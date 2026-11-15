import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../core"
import "../services"
import "../ui"

FocusScope {
    id: tv
    property bool active: false
    property var all: []
    property var shown: unlocked ? all : all.filter(t => !t.hidden)
    property bool unlocked: false
    property bool pinMode: false
    property bool pinWrong: false
    property string pinMd5: ""
    readonly property string home: Quickshell.env("HOME")

    onActiveChanged: {
        if (active) {
            unlocked = false
            pinMode = false
            loader.running = true
            focusTimer.restart()
        }
    }

    Timer {
        id: focusTimer
        interval: 60
        onTriggered: keys.forceActiveFocus()
    }

    FileView {
        path: tv.home + "/.config/canvas/private.json"
        onLoaded: {
            try { tv.pinMd5 = JSON.parse(text()).pinMd5 || "" } catch (e) {}
        }
    }

    Process {
        id: loader
        command: ["sh", "-c", "for d in \"$HOME\"/Themes/*/; do n=$(basename \"$d\"); [ -f \"$d/theme.fish\" ] || continue; h=0; [ -f \"$d/.hidden\" ] && h=1; c=$(grep -m1 '^set grub ' \"$d/theme.fish\" | awk '{print $3}'); echo \"$n|$h|$c\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                tv.all = text.trim().split("\n").filter(l => l !== "").map(l => {
                    const p = l.split("|")
                    return { name: p[0], hidden: p[1] === "1", color: p[2] ? "#" + p[2] : Theme.accent }
                })
                const i = tv.shown.findIndex(t => t.name === CurrentTheme.name)
                carousel.currentIndex = Math.max(0, i)
            }
        }
    }

    function apply() {
        const t = shown[carousel.currentIndex]
        if (!t) return
        Quickshell.execDetached(["fish", "-c", "theme " + t.name])
        IslandState.overlay = ""
    }

    function random() {
        if (shown.length < 2) return
        let i = carousel.currentIndex
        while (i === carousel.currentIndex) i = Math.floor(Math.random() * shown.length)
        const n = shown.length
        carousel.highlightMoveDuration = Theme.dur(70)
        spinTimer.left = n + (i - carousel.currentIndex + n) % n
        spinTimer.interval = Math.max(1, Theme.dur(75))
        spinTimer.restart()
    }

    function toggleHidden(t) {
        const file = home + "/Themes/" + t.name + "/.hidden"
        Quickshell.execDetached(["sh", "-c", t.hidden ? "rm -f \"$1\"" : "touch \"$1\"", "sh", file])
        loader.running = true
    }

    function checkPin() {
        if (Qt.md5(pinInput.text) === pinMd5) {
            unlocked = true
            pinMode = false
            keys.forceActiveFocus()
        } else {
            pinWrong = true
            shake.restart()
            wrongTimer.restart()
        }
    }

    Timer {
        id: wrongTimer
        interval: 700
        onTriggered: {
            tv.pinWrong = false
            pinInput.text = ""
        }
    }

    Timer {
        id: spinTimer
        property int left: 0
        interval: Math.max(1, Theme.dur(75))
        repeat: true
        onTriggered: {
            if (left > 0) {
                carousel.incrementCurrentIndex()
                left -= 1
                interval = Math.max(1, Theme.dur(75 + (left < 6 ? (6 - left) * 45 : 0)))
            } else {
                stop()
                carousel.highlightMoveDuration = Theme.dur(380)
            }
        }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (tv.pinMode) return
            if (event.key === Qt.Key_Escape) IslandState.overlay = ""
            else if (event.key === Qt.Key_Left) carousel.decrementCurrentIndex()
            else if (event.key === Qt.Key_Right) carousel.incrementCurrentIndex()
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) tv.apply()
            else if (event.key === Qt.Key_R) tv.random()
            else return
            event.accepted = true
        }
    }

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 24
        height: 34

        Row {
            spacing: 12
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰏘"
                size: 22
                color: Theme.accent
                hoverable: false
            }
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                text: "Themes"
                size: 20
                weight: Font.Bold
            }
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                text: Lang.t.themesCurrent + CurrentTheme.name
                size: 13
                color: Theme.subtext
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 16
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰒝"
                size: 20
                onClicked: tv.random()
            }
            Icon {
                visible: tv.pinMd5 !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: tv.unlocked ? "󰈈" : "󰈉"
                size: 20
                color: tv.unlocked ? Theme.accent : Theme.text
                onClicked: {
                    if (tv.unlocked) {
                        tv.unlocked = false
                    } else {
                        tv.pinMode = true
                        pinInput.text = ""
                        pinInput.forceActiveFocus()
                    }
                }
            }
        }
    }

    PathView {
        id: carousel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: footer.top
        model: tv.shown
        pathItemCount: Math.min(7, tv.shown.length)
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange
        highlightMoveDuration: Theme.dur(380)
        opacity: tv.pinMode ? 0.15 : 1
        Behavior on opacity { NumberAnimation { duration: Theme.dur(250) } }

        path: Path {
            startX: 0
            startY: carousel.height / 2
            PathAttribute { name: "itemScale"; value: 0.5 }
            PathAttribute { name: "itemZ"; value: 0 }
            PathAttribute { name: "itemOpacity"; value: 0.25 }
            PathLine { x: carousel.width / 2; y: carousel.height / 2 }
            PathAttribute { name: "itemScale"; value: 1.0 }
            PathAttribute { name: "itemZ"; value: 10 }
            PathAttribute { name: "itemOpacity"; value: 1.0 }
            PathLine { x: carousel.width; y: carousel.height / 2 }
            PathAttribute { name: "itemScale"; value: 0.5 }
            PathAttribute { name: "itemZ"; value: 0 }
            PathAttribute { name: "itemOpacity"; value: 0.25 }
        }

        WheelHandler {
            onWheel: event => {
                if (event.angleDelta.y > 0 || event.angleDelta.x > 0) carousel.decrementCurrentIndex()
                else carousel.incrementCurrentIndex()
            }
        }

        delegate: Item {
            id: card
            required property var modelData
            required property int index
            property bool current: PathView.isCurrentItem
            width: 320
            height: 230
            scale: PathView.itemScale
            z: PathView.itemZ
            opacity: PathView.itemOpacity

            ClippingRectangle {
                id: frame
                width: parent.width
                height: 190
                radius: 24
                color: Theme.surfaceHigh
                border.width: card.current ? 3 : 1
                border.color: card.current ? card.modelData.color : Theme.alpha(Theme.text, 0.15)

                Image {
                    anchors.fill: parent
                    source: "file://" + tv.home + "/Themes/" + card.modelData.name + "/lock.png"
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 480
                    asynchronous: true
                    scale: cardHover.hovered && card.current ? 1.06 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.dur(300) } }
                }

                Rectangle {
                    visible: card.modelData.name === CurrentTheme.name
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 12
                    width: 72
                    height: 24
                    radius: 12
                    color: card.modelData.color
                    Txt {
                        anchors.centerIn: parent
                        text: Lang.t.themesActive
                        size: 11
                        weight: Font.DemiBold
                        color: "#111111"
                    }
                }

                Icon {
                    visible: card.modelData.hidden
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 12
                    text: "󰌾"
                    size: 18
                    color: "#ffffff"
                    hoverable: false
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: frame.bottom
                anchors.topMargin: 12
                spacing: 8
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 10
                    height: 10
                    radius: 5
                    color: card.modelData.color
                }
                Txt {
                    text: card.modelData.name.charAt(0).toUpperCase() + card.modelData.name.slice(1)
                    size: 16
                    weight: Font.DemiBold
                }
            }

            HoverHandler { id: cardHover }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        if (tv.unlocked) tv.toggleHidden(card.modelData)
                    } else if (card.current) {
                        tv.apply()
                    } else {
                        carousel.currentIndex = card.index
                    }
                }
            }
        }
    }

    Column {
        anchors.centerIn: carousel
        spacing: 16
        visible: opacity > 0
        opacity: tv.pinMode ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(250) } }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tv.pinWrong ? Lang.t.pinWrong : Lang.t.pinEnter
            size: 16
            weight: Font.DemiBold
            color: tv.pinWrong ? "#ff6b6b" : Theme.text
        }

        Row {
            id: dots
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14
            Repeater {
                model: 4
                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    color: index < pinInput.text.length ? (tv.pinWrong ? "#ff6b6b" : Theme.accent) : "transparent"
                    border.width: 2
                    border.color: tv.pinWrong ? "#ff6b6b" : Theme.accent
                    scale: index < pinInput.text.length ? 1.15 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.dur(150); easing.type: Easing.OutBack } }
                }
            }

            SequentialAnimation {
                id: shake
                NumberAnimation { target: dots; property: "anchors.horizontalCenterOffset"; to: -14; duration: 50 }
                NumberAnimation { target: dots; property: "anchors.horizontalCenterOffset"; to: 14; duration: 70 }
                NumberAnimation { target: dots; property: "anchors.horizontalCenterOffset"; to: -8; duration: 70 }
                NumberAnimation { target: dots; property: "anchors.horizontalCenterOffset"; to: 0; duration: 60 }
            }
        }

        TextInput {
            id: pinInput
            width: 1
            height: 1
            opacity: 0
            maximumLength: 4
            validator: RegularExpressionValidator { regularExpression: /[0-9]*/ }
            onTextChanged: if (text.length === 4 && !tv.pinWrong) tv.checkPin()
            Keys.onEscapePressed: {
                tv.pinMode = false
                keys.forceActiveFocus()
            }
        }
    }

    Txt {
        id: footer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        text: Lang.t.themesHint + (tv.unlocked ? Lang.t.themesHintPrivate : "")
        size: 12
        color: Theme.subtext
    }
}
