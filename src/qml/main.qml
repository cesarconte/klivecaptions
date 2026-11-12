/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later

    KLiveCaptions — Subtítulos en tiempo real.

    Diseño Golden Gate / Liquid Glass (CachyOS.UI):
      * ventana `CachyWindow`: marco translúcido con blur de KWin, cabecera de
        44 px con el divisor duro de 1 px y radio de esquina de 20 px;
      * las acciones primarias (iniciar, traducir, copiar, limpiar) viven en
        la cabecera, siempre a la derecha;
      * el estado de la captura se muestra en una píldora de cristal a la
        izquierda de la cabecera;
      * la transcripción en vivo se presenta sobre una `CachyCard`;
      * toda la paleta, los radios y los espaciados salen de `CachyTheme`.
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import CachyOS.UI

CachyWindow {
    id: root

    // Translations come from the design system helper, which always falls back
    // to the source text when the application has no catalogue yet.
    title: CachyI18n.i18n("KLiveCaptions — Subtítulos en Tiempo Real")
    width: 900
    height: 250
    minimumWidth: 640
    minimumHeight: 200
    visible: true

    // =========================================================================
    // Geometría canónica Golden Gate
    // =========================================================================
    showTrafficLights: true
    showTitleBarDivider: true          // divisor duro de 1 px
    showWindowFrame: true              // Liquid Glass: blur KWin + rim especular
    resizable: true
    cornerRadius: CachyTheme.radiusWindow
    contentPadded: true                // margen perimetral de 18 px

    // =========================================================================
    // CABECERA — IZQUIERDA: estado de la captura
    // =========================================================================
    headerLeading: [
        Rectangle {
            id: statusPill
            anchors.verticalCenter: parent.verticalCenter
            height: 28
            implicitWidth: statusRow.implicitWidth + 18
            radius: 14
            color: CachyTheme.surfacePill
            border.width: 1
            border.color: CachyTheme.specularBorder

            RowLayout {
                id: statusRow
                anchors.fill: parent
                anchors.leftMargin: 9
                anchors.rightMargin: 9
                spacing: 7

                // Indicador reactivo del nivel de audio
                Rectangle {
                    Layout.preferredWidth: 9
                    Layout.preferredHeight: 9
                    radius: 4.5
                    color: CaptionEngine.running ? "#30D158" : CachyTheme.textMuted
                    scale: CaptionEngine.running ? (1.0 + CaptionEngine.audioLevel * 0.45) : 1.0

                    Behavior on scale {
                        NumberAnimation { duration: 90 }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.maximumWidth: 230
                    text: CaptionEngine.statusText
                    font.pixelSize: 11
                    color: CachyTheme.textSecondary
                    elide: Text.ElideRight
                }
            }
        }
    ]

    // =========================================================================
    // CABECERA — DERECHA: acciones primarias
    // =========================================================================
    headerActions: [
        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // Iniciar / Detener la captura
            CachyToolbarButton {
                text: CaptionEngine.running ? "⏸" : "▶"
                tooltipText: CaptionEngine.running ? "Pausar la captura" : "Iniciar la captura"
                onClicked: CaptionEngine.toggleCapture()
            }

            // Traducción en vivo (conmutable)
            CachyToolbarButton {
                checkable: true
                checked: CaptionEngine.translateEnabled
                text: "🌐"
                tooltipText: "Traducir la transcripción en vivo"
                onToggled: (nextState) => CaptionEngine.translateEnabled = nextState
            }

            // Separador duro antes de las acciones destructivas
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 18
                Layout.alignment: Qt.AlignVCenter
                color: CachyTheme.hardDividerColor
            }

            CachyToolbarButton {
                text: "📋"
                tooltipText: "Copiar la transcripción al portapapeles"
                onClicked: CaptionEngine.copyAllTranscript()
            }

            CachyToolbarButton {
                text: "🗑"
                tooltipText: "Limpiar los subtítulos"
                onClicked: CaptionEngine.clearCaptions()
            }
        }
    ]

    // =========================================================================
    // CONTENIDO
    // =========================================================================
    contentData: [
        ColumnLayout {
            anchors.fill: parent
            spacing: CachyTheme.spacingMedium

            // -----------------------------------------------------------------
            // Strip de configuración: origen del audio e idiomas
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 8

                // Origen de la captura: audio del sistema o micrófono
                QQC2.ComboBox {
                    id: sourceCombo
                    Layout.preferredWidth: 170
                    Layout.preferredHeight: 30
                    font.pixelSize: 12
                    model: [
                        { value: "sink", label: "🔊 Audio del PC" },
                        { value: "mic", label: "🎙️ Micrófono" }
                    ]
                    textRole: "label"
                    valueRole: "value"
                    currentIndex: CaptionEngine.captureSource === "sink" ? 0 : 1
                    onActivated: index => CaptionEngine.captureSource = sourceCombo.model[index].value
                }

                // Idioma de origen
                QQC2.ComboBox {
                    id: languageCombo
                    Layout.preferredWidth: 90
                    Layout.preferredHeight: 30
                    font.pixelSize: 12
                    model: [
                        { value: "auto", label: "Auto" },
                        { value: "es", label: "ES" },
                        { value: "en", label: "EN" },
                        { value: "fr", label: "FR" },
                        { value: "de", label: "DE" }
                    ]
                    textRole: "label"
                    valueRole: "value"
                    currentIndex: {
                        const index = languageCombo.model.findIndex(entry => entry.value === CaptionEngine.sourceLanguage);
                        return index >= 0 ? index : 0;
                    }
                    onActivated: index => CaptionEngine.sourceLanguage = languageCombo.model[index].value
                }

                // Idioma de destino de la traducción
                QQC2.ComboBox {
                    id: targetLanguageCombo
                    Layout.preferredWidth: 130
                    Layout.preferredHeight: 30
                    font.pixelSize: 12
                    visible: CaptionEngine.translateEnabled
                    model: ["Español", "English", "Français", "Deutsch", "Italiano"]
                    currentIndex: Math.max(0, targetLanguageCombo.model.indexOf(CaptionEngine.targetLanguage))
                    onActivated: index => CaptionEngine.targetLanguage = targetLanguageCombo.model[index]
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            // -----------------------------------------------------------------
            // Superficie de la transcripción en vivo
            // -----------------------------------------------------------------
            CachyCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0

                contentItem: ColumnLayout {
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.fillHeight: true
                        text: CaptionEngine.currentCaption.length > 0
                            ? CaptionEngine.currentCaption
                            : (CaptionEngine.running
                                ? "Esperando voz o audio en reproducción…"
                                : "Pulsa «Iniciar» para subtitular en tiempo real el audio del sistema o el micrófono.")
                        color: CaptionEngine.currentCaption.length > 0
                            ? CachyTheme.textPrimary
                            : CachyTheme.textMuted
                        font.pixelSize: 18
                        font.weight: Font.Medium
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        visible: CaptionEngine.translateEnabled && CaptionEngine.currentTranslation.length > 0
                        text: "🌐 " + CaptionEngine.currentTranslation
                        color: CachyTheme.accentColor
                        font.pixelSize: 15
                        font.italic: true
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }
            }
        }
    ]
}
