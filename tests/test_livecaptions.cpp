/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#include "livecaptionengine.h"

#include <QFile>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QTest>

class TestLiveCaptions : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void testPipeWireSinkAndMicArgs()
    {
        // System audio sink monitor must use stream.capture.sink=true and never hardcode hw:* devices
        const QStringList sinkArgs = LiveCaptionEngine::buildPipeWireRecordArgs(QStringLiteral("sink"));
        QVERIFY(sinkArgs.contains(QStringLiteral("--raw")));
        QVERIFY(sinkArgs.contains(QStringLiteral("stream.capture.sink=true")));
        for (const QString &arg : sinkArgs) {
            QVERIFY(!arg.contains(QStringLiteral("hw:")));
        }

        // Microphone source must use default PipeWire/EasyEffects input without stream.capture.sink=true
        const QStringList micArgs = LiveCaptionEngine::buildPipeWireRecordArgs(QStringLiteral("mic"));
        QVERIFY(!micArgs.contains(QStringLiteral("stream.capture.sink=true")));
    }

    void testWavHeaderAndRmsCalculation()
    {
        const QByteArray hdr = LiveCaptionEngine::createWavHeader(64000, 16000, 1, 16);
        QCOMPARE(hdr.size(), 44);
        QCOMPARE(hdr.left(4), QByteArray("RIFF"));
        QCOMPARE(hdr.mid(8, 4), QByteArray("WAVE"));

        QByteArray silence(3200, 0);
        QCOMPARE(LiveCaptionEngine::computePcmRms(silence), 0.0);

        QByteArray tone(3200, 0);
        qint16 *samples = reinterpret_cast<qint16 *>(tone.data());
        for (int i = 0; i < 1600; ++i) {
            samples[i] = 8192;
        }
        const double rms = LiveCaptionEngine::computePcmRms(tone);
        QVERIFY(rms > 0.20 && rms < 0.30);
    }

    void testWhisperArtifactCleaning()
    {
        const QString dirty = QStringLiteral("  [BLANK_AUDIO] Hola a todos en la conferencia (aplausos) [Música]  ");
        const QString cleaned = LiveCaptionEngine::cleanWhisperOutput(dirty);
        QCOMPARE(cleaned, QStringLiteral("Hola a todos en la conferencia"));
    }

    void testOverlayQmlSyntax()
    {
        QQmlEngine engine;
        const QString qmlFile = QStringLiteral(KLIVECAPTIONS_SOURCE_DIR) + QStringLiteral("/src/qml/main.qml");
        QVERIFY(QFile::exists(qmlFile));
        QQmlComponent comp(&engine, QUrl::fromLocalFile(qmlFile));
        QVERIFY2(!comp.isError(), qPrintable(comp.errorString()));
    }
};

QTEST_MAIN(TestLiveCaptions)
#include "test_livecaptions.moc"
