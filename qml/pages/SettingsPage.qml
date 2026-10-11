import QtQuick 2.6
import Sailfish.Silica 1.0

Page {
    id: settingsPage

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

            TextField {
                id: cheapField
                width: parent.width
                label: qsTr("Vihreä, kun hinta on korkeintaan (snt/kWh)")
                placeholderText: "2,00"
                text: appSettings.cheapThreshold.toFixed(2).replace(".", ",")
                inputMethodHints: Qt.ImhFormattedNumbersOnly
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
                placeholderText: "10,00"
                text: appSettings.expensiveThreshold.toFixed(2).replace(".", ",")
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false
                onActiveFocusChanged: {
                    if (!activeFocus)
                        applyExpensive(text)
                }
                Component.onDestruction: applyExpensive(text)
            }

            SectionHeader {
                text: qsTr("Graafin tarkkuus")
            }

            ComboBox {
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
