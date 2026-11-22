import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pam
import "../core"
import "../services"
import "../ui"

Item {
    id: lc
    property bool preview: false
    property string status: ""
    signal unlocked()

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Image {
        id: bg
        anchors.fill: parent
        source: CurrentTheme.dir !== "" ? "file://" + CurrentTheme.dir + "/lock.png" : ""
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: bg
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        brightness: -0.15
        scale: intro.running ? 1.08 : 1
        Behavior on scale { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.base, 0.35)
    }

    Column {
        id: clockCol
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.2
        spacing: 4
        opacity: 0
        transform: Translate { id: clockShift; y: -60 }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clock.date, Config.timeFmt)
            size: 128
            weight: Font.Bold
        }
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: clock.date.toLocaleString(Lang.locale, Lang.t.dateLong)
            size: 22
            color: Theme.subtext
        }
    }

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: 0
        y: parent.height * 0.62
        width: input.text.length > 0 ? Math.max(260, 120 + input.text.length * 22) : 260
        height: 64
        radius: 32
        color: Theme.panel
        border.width: 2
        border.color: lc.status === "wrong" ? "#ff6b6b" : Theme.alpha(Theme.accent, lc.status === "checking" ? 1 : 0.6)
        opacity: 0
        Behavior on width { NumberAnimation { duration: Theme.dur(300); easing.type: Easing.OutBack } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        ClippingRectangle {
            id: avatar
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 48
            height: 48
            radius: 24
            color: Theme.surfaceHigh
            Image {
                anchors.fill: parent
                source: CurrentTheme.face !== "" ? "file://" + CurrentTheme.face : ""
                fillMode: Image.PreserveAspectCrop
            }
        }

        Txt {
            visible: input.text.length === 0
            anchors.left: avatar.right
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: lc.status === "wrong" ? Lang.t.pwWrong : Lang.t.pwEnter
            size: 16
            color: lc.status === "wrong" ? "#ff6b6b" : Theme.subtext
        }

        Row {
            anchors.left: avatar.right
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            Repeater {
                model: input.text.length
                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    color: Theme.accent
                    scale: 0
                    Component.onCompleted: pop.start()
                    NumberAnimation on scale {
                        id: pop
                        running: false
                        to: 1
                        duration: Theme.dur(220)
                        easing.type: Easing.OutBack
                    }
                    SequentialAnimation on opacity {
                        running: lc.status === "checking"
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 400 }
                        NumberAnimation { to: 1; duration: 400 }
                    }
                }
            }
        }

        SequentialAnimation {
            id: shake
            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: -18; duration: 50 }
            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: 18; duration: 80 }
            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: -10; duration: 80 }
            NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: 0; duration: 70 }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        spacing: 24
        opacity: 0.85

        Row {
            visible: Power.present
            spacing: 8
            BatteryIcon { anchors.verticalCenter: parent.verticalCenter }
            Txt { anchors.verticalCenter: parent.verticalCenter; text: Power.percent + "%"; size: 14 }
        }
        Txt {
            visible: Media.player !== null && Media.title !== "" && !Config.opt.lockMusic
            anchors.verticalCenter: parent.verticalCenter
            text: "󰎈  " + Media.title
            size: 14
        }
        Txt {
            visible: lc.preview
            anchors.verticalCenter: parent.verticalCenter
            text: Lang.t.lockPreviewHint
            size: 14
            color: Theme.subtext
        }
    }

    LockExtras {
        anchors.fill: parent
        opacity: clockCol.opacity
    }

    ParallelAnimation {
        id: intro
        running: true
        NumberAnimation { target: clockCol; property: "opacity"; to: 1; duration: Theme.dur(700) }
        NumberAnimation { target: clockShift; property: "y"; to: 0; duration: Theme.dur(800); easing.type: Easing.OutCubic }
        SequentialAnimation {
            PauseAnimation { duration: Theme.dur(250) }
            NumberAnimation { target: pill; property: "opacity"; to: 1; duration: Theme.dur(500) }
        }
    }

    PamContext {
        id: pam
        onPamMessage: {
            if (responseRequired) respond(input.text)
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                lc.status = ""
                lc.unlocked()
            } else {
                lc.status = "wrong"
                input.text = ""
                shake.restart()
            }
        }
    }

    TextInput {
        id: input
        width: 1
        height: 1
        opacity: 0
        focus: true
        echoMode: TextInput.Password
        Component.onCompleted: forceActiveFocus()
        onTextChanged: if (text.length > 0 && lc.status === "wrong") lc.status = ""
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (text.length > 0 && lc.status !== "checking") {
                    lc.status = "checking"
                    pam.start()
                }
                event.accepted = true
            } else if (event.key === Qt.Key_Escape) {
                if (lc.preview) lc.unlocked()
                else text = ""
                event.accepted = true
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: input.forceActiveFocus()
    }
}
