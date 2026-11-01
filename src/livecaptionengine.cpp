/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#include "livecaptionengine.h"

#include <cmath>
#include <cstring>

#include <QClipboard>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QRegularExpression>
#include <QStandardPaths>

LiveCaptionEngine::LiveCaptionEngine(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
{
}

LiveCaptionEngine::~LiveCaptionEngine()
{
    stopCapture();
}

bool LiveCaptionEngine::running() const { return m_running; }
QString LiveCaptionEngine::captureSource() const { return m_captureSource; }
QString LiveCaptionEngine::sourceLanguage() const { return m_sourceLanguage; }
bool LiveCaptionEngine::translateEnabled() const { return m_translateEnabled; }
QString LiveCaptionEngine::targetLanguage() const { return m_targetLanguage; }
QString LiveCaptionEngine::currentCaption() const { return m_currentCaption; }
QString LiveCaptionEngine::currentTranslation() const { return m_currentTranslation; }
QVariantList LiveCaptionEngine::history() const { return m_history; }
qreal LiveCaptionEngine::audioLevel() const { return m_audioLevel; }
QString LiveCaptionEngine::statusText() const { return m_statusText; }

void LiveCaptionEngine::setCaptureSource(const QString &source)
{
    if (m_captureSource != source) {
        m_captureSource = source;
        Q_EMIT captureSourceChanged();
        if (m_running) {
            stopCapture();
            startCapture();
        }
    }
}

void LiveCaptionEngine::setSourceLanguage(const QString &lang)
{
    if (m_sourceLanguage != lang) {
        m_sourceLanguage = lang;
        Q_EMIT sourceLanguageChanged();
    }
}

void LiveCaptionEngine::setTranslateEnabled(bool enabled)
{
    if (m_translateEnabled != enabled) {
        m_translateEnabled = enabled;
        Q_EMIT translateEnabledChanged();
    }
}

void LiveCaptionEngine::setTargetLanguage(const QString &lang)
{
    if (m_targetLanguage != lang) {
        m_targetLanguage = lang;
        Q_EMIT targetLanguageChanged();
    }
}

QByteArray LiveCaptionEngine::createWavHeader(int dataSize, int sampleRate, int channels, int bitsPerSample)
{
    QByteArray header(44, 0);
    char *h = header.data();
    std::memcpy(h, "RIFF", 4);
    const qint32 chunkSize = 36 + dataSize;
    std::memcpy(h + 4, &chunkSize, 4);
    std::memcpy(h + 8, "WAVE", 4);
    std::memcpy(h + 12, "fmt ", 4);
    const qint32 subchunk1Size = 16;
    std::memcpy(h + 16, &subchunk1Size, 4);
    const qint16 audioFormat = 1; // PCM
    std::memcpy(h + 20, &audioFormat, 2);
    const qint16 numChannels = static_cast<qint16>(channels);
    std::memcpy(h + 22, &numChannels, 2);
    const qint32 sRate = sampleRate;
    std::memcpy(h + 24, &sRate, 4);
    const qint32 byteRate = sampleRate * channels * (bitsPerSample / 8);
    std::memcpy(h + 28, &byteRate, 4);
    const qint16 blockAlign = static_cast<qint16>(channels * (bitsPerSample / 8));
    std::memcpy(h + 32, &blockAlign, 2);
    const qint16 bitsPerSamp = static_cast<qint16>(bitsPerSample);
    std::memcpy(h + 34, &bitsPerSamp, 2);
    std::memcpy(h + 36, "data", 4);
    const qint32 dSize = dataSize;
    std::memcpy(h + 40, &dSize, 4);
    return header;
}

QStringList LiveCaptionEngine::buildPipeWireRecordArgs(const QString &captureSource)
{
    QStringList args;
    args << QStringLiteral("--raw")
         << QStringLiteral("--format=s16")
         << QStringLiteral("--rate=16000")
         << QStringLiteral("--channels=1");

    if (captureSource == QStringLiteral("sink")) {
        // Capture the default PipeWire output sink monitor (respecting EasyEffects virtual sink routing)
        args << QStringLiteral("-P") << QStringLiteral("stream.capture.sink=true");
    }
    args << QStringLiteral("-");
    return args;
}

QString LiveCaptionEngine::cleanWhisperOutput(const QString &rawOutput)
{
    QString text = rawOutput.trimmed();
    static const QRegularExpression bracketRx(QStringLiteral("\\[.*?\\]|\\(.*?\\)"));
    text.remove(bracketRx);
    return text.simplified().trimmed();
}

double LiveCaptionEngine::computePcmRms(const QByteArray &pcmChunk)
{
    const int sampleCount = pcmChunk.size() / static_cast<int>(sizeof(qint16));
    if (sampleCount <= 0) {
        return 0.0;
    }
    const qint16 *samples = reinterpret_cast<const qint16 *>(pcmChunk.constData());
    double sumSq = 0.0;
    for (int i = 0; i < sampleCount; ++i) {
        const double norm = samples[i] / 32768.0;
        sumSq += norm * norm;
    }
    return std::sqrt(sumSq / sampleCount);
}

QString LiveCaptionEngine::resolveWhisperBinary() const
{
    QString bin = QStandardPaths::findExecutable(QStringLiteral("whisper-cli"));
    if (!bin.isEmpty()) return bin;
    const QString localBin = QDir::homePath() + QStringLiteral("/.local/bin/whisper-cli");
    if (QFile::exists(localBin)) return localBin;
    return QStandardPaths::findExecutable(QStringLiteral("whisper"));
}

QString LiveCaptionEngine::resolveWhisperModel() const
{
    const QString model = QDir::homePath() + QStringLiteral("/.local/share/kiri/models/ggml-base.bin");
    if (QFile::exists(model)) return model;
    return QString();
}

void LiveCaptionEngine::startCapture()
{
    if (m_running) return;

    const QString pwRecord = QStandardPaths::findExecutable(QStringLiteral("pw-record"));
    if (pwRecord.isEmpty()) {
        m_statusText = QStringLiteral("Error: pw-record (PipeWire) no encontrado");
        Q_EMIT statusTextChanged();
        return;
    }

    m_pcmBuffer.clear();
    m_pwProcess = new QProcess(this);
    connect(m_pwProcess, &QProcess::readyReadStandardOutput, this, &LiveCaptionEngine::onAudioChunkReady);

    m_pwProcess->start(pwRecord, buildPipeWireRecordArgs(m_captureSource));
    if (!m_pwProcess->waitForStarted(2000)) {
        m_statusText = QStringLiteral("No se pudo iniciar la captura de PipeWire");
        Q_EMIT statusTextChanged();
        m_pwProcess->deleteLater();
        m_pwProcess = nullptr;
        return;
    }

    m_running = true;
    m_statusText = (m_captureSource == QStringLiteral("sink"))
        ? QStringLiteral("Escuchando audio del sistema (PipeWire)…")
        : QStringLiteral("Escuchando micrófono (PipeWire + EasyEffects)…");
    Q_EMIT runningChanged();
    Q_EMIT statusTextChanged();
}

void LiveCaptionEngine::stopCapture()
{
    if (m_pwProcess) {
        disconnect(m_pwProcess, nullptr, this, nullptr);
        if (m_pwProcess->state() != QProcess::NotRunning) {
            m_pwProcess->terminate();
            if (!m_pwProcess->waitForFinished(800)) {
                m_pwProcess->kill();
            }
        }
        m_pwProcess->deleteLater();
        m_pwProcess = nullptr;
    }
    m_pcmBuffer.clear();
    m_audioLevel = 0.0;
    Q_EMIT audioLevelChanged();

    if (m_running) {
        m_running = false;
        m_statusText = QStringLiteral("Subtítulos en pausa");
        Q_EMIT runningChanged();
        Q_EMIT statusTextChanged();
    }
}

void LiveCaptionEngine::toggleCapture()
{
    if (m_running) {
        stopCapture();
    } else {
        startCapture();
    }
}

void LiveCaptionEngine::clearCaptions()
{
    m_currentCaption.clear();
    m_currentTranslation.clear();
    m_history.clear();
    Q_EMIT captionUpdated();
    Q_EMIT historyChanged();
}

void LiveCaptionEngine::copyAllTranscript() const
{
    QStringList lines;
    for (const QVariant &v : m_history) {
        const QVariantMap map = v.toMap();
        const QString orig = map.value(QStringLiteral("caption")).toString();
        const QString tr = map.value(QStringLiteral("translation")).toString();
        if (!tr.isEmpty()) {
            lines << QStringLiteral("%1 -> [%2]").arg(orig, tr);
        } else {
            lines << orig;
        }
    }
    if (!m_currentCaption.isEmpty()) {
        lines << m_currentCaption;
    }
    if (QClipboard *cb = QGuiApplication::clipboard()) {
        cb->setText(lines.join(QLatin1Char('\n')));
    }
}

void LiveCaptionEngine::onAudioChunkReady()
{
    if (!m_pwProcess) return;
    const QByteArray chunk = m_pwProcess->readAllStandardOutput();
    if (chunk.isEmpty()) return;

    const double rms = computePcmRms(chunk);
    const qreal level = qBound(0.0, rms * 5.0, 1.0);
    if (std::abs(m_audioLevel - level) > 0.02) {
        m_audioLevel = level;
        Q_EMIT audioLevelChanged();
    }

    m_pcmBuffer.append(chunk);

    // 2.6 seconds of 16kHz 16-bit mono PCM = 83200 bytes
    const int windowBytes = 16000 * 2 * 26 / 10;
    if (m_pcmBuffer.size() >= windowBytes && !m_transcribingChunk) {
        const QByteArray windowData = m_pcmBuffer.left(windowBytes);
        // Keep 0.35s overlap for word continuity
        m_pcmBuffer.remove(0, windowBytes - (16000 * 2 * 35 / 100));

        if (computePcmRms(windowData) >= 0.012) {
            processAudioWindow(windowData);
        }
    }
}

void LiveCaptionEngine::processAudioWindow(const QByteArray &pcmData)
{
    const QString whisperBin = resolveWhisperBinary();
    const QString modelPath = resolveWhisperModel();
    if (whisperBin.isEmpty() || modelPath.isEmpty()) {
        m_statusText = QStringLiteral("Whisper.cpp o modelo ggml-base.bin no encontrado");
        Q_EMIT statusTextChanged();
        return;
    }

    m_transcribingChunk = true;
    const QString tmpWav = QDir::tempPath() + QStringLiteral("/klivecaptions_%1.wav").arg(QDateTime::currentMSecsSinceEpoch());
    QFile wavFile(tmpWav);
    if (!wavFile.open(QIODevice::WriteOnly)) {
        m_transcribingChunk = false;
        return;
    }
    wavFile.write(createWavHeader(pcmData.size()));
    wavFile.write(pcmData);
    wavFile.close();

    QProcess *proc = new QProcess(this);
    QStringList args;
    args << QStringLiteral("-m") << modelPath
         << QStringLiteral("-f") << tmpWav
         << QStringLiteral("--no-timestamps")
         << QStringLiteral("-t") << QStringLiteral("4")
         << QStringLiteral("-np");

    if (m_sourceLanguage != QStringLiteral("auto") && !m_sourceLanguage.isEmpty()) {
        args << QStringLiteral("-l") << m_sourceLanguage;
    } else {
        args << QStringLiteral("-l") << QStringLiteral("es");
    }

    connect(proc, &QProcess::finished, this, [this, proc, tmpWav](int exitCode, QProcess::ExitStatus) {
        proc->deleteLater();
        QFile::remove(tmpWav);
        m_transcribingChunk = false;

        if (exitCode != 0) return;

        const QString text = cleanWhisperOutput(QString::fromUtf8(proc->readAllStandardOutput()));
        if (text.length() < 2) return;

        if (!m_currentCaption.isEmpty() && m_currentCaption != text) {
            QVariantMap entry;
            entry[QStringLiteral("caption")] = m_currentCaption;
            entry[QStringLiteral("translation")] = m_currentTranslation;
            entry[QStringLiteral("time")] = QDateTime::currentDateTime().toString(QStringLiteral("hh:mm:ss"));
            m_history.append(entry);
            while (m_history.size() > 30) {
                m_history.removeFirst();
            }
            Q_EMIT historyChanged();
        }

        m_currentCaption = text;
        if (!m_translateEnabled) {
            m_currentTranslation.clear();
        }
        Q_EMIT captionUpdated();

        if (m_translateEnabled) {
            requestOllamaTranslation(text);
        }
    });

    proc->start(whisperBin, args);
}

void LiveCaptionEngine::requestOllamaTranslation(const QString &captionText)
{
    QJsonObject reqObj;
    reqObj[QStringLiteral("model")] = QStringLiteral("qwen2.5:7b");
    reqObj[QStringLiteral("stream")] = false;

    QJsonArray msgs;
    QJsonObject sys;
    sys[QStringLiteral("role")] = QStringLiteral("system");
    sys[QStringLiteral("content")] = QStringLiteral(
        "Eres un traductor simultáneo de subtítulos en vivo (Live Captions). "
        "Traduce el siguiente fragmento al idioma '%1'. Devuelve ÚNICAMENTE la traducción directa en una sola línea, sin explicaciones ni comillas.")
        .arg(m_targetLanguage);
    msgs.append(sys);

    QJsonObject usr;
    usr[QStringLiteral("role")] = QStringLiteral("user");
    usr[QStringLiteral("content")] = captionText;
    msgs.append(usr);

    reqObj[QStringLiteral("messages")] = msgs;

    QNetworkRequest req(QUrl(QStringLiteral("http://127.0.0.1:11434/api/chat")));
    req.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));

    QNetworkReply *reply = m_nam->post(req, QJsonDocument(reqObj).toJson(QJsonDocument::Compact));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) return;

        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        const QString translated = doc.object()
                                      .value(QStringLiteral("message"))
                                      .toObject()
                                      .value(QStringLiteral("content"))
                                      .toString()
                                      .trimmed();
        if (!translated.isEmpty()) {
            m_currentTranslation = translated;
            Q_EMIT captionUpdated();
        }
    });
}
