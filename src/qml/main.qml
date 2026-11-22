/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later

    KLiveCaptions — Subtítulos en tiempo real.

    Diseño Golden Gate / Liquid Glass (CachyOS.UI):
      * Ventana `CachyWindow`: marco translúcido con blur de KWin, esquinas de 20 px,
        borde especular de 1 px y cabecera limpia sin divisor duro (`showTitleBarDivider: false`).
      * Cápsula de acciones `CachyToolbarGroup` con controles Golden Gate:
        pausar/reanudar, alternar origen (micrófono / sistema), ajustes en `CachyPopover`,
        copiar transcripción y limpiar.
      * Píldora de estado reactiva en `headerLeading` con vúmetro y estado de audio.
      * Tipografía de alto contraste con tamaño ajustable y desplazamiento fluido.
      * Paleta resuelta íntegramente mediante tokens de `CachyPalette` y `CachyTheme`.
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
    // Geometría canónica Golden Gate (macOS 27 Liquid Glass)
    // =========================================================================
    showTrafficLights: true
    showTitle: false
    showTitleBarDivider: false         // Barra flotante continua Liquid Glass
    showWindowFrame: true              // Liquid Glass: blur KWin + rim especular
    resizable: true
    cornerRadius: CachyTheme.radiusWindow
    contentPadded: true                // Margen perimetral de 18 px

    property int captionFontSize: 20   // Ajustable en ajustes: 16, 20 o 26 px

    // =========================================================================
    // CABECERA — IZQUIERDA: estado de la captura y vúmetro reactivo
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
                    color: CaptionEngine.running ? "#30D158" : CachyPalette.textMuted
                    scale: CaptionEngine.running ? (1.0 + CaptionEngine.audioLevel * 0.45) : 1.0

                    Behavior on scale {
                        NumberAnimation { duration: 90 }
                    }
                }

                CachyIcon {
                    name: CaptionEngine.captureSource === "sink" ? "volume" : "microphone"
                    size: 13
                    color: CaptionEngine.running ? CachyTheme.accentColor : CachyPalette.textSecondary
                }

                CachyLabel {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.maximumWidth: 220
                    text: CaptionEngine.statusText
                    font.pixelSize: 11
                    color: CachyPalette.textSecondary
                    elide: Text.ElideRight
                }
            }
        }
    ]

    // =========================================================================
    // CABECERA — DERECHA: acciones agrupadas en cápsula Golden Gate
    // =========================================================================
    headerActions: [
        CachyToolbarGroup {
            anchors.verticalCenter: parent.verticalCenter

            // Iniciar / Pausar la captura
            CachyToolbarButton {
                pillStyle: false
                iconName: CaptionEngine.running ? "pause" : "play"
                tooltipText: CaptionEngine.running
                    ? CachyI18n.i18n("Pausar la captura")
                    : CachyI18n.i18n("Iniciar la captura")
                primary: !CaptionEngine.running
                onClicked: CaptionEngine.toggleCapture()
            }

            // Alternar origen de captura: audio del sistema vs micrófono
            CachyToolbarButton {
                pillStyle: false
                iconName: CaptionEngine.captureSource === "sink" ? "volume" : "microphone"
                tooltipText: CaptionEngine.captureSource === "sink"
                    ? CachyI18n.i18n("Fuente: Audio del sistema (clic para cambiar a micrófono)")
                    : CachyI18n.i18n("Fuente: Micrófono (clic para cambiar a audio del sistema)")
                onClicked: {
                    CaptionEngine.captureSource = (CaptionEngine.captureSource === "sink" ? "mic" : "sink");
                }
            }

            // Ajustes de subtítulos y traducción en CachyPopover
            CachyToolbarButton {
                id: settingsBtn
                pillStyle: false
                iconName: "settings"
                tooltipText: CachyI18n.i18n("Ajustes de subtítulos, fuente e idioma")
                onClicked: settingsPopover.openAt(settingsBtn)
            }

            // Copiar transcripción completa
            CachyToolbarButton {
                pillStyle: false
                iconName: "copy"
                tooltipText: CachyI18n.i18n("Copiar la transcripción al portapapeles")
                onClicked: CaptionEngine.copyAllTranscript()
            }

            // Limpiar subtítulos
            CachyToolbarButton {
                pillStyle: false
                iconName: "trash"
                tooltipText: CachyI18n.i18n("Limpiar los subtítulos")
                onClicked: CaptionEngine.clearCaptions()
            }
        }
    ]

    // =========================================================================
    // POPOVER DE AJUSTES (macOS Golden Gate)
    // =========================================================================
    CachyPopover {
        id: settingsPopover
        preferredWidth: 320
        preferredEdge: Qt.BottomEdge

        ColumnLayout {
            spacing: 12
            width: parent.width

            CachyLabel {
                text: CachyI18n.i18n("Ajustes de Subtítulos")
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: CachyPalette.text
            }

            // Selector de tamaño de fuente
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 4

                CachyLabel {
                    text: CachyI18n.i18n("Tamaño de texto")
                    font.pixelSize: 11
                    color: CachyPalette.textSecondary
                }

                CachySegmentedControl {
                    id: fontSegControl
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    model: [
                        CachyI18n.i18n("Normal"),
                        CachyI18n.i18n("Grande"),
                        CachyI18n.i18n("Extra")
                    ]
                    currentIndex: root.captionFontSize === 16 ? 0 : (root.captionFontSize === 26 ? 2 : 1)
                    onCurrentIndexChanged: {
                        if (currentIndex === 0) root.captionFontSize = 16;
                        else if (currentIndex === 2) root.captionFontSize = 26;
                        else root.captionFontSize = 20;
                    }
                }
            }

            // Selector de idioma de origen
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 4

                CachyLabel {
                    text: CachyI18n.i18n("Idioma de audio")
                    font.pixelSize: 11
                    color: CachyPalette.textSecondary
                }

                CachyComboBox {
                    id: popLanguageCombo
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.preferredHeight: 30
                    model: [
                        { value: "auto", label: CachyI18n.i18n("Detección automática") },
                        { value: "es", label: "Español (ES)" },
                        { value: "en", label: "English (EN)" },
                        { value: "fr", label: "Français (FR)" },
                        { value: "de", label: "Deutsch (DE)" }
                    ]
                    textRole: "label"
                    currentIndex: {
                        const idx = model.findIndex(entry => entry.value === CaptionEngine.sourceLanguage);
                        return idx >= 0 ? idx : 0;
                    }
                    onActivated: index => CaptionEngine.sourceLanguage = model[index].value
                }
            }

            // Separador
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: CachyPalette.specularBorder
            }

            // Traducción en vivo con CachySwitch
            RowLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 8

                CachyLabel {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: CachyI18n.i18n("Traducción en vivo")
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: CachyPalette.text
                }

                CachySwitch {
                    checked: CaptionEngine.translateEnabled
                    onToggled: CaptionEngine.translateEnabled = checked
                }
            }

            // Idioma de destino
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                visible: CaptionEngine.translateEnabled
                spacing: 4

                CachyLabel {
                    text: CachyI18n.i18n("Traducir a")
                    font.pixelSize: 11
                    color: CachyPalette.textSecondary
                }

                CachyComboBox {
                    id: popTargetLanguageCombo
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.preferredHeight: 30
                    model: ["Español", "English", "Français", "Deutsch", "Italiano"]
                    currentIndex: Math.max(0, model.indexOf(CaptionEngine.targetLanguage))
                    onActivated: index => CaptionEngine.targetLanguage = model[index]
                }
            }
        }
    }

    // =========================================================================
    // CONTENIDO PRINCIPAL: Lienzo de subtítulos de alto contraste e historial
    // =========================================================================
    contentData: [
        ColumnLayout {
            anchors.fill: parent
            spacing: CachyTheme.spacingMedium

            // -----------------------------------------------------------------
            // Superficie de subtítulos en vivo (CachyCard Liquid Glass)
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
                        font.pixelSize: root.captionFontSize
                        font.weight: Font.DemiBold
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
                            name: "globe"
                            size: 15
                            color: CachyTheme.accentColor
                        }

                        CachyLabel {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: CaptionEngine.currentTranslation
                            color: CachyTheme.accentColor
                            font.pixelSize: Math.max(13, root.captionFontSize - 4)
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
                                name: "globe"
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
                        name: "microphone"
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
