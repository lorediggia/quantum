import QtQuick

Loader {
    id: root

    property bool shouldBeActive: false
    property bool everActivated:  false

    active: everActivated

    onShouldBeActiveChanged: {
        if (shouldBeActive) {
            everActivated = true
            if (item && typeof item.open === "function") item.open()
        }
    }

    onLoaded: {
        if (shouldBeActive && item && typeof item.open === "function") item.open()
    }
}
