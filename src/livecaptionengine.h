/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#pragma once

#include <QByteArray>
#include <QNetworkAccessManager>
#include <QObject>
#include <QProcess>
#include <QStringList>
#include <QVariantList>

class LiveCaptionEngine : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(QString captureSource READ captureSource WRITE setCaptureSource NOTIFY captureSourceChanged)
    Q_PROPERTY(QString sourceLanguage READ sourceLanguage WRITE setSourceLanguage NOTIFY sourceLanguageChanged)
    Q_PROPERTY(bool translateEnabled READ translateEnabled WRITE setTranslateEnabled NOTIFY translateEnabledChanged)
    Q_PROPERTY(QString targetLanguage READ targetLanguage WRITE setTargetLanguage NOTIFY targetLanguageChanged)
    Q_PROPERTY(QString currentCaption READ currentCaption NOTIFY captionUpdated)
    Q_PROPERTY(QString currentTranslation READ currentTranslation NOTIFY captionUpdated)
    Q_PROPERTY(QVariantList history READ history NOTIFY historyChanged)
    Q_PROPERTY(qreal audioLevel READ audioLevel NOTIFY audioLevelChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusTextChanged)

public:
    explicit LiveCaptionEngine(QObject *parent = nullptr);
    ~LiveCaptionEngine() override;

    bool running() const;
    QString captureSource() const;
    void setCaptureSource(const QString &source);

    QString sourceLanguage() const;
    void setSourceLanguage(const QString &lang);

    bool translateEnabled() const;
    void setTranslateEnabled(bool enabled);

    QString targetLanguage() const;
    void setTargetLanguage(const QString &lang);

    QString currentCaption() const;
    QString currentTranslation() const;
    QVariantList history() const;
    qreal audioLevel() const;
    QString statusText() const;

    Q_INVOKABLE void startCapture();
    Q_INVOKABLE void stopCapture();
    Q_INVOKABLE void toggleCapture();
    Q_INVOKABLE void clearCaptions();
    Q_INVOKABLE void copyAllTranscript() const;

    // Static helpers exposed for unit testing
    static QByteArray createWavHeader(int dataSize, int sampleRate = 16000, int channels = 1, int bitsPerSample = 16);
    static QStringList buildPipeWireRecordArgs(const QString &captureSource);
    static QString cleanWhisperOutput(const QString &rawOutput);
    static double computePcmRms(const QByteArray &pcmChunk);

Q_SIGNALS:
    void runningChanged();
    void captureSourceChanged();
    void sourceLanguageChanged();
    void translateEnabledChanged();
    void targetLanguageChanged();
    void captionUpdated();
    void historyChanged();
    void audioLevelChanged();
    void statusTextChanged();

private Q_SLOTS:
    void onAudioChunkReady();

private:
    void processAudioWindow(const QByteArray &pcmData);
    void requestOllamaTranslation(const QString &captionText);
    QString resolveWhisperBinary() const;
    QString resolveWhisperModel() const;

    bool m_running = false;
    QString m_captureSource = QStringLiteral("sink"); // "sink" (system audio) or "mic"
    QString m_sourceLanguage = QStringLiteral("auto");
    bool m_translateEnabled = false;
    QString m_targetLanguage = QStringLiteral("Español");

    QString m_currentCaption;
    QString m_currentTranslation;
    QVariantList m_history;
    qreal m_audioLevel = 0.0;
    QString m_statusText = QStringLiteral("Listo para subtitular (PipeWire)");

    QProcess *m_pwProcess = nullptr;
    QByteArray m_pcmBuffer;
    bool m_transcribingChunk = false;
    QNetworkAccessManager *m_nam = nullptr;
};
