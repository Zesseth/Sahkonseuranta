import QtQuick 2.6
import Sailfish.Silica 1.0

Page {
    id: settingsPage

    readonly property color cardColor: Theme.rgba(Theme.highlightBackgroundColor, 0.15)

    function applyCheap(text) {
        var v = parseFloat(String(text).replace(",", "."))
        if (!isNaN(v))
            appSettings.cheapThreshold = v
    }

    function applyExpensive(text) {
        var v = parseFloat(String(text).replace(",", "."))
        if (!isNaN(v))
            appSettings.expensiveThreshold = v
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
                text: qsTr("Pallon värit")
            }

            // Cheap threshold card
            Rectangle {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: cheapField.height + 2 * Theme.paddingMedium
                radius: Theme.paddingSmall
                color: settingsPage.cardColor

                TextField {
                    id: cheapField
                    width: parent.width - 2 * Theme.paddingMedium
                    anchors.centerIn: parent
                    label: qsTr("Vihreä, kun hinta on korkeintaan (snt/kWh)")
                    placeholderText: "2,00"
                    text: appSettings.cheapThreshold.toFixed(2).replace(".", ",")
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: expensiveField.focus = true
                    onAccepted: applyCheap(text)
                    onActiveFocusChanged: {
                        if (!activeFocus)
                            applyCheap(text)
                    }
                    Component.onDestruction: applyCheap(text)
                }
            }

            // Expensive threshold card
            Rectangle {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: expensiveField.height + 2 * Theme.paddingMedium
                radius: Theme.paddingSmall
                color: settingsPage.cardColor

                TextField {
                    id: expensiveField
                    width: parent.width - 2 * Theme.paddingMedium
                    anchors.centerIn: parent
                    label: qsTr("Punainen, kun hinta on vähintään (snt/kWh)")
                    placeholderText: "10,00"
                    text: appSettings.expensiveThreshold.toFixed(2).replace(".", ",")
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    EnterKey.iconSource: "image://theme/icon-m-enter-close"
                    EnterKey.onClicked: focus = false
                    onAccepted: applyExpensive(text)
                    onActiveFocusChanged: {
                        if (!activeFocus)
                            applyExpensive(text)
                    }
                    Component.onDestruction: applyExpensive(text)
                }
            }

            SectionHeader {
                text: qsTr("Graafin tarkkuus")
            }

            // Resolution card
            Rectangle {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: resolutionCombo.height + 2 * Theme.paddingMedium
                radius: Theme.paddingSmall
                color: settingsPage.cardColor

                ComboBox {
                    id: resolutionCombo
                    width: parent.width - 2 * Theme.paddingMedium
                    anchors.centerIn: parent
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
