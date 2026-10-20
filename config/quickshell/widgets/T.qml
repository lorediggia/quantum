import QtQuick
import qs.core

Text {
    color: Theme.fg
    font.family: /[\uE000-\uF8FF]|[\u{F0000}-\u{FFFFD}]/u.test(text) ? Theme.mono : Theme.sans
}
