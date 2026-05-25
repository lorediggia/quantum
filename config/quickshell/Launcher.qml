import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: launcherWin


    property var allApps: []

    property color themeBg
    property color themeFg
    property color themeAccent
    property color themeSecond

    readonly property color textMain: Qt.rgba(themeFg.r, themeFg.g, themeFg.b, 0.95)
    readonly property color textDim:  Qt.rgba(themeFg.r, themeFg.g, themeFg.b, 0.40)
    readonly property color selBg:    Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.12)
    readonly property color selBd:    themeAccent

    property string query: ""
    property int selectedIdx: 0

    readonly property var filteredApps: {
        if (query === "") return allApps
        const q = query.toLowerCase()
        return allApps.filter(a => a.name.toLowerCase().includes(q))
    }

    WlrLayershell.namespace:     "quickshell-launcher"
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    implicitWidth: 380
    implicitHeight: 420
    color: "transparent"
    visible: false

    function show() {
        visible = true
        searchInput.text = ""
        selectedIdx = 0
        Qt.callLater(() => searchInput.forceActiveFocus())
    }
    function hide()   { visible = false }
    function toggle() { visible ? hide() : show() }

    function launch(idx) {
        const list = filteredApps
        if (idx < 0 || idx >= list.length) return
        spawnProc.command = ["sh", "-c", "setsid -f " + list[idx].exec + " </dev/null >/dev/null 2>&1"]
        spawnProc.running = true
        hide()
    }

    function moveSel(delta) {
        const n = filteredApps.length
        if (n === 0) return
        selectedIdx = Math.max(0, Math.min(n - 1, selectedIdx + delta))
        appList.positionViewAtIndex(selectedIdx, ListView.Contain)
    }

    Process { id: spawnProc }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: launcherWin.themeBg
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.05)
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 40

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: searchInput.activeFocus ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(1, 1, 1, 0.02)
                    Behavior on color { ColorAnimation { duration: 200 } }
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
                        selectedTextColor: launcherWin.themeAccent

                        onTextChanged: { launcherWin.query = text; launcherWin.selectedIdx = 0 }

                        Keys.onDownPressed:   moveSel(1)
                        Keys.onUpPressed:     moveSel(-1)
                        Keys.onPressed: (event) => {
                            if      (event.key === Qt.Key_PageDown) { moveSel(6);  event.accepted = true }
                            else if (event.key === Qt.Key_PageUp)   { moveSel(-6); event.accepted = true }
                        }
                        Keys.onReturnPressed: launcherWin.launch(selectedIdx)
                        Keys.onEnterPressed:  launcherWin.launch(selectedIdx)
                        Keys.onEscapePressed: launcherWin.hide()

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

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 2
                    width: searchInput.activeFocus ? parent.width - 24 : 0
                    color: launcherWin.themeAccent
                    radius: 1
                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
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

                delegate: Item {
                    width: ListView.view.width
                    height: 36

                    readonly property bool isSel: index === launcherWin.selectedIdx

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: isSel ? selBg : (rowHover.hovered ? Qt.rgba(1, 1, 1, 0.03) : "transparent")
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 4
                        width: 3
                        height: isSel ? 18 : 0
                        radius: 2
                        color: selBd
                        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    }

                    HoverHandler { id: rowHover }
                    TapHandler { onTapped: { launcherWin.selectedIdx = index; launcherWin.launch(index) } }

                    Text {
                        anchors.fill: parent
                        anchors { leftMargin: 16; rightMargin: 16 }
                        verticalAlignment: Text.AlignVCenter
                        text: modelData.name
                        color: parent.isSel ? launcherWin.themeAccent : textMain
                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 13; weight: parent.isSel ? Font.Bold : Font.Normal; letterSpacing: 0.3 }
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
}
