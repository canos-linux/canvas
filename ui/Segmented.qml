import QtQuick
import "../core"

Rectangle {
    id: seg
    property var options: []
    property var values: []
    property var value
    signal picked(var v)
    property int current: Math.max(0, values.indexOf(value))
    width: options.length * 84 + 8
    height: 34
    radius: 17
    color: Theme.surfaceHigh

    Rectangle {
        y: 4
        x: 4 + seg.current * 84
        width: 84
        height: 26
        radius: 13
        color: Theme.accent
        Behavior on x { NumberAnimation { duration: Theme.dur(280); easing.type: Easing.OutBack } }
    }

    Row {
        x: 4
        y: 4
        Repeater {
            model: seg.options
            Item {
                width: 84
                height: 26
                Txt {
                    anchors.centerIn: parent
                    text: modelData
                    size: 13
                    weight: Font.Medium
                    color: index === seg.current ? Theme.base : Theme.text
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: seg.picked(seg.values[index])
                }
            }
        }
    }
}
