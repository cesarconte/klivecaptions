/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: rootWindow
    width: 820
    height: 160
    visible: true
    title: i18n("KLiveCaptions — Subtítulos en Tiempo Real")

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.mediumSpacing
        spacing: Kirigami.Units.smallSpacing

        // Top Control Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            // Reactive audio indicator dot
            Rectangle {
                implicitWidth: 10
                implicitHeight: 10
                radius: 5
                color: CaptionEngine.running ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
                scale: CaptionEngine.running ? (1.0 + CaptionEngine.audioLevel * 0.45) : 1.0
                Behavior on scale { NumberAnimation { duration: 90 } }
            }

            QQC2.Label {
                text: CaptionEngine.statusText
                color: Kirigami.Theme.disabledTextColor
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

                // Play / Pause Live Captions
                QQC2.ToolButton {
                    icon.name: CaptionEngine.running ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
                    text: CaptionEngine.running ? "Pausar" : "Iniciar"
                    display: QQC2.AbstractButton.TextBesideIcon
                    onClicked: CaptionEngine.toggleCapture()
                }

                // Source selector: System Audio (PipeWire Sink Monitor) vs Microphone
                QQC2.ComboBox {
                    id: sourceCombo
                    implicitWidth: 155
                    model: [
                        { value: "sink", label: "🔊 Audio del PC" },
                        { value: "mic", label: "🎙️ Micrófono" }
                    ]
                    textRole: "label"
                    valueRole: "value"
                    currentIndex: CaptionEngine.captureSource === "sink" ? 0 : 1
                    onActivated: index => {
                        CaptionEngine.captureSource = model[index].value;
                    }
                }

                // Source language
                QQC2.ComboBox {
                    implicitWidth: 95
                    model: [
                        { value: "es", label: "ES" },
                        { value: "en", label: "EN" },
                        { value: "fr", label: "FR" },
                        { value: "de", label: "DE" }
                    ]
                    textRole: "label"
                    valueRole: "value"
                    currentIndex: 0
                    onActivated: index => {
                        CaptionEngine.sourceLanguage = model[index].value;
                    }
                }

                // Live Translation toggle
                QQC2.ToolButton {
                    checkable: true
                    checked: CaptionEngine.translateEnabled
                    icon.name: "preferences-desktop-locale-symbolic"
                    text: "Traducir"
                    display: QQC2.AbstractButton.TextBesideIcon
                    onClicked: CaptionEngine.translateEnabled = checked
                }

                // Target translation language
                QQC2.ComboBox {
                    visible: CaptionEngine.translateEnabled
                    implicitWidth: 115
                    model: ["Español", "English", "Français", "Deutsch", "Italiano"]
                    currentIndex: 0
                    onActivated: index => {
                        CaptionEngine.targetLanguage = model[index];
                    }
                }

                QQC2.ToolButton {
                    icon.name: "edit-copy-symbolic"
                    onClicked: CaptionEngine.copyAllTranscript()
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: "Copiar transcripción al portapapeles"
                }

                QQC2.ToolButton {
                    icon.name: "edit-clear-symbolic"
                    onClicked: CaptionEngine.clearCaptions()
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: "Limpiar subtítulos"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.15)
            }

            // Live Caption Main Display Area
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                QQC2.Label {
                    Layout.fillWidth: true
                    text: CaptionEngine.currentCaption.length > 0
                        ? CaptionEngine.currentCaption
                        : (CaptionEngine.running
                            ? "Esperando voz o audio en reproducción…"
                            : "Pulsa «Iniciar» para subtitular en tiempo real el audio del sistema o micrófono.")
                    color: CaptionEngine.currentCaption.length > 0 ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                    font.pixelSize: 18
                    font.weight: Font.Medium
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    visible: CaptionEngine.translateEnabled && CaptionEngine.currentTranslation.length > 0
                    text: "🌐 " + CaptionEngine.currentTranslation
                    color: Kirigami.Theme.highlightColor
                    font.pixelSize: 15
                    font.italic: true
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }
        }
}
