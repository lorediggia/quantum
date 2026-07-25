import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: launcherWin

    property var allApps: []

    property color themeFg:     "#ffffff"
    property color themeAccent: "#ffffff"
    property color themeSecond: "#ffffff"

    readonly property color textMain: Qt.rgba(themeFg.r, themeFg.g, themeFg.b, 0.95)
    readonly property color textDim:  Qt.rgba(themeFg.r, themeFg.g, themeFg.b, 0.40)
    readonly property color selBg:    Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.15)

    property string query: ""

    signal requestClose()

    implicitWidth:  420
    implicitHeight: 440

    readonly property var filteredApps: {
        if (query === "") return allApps
        const q = query.toLowerCase()
        return allApps.filter(a => a.name.toLowerCase().includes(q))
    }

    function open() {
        searchInput.text = ""
        appList.currentIndex = 0
        Qt.callLater(() => searchInput.forceActiveFocus())
    }

    function launch(idx) {
        const list = filteredApps
        if (idx < 0 || idx >= list.length) return
        spawnProc.command = ["sh", "-c", "setsid -f " + list[idx].exec + " </dev/null >/dev/null 2>&1"]
        spawnProc.running = true
        requestClose()
    }

    function moveSel(delta) {
        const n = filteredApps.length
        if (n === 0) return
        appList.currentIndex = Math.max(0, Math.min(n - 1, appList.currentIndex + delta))
        appList.positionViewAtIndex(appList.currentIndex, ListView.Contain)
    }

    Process { id: spawnProc }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        anchors.topMargin: 18
        spacing: 16

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 40

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: searchInput.activeFocus ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.08) : "transparent"
                border.width: 1
                border.color: searchInput.activeFocus ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.3) : Qt.rgba(themeFg.r, themeFg.g, themeFg.b, 0.1)
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                Text {
                    text: "󰍉"
                    color: searchInput.activeFocus ? launcherWin.themeAccent : textDim
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 16 }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    verticalAlignment: TextInput.AlignVCenter
                    color: textMain
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 14; weight: Font.Medium }
                    selectByMouse: true
                    clip: true
                    selectionColor: selBg
                    selectedTextColor: textMain

                    onTextChanged: { launcherWin.query = text; appList.currentIndex = 0 }

                    Keys.onDownPressed:   moveSel(1)
                    Keys.onUpPressed:     moveSel(-1)
                    Keys.onPressed: (event) => {
                        if      (event.key === Qt.Key_PageDown) { moveSel(6);  event.accepted = true }
                        else if (event.key === Qt.Key_PageUp)   { moveSel(-6); event.accepted = true }
                    }
                    Keys.onReturnPressed: launcherWin.launch(appList.currentIndex)
                    Keys.onEnterPressed:  launcherWin.launch(appList.currentIndex)
                    Keys.onEscapePressed: launcherWin.requestClose()

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Search..."
                        color: textDim
                        visible: searchInput.text === ""
                        font: searchInput.font
                    }
                }
            }
        }

        ListView {
            id: appList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: launcherWin.filteredApps
            boundsBehavior: Flickable.DragAndOvershootBounds
            flickDeceleration: 3000
            pixelAligned: true
            cacheBuffer: 300

            currentIndex: 0
            highlightMoveDuration: 250
            highlightFollowsCurrentItem: true

            highlight: Item {
                z: 0
                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: selBg
                }
            }

            delegate: Item {
                width: ListView.view.width
                height: 38

                readonly property bool isSel: ListView.isCurrentItem

                TapHandler { onTapped: { appList.currentIndex = index; launcherWin.launch(index) } }

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    verticalAlignment: Text.AlignVCenter
                    text: modelData.name
                    color: isSel ? textMain : textDim
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 13; weight: isSel ? Font.Bold : Font.Medium; letterSpacing: 0.3 }
                    elide: Text.ElideRight

                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            Text {
                anchors.centerIn: parent
                text: launcherWin.allApps.length === 0 ? "Loading..." : "No matches found"
                color: textDim
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 12; italic: true }
                visible: launcherWin.filteredApps.length === 0
            }
        }
    }
}
