/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later

    KLiveCaptions — Subtítulos en tiempo real.

    Diseño Golden Gate / Liquid Glass (CachyOS.UI):
      * ventana `CachyWindow`: marco translúcido con blur de KWin, cabecera de
        44 px con divisor duro de 1 px y radio de esquina de 20 px;
      * acciones primarias en la cabecera (iniciar/pausar, traducir, copiar, limpiar)
        usando `CachyToolbarButton` con iconos vectoriales temáticos;
      * estado de captura y nivel de audio reactivo en píldora de cristal a la izquierda;
      * selectores integrados con `CachyComboBox`;
      * transcripción en vivo presentada sobre `CachyCard`;
      * tipografía completa basada en `CachyLabel` y tokens de `CachyTheme`.
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import CachyOS.UI

CachyWindow {
    id: root

    title: CachyI18n.i18n("KLiveCaptions — Subtítulos en Tiempo Real")

    width: CachyTheme.windowWidthSettings
    height: CachyTheme.windowHeightSettings
    minimumWidth: 640
    minimumHeight: 480
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
    // CABECERA — IZQUIERDA: estado de la captura y nivel de audio
    // =========================================================================
    headerLeading: [
        Rectangle {
            id: statusPill
            anchors.verticalCenter: parent.verticalCenter
            height: 28
            implicitWidth: statusRow.implicitWidth + 18
            radius: 14
            color: CachyPalette.surfacePill
            border.width: 1
            border.color: CachyPalette.specularBorder

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

                CachyLabel {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.maximumWidth: 230
                    text: CaptionEngine.statusText
                    font.pixelSize: 11
                    color: CachyPalette.textSecondary
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
                iconName: CaptionEngine.running ? "media-playback-pause" : "media-playback-start"
                tooltipText: CaptionEngine.running
                    ? CachyI18n.i18n("Pausar la captura")
                    : CachyI18n.i18n("Iniciar la captura")
                primary: !CaptionEngine.running
                onClicked: CaptionEngine.toggleCapture()
            }

            // Traducción en vivo (conmutable)
            CachyToolbarButton {
                checkable: true
                checked: CaptionEngine.translateEnabled
                iconName: "preferences-desktop-locale"
                tooltipText: CachyI18n.i18n("Traducir la transcripción en vivo")
                onToggled: (nextState) => CaptionEngine.translateEnabled = nextState
            }

            // Separador duro antes de las acciones secundarias / destructivas
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 18
                Layout.alignment: Qt.AlignVCenter
                color: CachyTheme.hardDividerColor
            }

            CachyToolbarButton {
                iconName: "edit-copy"
                tooltipText: CachyI18n.i18n("Copiar la transcripción al portapapeles")
                onClicked: CaptionEngine.copyAllTranscript()
            }

            CachyToolbarButton {
                iconName: "edit-clear"
                tooltipText: CachyI18n.i18n("Limpiar los subtítulos")
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
            // Barra de configuración: origen del audio e idiomas
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 8

                // Origen de la captura: audio del sistema o micrófono
                CachyComboBox {
                    id: sourceCombo
                    Layout.preferredWidth: 180
                    Layout.preferredHeight: 32
                    model: [
                        { value: "sink", label: CachyI18n.i18n("Audio del sistema") },
                        { value: "mic", label: CachyI18n.i18n("Micrófono") }
                    ]
                    textRole: "label"
                    currentIndex: CaptionEngine.captureSource === "sink" ? 0 : 1
                    onActivated: index => CaptionEngine.captureSource = sourceCombo.model[index].value
                }

                // Idioma de origen
                CachyComboBox {
                    id: languageCombo
                    Layout.preferredWidth: 110
                    Layout.preferredHeight: 32
                    model: [
                        { value: "auto", label: CachyI18n.i18n("Auto") },
                        { value: "es", label: "Español (ES)" },
                        { value: "en", label: "English (EN)" },
                        { value: "fr", label: "Français (FR)" },
                        { value: "de", label: "Deutsch (DE)" }
                    ]
                    textRole: "label"
                    currentIndex: {
                        const index = languageCombo.model.findIndex(entry => entry.value === CaptionEngine.sourceLanguage);
                        return index >= 0 ? index : 0;
                    }
                    onActivated: index => CaptionEngine.sourceLanguage = languageCombo.model[index].value
                }

                // Idioma de destino de la traducción
                CachyComboBox {
                    id: targetLanguageCombo
                    Layout.preferredWidth: 140
                    Layout.preferredHeight: 32
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
            // Superficie de subtítulos en vivo (CachyCard)
            // -----------------------------------------------------------------
            CachyCard {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.preferredHeight: 180

                contentItem: ColumnLayout {
                    spacing: 8

                    CachyLabel {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: CaptionEngine.currentCaption.length > 0
                            ? CaptionEngine.currentCaption
                            : (CaptionEngine.running
                                ? CachyI18n.i18n("Esperando voz o audio en reproducción…")
                                : CachyI18n.i18n("Pulsa «Iniciar» para subtitular en tiempo real el audio del sistema o el micrófono."))
                        color: CaptionEngine.currentCaption.length > 0
                            ? CachyPalette.text
                            : CachyPalette.textMuted
                        font.pixelSize: 18
                        font.weight: Font.Medium
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        visible: CaptionEngine.translateEnabled && CaptionEngine.currentTranslation.length > 0
                        spacing: 6

                        CachyIcon {
                            Layout.alignment: Qt.AlignVCenter
                            name: "preferences-desktop-locale"
                            size: 15
                            color: CachyTheme.accentColor
                        }

                        CachyLabel {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: CaptionEngine.currentTranslation
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

            // -----------------------------------------------------------------
            // Encabezado de historial de transcripciones
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 8

                CachyLabel {
                    text: CachyI18n.i18n("TRANSCRIPCIÓN")
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: CachyPalette.textMuted
                }

                Rectangle {
                    Layout.preferredWidth: historyCount.implicitWidth + 14
                    Layout.preferredHeight: 18
                    radius: 9
                    color: CachyPalette.surfacePill
                    border.width: 1
                    border.color: CachyPalette.specularBorder

                    CachyLabel {
                        id: historyCount
                        anchors.centerIn: parent
                        text: CaptionEngine.history.length
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: CachyPalette.textSecondary
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            // -----------------------------------------------------------------
            // Historial con scroll y estado vacío
            // -----------------------------------------------------------------
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0

                ListView {
                    id: historyView
                    anchors.fill: parent
                    clip: true
                    spacing: 4
                    model: CaptionEngine.history
                    boundsBehavior: Flickable.StopAtBounds
                    verticalLayoutDirection: ListView.TopToBottom

                    delegate: Item {
                        id: historyRow
                        required property var modelData

                        width: ListView.view ? ListView.view.width : 0
                        height: captionText.implicitHeight + (translationRow.visible ? translationRow.implicitHeight + 4 : 0) + 12

                        CachyLabel {
                            id: timeText
                            x: 0
                            y: 1
                            width: 58
                            text: historyRow.modelData.time ?? ""
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: CachyPalette.textMuted
                            elide: Text.ElideRight
                        }

                        CachyLabel {
                            id: captionText
                            x: 68
                            y: 0
                            width: Math.max(0, historyRow.width - 68 - 8)
                            text: historyRow.modelData.caption ?? ""
                            font.pixelSize: 12
                            color: CachyPalette.text
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            id: translationRow
                            x: 68
                            y: captionText.height + 3
                            width: Math.max(0, historyRow.width - 68 - 8)
                            visible: (historyRow.modelData.translation ?? "").length > 0
                            spacing: 5

                            CachyIcon {
                                name: "preferences-desktop-locale"
                                size: 12
                                color: CachyTheme.accentColor
                            }

                            CachyLabel {
                                Layout.fillWidth: true
                                text: historyRow.modelData.translation ?? ""
                                font.pixelSize: 11
                                font.italic: true
                                color: CachyTheme.accentColor
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }

                // Estado vacío centrado
                ColumnLayout {
                    anchors.top: parent.top
                    anchors.topMargin: 28
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.max(0, parent.width - 40)
                    spacing: 8
                    visible: historyView.count === 0

                    CachyIcon {
                        Layout.alignment: Qt.AlignHCenter
                        name: "audio-input-microphone"
                        size: 32
                        color: CachyPalette.textMuted
                    }

                    CachyLabel {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: CachyI18n.i18n("Sin transcripciones todavía")
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: CachyPalette.textSecondary
                        wrapMode: Text.WordWrap
                    }

                    CachyLabel {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: CachyI18n.i18n("Pulsa «Iniciar» y las frases capturadas aparecerán aquí con su hora.")
                        font.pixelSize: 11
                        color: CachyPalette.textMuted
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    ]
}
