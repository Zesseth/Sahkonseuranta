// SPDX-License-Identifier: AGPL-3.0-or-later
import QtQuick 2.6
import Sailfish.Silica 1.0

Page {
    id: settingsPage

    readonly property color cardColor: Theme.rgba(Theme.highlightBackgroundColor, 0.2)
    readonly property int cardRadius: Theme.paddingLarge

    function fmt(v) {
        return Math.round(v)
    }

    function applyCheap(text) {
        var v = parseFloat(String(text).replace(",", "."))
        if (!isNaN(v))
            appSettings.cheapThreshold = v
        cheapField.text = fmt(appSettings.cheapThreshold)
        expensiveField.text = fmt(appSettings.expensiveThreshold)
    }

    function applyExpensive(text) {
        var v = parseFloat(String(text).replace(",", "."))
        if (!isNaN(v))
            appSettings.expensiveThreshold = v
        expensiveField.text = fmt(appSettings.expensiveThreshold)
    }

    SilicaFlickable {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: aboutCard.top
        }
        contentHeight: column.height + Theme.paddingLarge

        VerticalScrollDecorator {}

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Asetukset")
            }

            // Price thresholds card
            Rectangle {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: thresholdColumn.height + 2 * Theme.paddingLarge
                radius: settingsPage.cardRadius
                color: settingsPage.cardColor

                Column {
                    id: thresholdColumn
                    spacing: Theme.paddingMedium
                    width: parent.width - 2 * Theme.paddingLarge
                    anchors.centerIn: parent

                    Label {
                        text: qsTr("Hintarajat")
                        color: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeMedium
                        font.bold: true
                    }

                    TextField {
                        id: cheapField
                        width: parent.width
                        label: qsTr("Vihreä, kun hinta on korkeintaan (snt/kWh)")
                        placeholderText: "5"
                        text: fmt(appSettings.cheapThreshold)
                        inputMethodHints: Qt.ImhDigitsOnly
                        EnterKey.iconSource: "image://theme/icon-m-enter-next"
                        EnterKey.onClicked: expensiveField.focus = true
                        onActiveFocusChanged: {
                            if (!activeFocus)
                                applyCheap(text)
                        }
                        Component.onDestruction: applyCheap(text)
                    }

                    TextField {
                        id: expensiveField
                        width: parent.width
                        label: qsTr("Punainen, kun hinta on vähintään (snt/kWh)")
                        placeholderText: "10"
                        text: fmt(appSettings.expensiveThreshold)
                        inputMethodHints: Qt.ImhDigitsOnly
                        EnterKey.iconSource: "image://theme/icon-m-enter-close"
                        EnterKey.onClicked: focus = false
                        onActiveFocusChanged: {
                            if (!activeFocus)
                                applyExpensive(text)
                        }
                        Component.onDestruction: applyExpensive(text)
                    }
                }
            }

            // Chart resolution card
            Rectangle {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: resolutionColumn.height + 2 * Theme.paddingLarge
                radius: settingsPage.cardRadius
                color: settingsPage.cardColor

                Column {
                    id: resolutionColumn
                    spacing: Theme.paddingMedium
                    width: parent.width - 2 * Theme.paddingLarge
                    anchors.centerIn: parent

                    Label {
                        text: qsTr("Graafin tarkkuus")
                        color: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeMedium
                        font.bold: true
                    }

                    ComboBox {
                        id: resolutionCombo
                        width: parent.width
                        label: qsTr("Palkkien hinnoittelu")
                        currentIndex: appSettings.resolution === 60 ? 1 : 0
                        menu: ContextMenu {
                            MenuItem { text: qsTr("15 min") }
                            MenuItem { text: qsTr("1 tunti") }
                        }
                        onCurrentIndexChanged: {
                            appSettings.resolution = currentIndex === 1 ? 60 : 15
                        }
                    }
                }
            }
        }
    }

    // About card pinned to the bottom of the page
    Rectangle {
        id: aboutCard
        x: Theme.horizontalPageMargin
        width: parent.width - 2 * Theme.horizontalPageMargin
        height: aboutColumn.height + 2 * Theme.paddingLarge
        radius: settingsPage.cardRadius
        color: settingsPage.cardColor
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingMedium

        Column {
            id: aboutColumn
            spacing: Theme.paddingMedium
            width: parent.width - 2 * Theme.paddingLarge
            anchors.centerIn: parent

            Label {
                text: qsTr("Tietoja")
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
            }

            Label {
                text: qsTr("Versio %1").arg(appVersion)
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeMedium
            }

            Label {
                text: "<a href=\"https://github.com/Zesseth/Sahkonseuranta\">GitHub</a>"
                color: Theme.highlightColor
                linkColor: Theme.highlightColor
                font.pixelSize: Theme.fontSizeMedium
                textFormat: Text.RichText
                onLinkActivated: Qt.openUrlExternally(link)
            }
        }
    }
}
