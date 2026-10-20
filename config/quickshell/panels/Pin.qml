import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import qs.widgets

Panel {
    id: pin
    readonly property var t: Desktop.target
    property string app: ""
    property string icon: ""
    property int mine: -2
    property bool loading: false
    readonly property var picks: app || fCmd.text || !fName.text ? [] : Apps.search(fName.text).slice(0, 6)
    readonly property bool ok: fName.text !== "" && (fCmd.text !== "" || app !== "")
    readonly property string home: Cfg.home

    implicitWidth: 440
    spacing: 12

    function load() {
        if (!t || t.index === mine) return
        loading = true
        const r = Desktop.icons[t.index] ?? {}
        fName.text = r.name ?? ""; fCmd.text = r.cmd ?? ""; app = r.app ?? ""; icon = r.icon ?? ""
        mine = t.index
        loading = false
        later.stop()
        fName.grab()
    }
    function apply() {
        if (loading || !t || !ok) return
        const row = { name: fName.text, icon, cmd: fCmd.text, app: fCmd.text ? "" : app, col: t.col, row: t.row }
        if (t.index >= 0) return Desktop.put(t.index, row)
        Desktop.put(-1, row)
        mine = Desktop.icons.length - 1
        Desktop.target = { index: mine, col: t.col, row: t.row }
    }
    function pick(e) { app = e.id; fName.text = e.name; apply() }
    function tilde(p) { return p.startsWith(home + "/") ? "~" + p.slice(home.length) : p }
    function choose() {
        Desktop.picking = true
        Util.run(["zenity", "--file-selection", "--filename=" + home + "/pictures/", "--file-filter=*.png *.svg *.jpg *.jpeg *.webp *.gif"], out => {
            Desktop.picking = false
            if (out.trim()) icon = tilde(out.trim())
        })
    }

    onTChanged: load()
    Component.onCompleted: load()
    onAppChanged: later.restart()
    onIconChanged: later.restart()
    Timer { id: later; interval: 250; onTriggered: pin.apply() }

    RowLayout {
        spacing: 14
        Tile {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 74
            implicitHeight: 74
            radius: 22
            color: hovered ? Theme.fgA(0.08) : Theme.fgA(0.04)
            onClicked: pin.choose()
            Icon { anchors.centerIn: parent; size: 48; source: Desktop.iconOf({ icon: pin.icon, app: pin.app, cmd: fCmd.text }) }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            Field { id: fName; Layout.fillWidth: true; implicitHeight: 34; hint: "󰍉"
                    onTextChanged: later.restart(); onAccepted: pin.picks.length ? pin.pick(pin.picks[0]) : Ui.close() }
            Field { id: fCmd; Layout.fillWidth: true; implicitHeight: 34; hint: "󰆍"
                    onTextChanged: later.restart(); onAccepted: Ui.close() }
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 34
            spacing: 6
            Btn { visible: (pin.t?.index ?? -1) >= 0; plain: true; size: 34; icon: "󰆴"; onClicked: { Desktop.drop(pin.t.index); Ui.close() } }
            Btn { visible: pin.icon !== ""; plain: true; size: 34; icon: "󰦛"; onClicked: pin.icon = "" }
        }
    }

    Row {
        visible: pin.picks.length > 0
        Layout.leftMargin: 88
        spacing: 6
        Repeater {
            model: pin.picks
            Tile {
                required property var modelData
                width: 34
                height: 34
                color: hovered ? Theme.accA(0.14) : Theme.fgA(0.05)
                onClicked: pin.pick(modelData)
                Icon { anchors.centerIn: parent; size: 20; source: parent.modelData.icon }
            }
        }
    }
}
