// SPDX-License-Identifier: AGPL-3.0-or-later
import QtQuick 2.6
import Sailfish.Silica 1.0

Page {
    id: settingsPage

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

    onStatusChanged: {
        if (status === PageStatus.Deactivating) {
            applyCheap(cheapField.text)
            applyExpensive(expensiveField.text)
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        VerticalScrollDecorator {}

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Asetukset")
            }

            SectionHeader {
                text: qsTr("Hintarajat")
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
            }

            SectionHeader {
                text: qsTr("Graafin tarkkuus")
            }

            ComboBox {
                id: resolutionCombo
                width: parent.width
                label: qsTr("Palkkien hinnoittelu")
                // Reactive: reflects external changes to the setting
                currentIndex: appSettings.resolution === 60 ? 1 : 0
                // Writes only after construction, so index changes
                // during page build do not trigger redundant writes
                property bool ready: false
                Component.onCompleted: ready = true
                menu: ContextMenu {
                    MenuItem { text: qsTr("15 min") }
                    MenuItem { text: qsTr("1 tunti") }
                }
                onCurrentIndexChanged: {
                    if (ready)
                        appSettings.resolution = currentIndex === 1 ? 60 : 15
                }
            }

            SectionHeader {
                text: qsTr("Tietoja")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: qsTr("Versio %1").arg(appVersion)
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeMedium
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: "<a href=\"https://github.com/Zesseth/Sahkonseuranta\">GitHub</a>"
                color: Theme.highlightColor
                linkColor: Theme.primaryColor
                font.pixelSize: Theme.fontSizeMedium
                textFormat: Text.RichText
                onLinkActivated: Qt.openUrlExternally(link)
            }
        }
    }
}
