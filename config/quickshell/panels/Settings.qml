import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import qs.widgets

Item {
    id: st
    readonly property var look: Cfg.look
    readonly property var bar: Cfg.bar
    property bool resetting: false

    component Opt: RowLayout {
        property alias label: text.text
        Layout.fillWidth: true
        Layout.preferredHeight: 28
        spacing: 12
        T { id: text; Layout.fillWidth: true; color: Theme.fgA(0.75); font.pixelSize: 12 }
    }
    component Switch: Opt {
        id: sw
        property alias checked: toggle.checked
        signal flipped()
        Toggle { id: toggle; onClicked: sw.flipped() }
    }
    component Section: Caption { Layout.topMargin: 10 }

    ColumnLayout {
        anchors { fill: parent; margins: 24 }
        spacing: 20

        Head {
            icon: Ui.icons.settings
            title: "settings"
            Btn { size: 28; icon: st.resetting ? "󰄬" : "󰦛"; active: st.resetting; onClicked: st.resetting ? Cfg.reset() : st.resetting = true }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: page.implicitHeight

            ColumnLayout {
                id: page
                width: parent.width
                spacing: 10

                Caption { text: "Look" }
                Opt {
                    label: "Theme"
                    Chips { options: [{ value: false, label: "󰖔" }, { value: true, label: "󰖨" }]; current: st.look.light; onPicked: v => st.look.light = v }
                }
                Row {
                    id: swatches
                    readonly property real s: Math.floor((width - 7 * spacing) / 8)
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: ["", ...Theme.swatches.slice(0, 7)]
                        Tile {
                            required property string modelData
                            width: swatches.s
                            height: swatches.s
                            radius: Math.round(swatches.s * 0.36)
                            color: modelData || Theme.fgA(0.08)
                            border { width: st.look.accent === modelData ? 2 : 0; color: Theme.fg }
                            onClicked: st.look.accent = modelData
                            T { anchors.centerIn: parent; visible: parent.modelData === ""; text: "󰸉"; color: Theme.fgA(0.6); font.pixelSize: 12 }
                        }
                    }
                }
                Opt { label: "Corner radius";   Stepper { value: st.look.rad;     to: 30;                       onMoved: v => st.look.rad = v } }
                Opt { label: "Bar height";      Stepper { value: st.look.barH;    from: 28; to: 60;             onMoved: v => st.look.barH = v } }
                Opt { label: "Frame thickness"; Stepper { value: st.look.edge;    to: 30;                       onMoved: v => st.look.edge = v } }
                Opt { label: "Drawer width";    Stepper { value: st.look.drawerW; from: 260; to: 460; step: 20; onMoved: v => st.look.drawerW = v } }
                Opt { label: "Animation speed"; Stepper { value: st.look.speed;   from: 0.5; to: 2; step: 0.1; suffix: "×"; onMoved: v => st.look.speed = v } }

                Section { text: "Bar" }
                Item {
                    id: order
                    property int from: -1
                    property int to: -1
                    readonly property var on: st.bar.buttons
                    readonly property real step: Math.min(34, width / Math.max(1, on.length))
                    function slot(i) { return from < 0 || i === from ? i : i > from && i <= to ? i - 1 : i < from && i >= to ? i + 1 : i }
                    Layout.fillWidth: true
                    implicitHeight: 28
                    Repeater {
                        model: order.on
                        Btn {
                            required property string modelData
                            required property int index
                            x: order.slot(index) * order.step
                            z: dh.active ? 1 : 0
                            plain: true
                            size: 28
                            icon: Act.icon(modelData)
                            lit: true
                            Behavior on x { enabled: !dh.active; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            onXChanged: if (dh.active) order.to = Util.clamp(Math.round(x / order.step), 0, order.on.length - 1)
                            onClicked: st.bar.buttons = order.on.filter(k => k !== modelData)
                            DragHandler {
                                id: dh
                                yAxis.enabled: false
                                xAxis { minimum: 0; maximum: order.width - 28 }
                                onActiveChanged: {
                                    if (active) return order.from = order.to = parent.index
                                    const a = order.on.slice()
                                    a.splice(order.to, 0, a.splice(order.from, 1)[0])
                                    order.from = -1
                                    st.bar.buttons = a
                                }
                            }
                        }
                    }
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: Object.keys(Ui.icons).filter(k => !st.bar.buttons.includes(k))
                        Btn {
                            required property string modelData
                            plain: true
                            size: 28
                            icon: Act.icon(modelData)
                            opacity: hovered ? 1 : 0.35
                            onClicked: st.bar.buttons = [...st.bar.buttons, modelData]
                        }
                    }
                }
                Opt    { label: "Workspaces"; Stepper { value: st.bar.wsCount; to: 10; onMoved: v => st.bar.wsCount = v } }
                Switch { label: "Japanese numerals"; checked: st.bar.japanese; onFlipped: st.bar.japanese = !checked }
                Switch { label: "Focused app";       checked: st.bar.appName;  onFlipped: st.bar.appName = !checked }
                Switch { label: "24-hour clock";     checked: st.bar.clock24;  onFlipped: st.bar.clock24 = !checked }
                Switch { label: "Seconds";           checked: st.bar.seconds;  onFlipped: st.bar.seconds = !checked }
                Switch { label: "Date";              checked: st.bar.date;     onFlipped: st.bar.date = !checked }
                Switch { label: "Now playing";       checked: st.bar.media;    onFlipped: st.bar.media = !checked }

                Section { text: "Desktop" }
                Switch { label: "Icons";     checked: Cfg.desktop.show; onFlipped: Cfg.desktop.show = !checked }
                Opt    { label: "Icon size"; Stepper { value: Cfg.desktop.size; from: 32; to: 96; step: 8; onMoved: v => Cfg.desktop.size = v } }

                Section { text: "Stickers" }
                Chips {
                    Layout.fillWidth: true
                    options: [{ value: "", label: "All" }, ...Stickers.packs]
                    current: Cfg.pack
                    onPicked: v => Cfg.pack = v
                }

                Section { text: "Wallpapers" }
                Field { Layout.fillWidth: true; implicitHeight: 28; hint: "󰉋"; text: Cfg.wallDir; onAccepted: Cfg.wallDir = text }
            }
        }
    }
}
