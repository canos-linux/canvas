import QtQuick
import "../core"
import "../ui"

Column {
    id: row
    property string title: ""
    property string sub: ""
    property var options: []
    property var values: []
    property var value
    property bool searchable: false
    property string placeholder: ""
    property bool open: false
    signal picked(var v)
    readonly property int cur: values.indexOf(value)
    property var shown: {
        const q = search.text.toLowerCase()
        const r = []
        for (let i = 0; i < options.length; i++)
            if (!q || String(options[i]).toLowerCase().indexOf(q) !== -1) r.push(i)
        return r
    }
    width: parent ? parent.width : 400

    SettingRow {
        title: row.title
        sub: row.sub
        Rectangle {
            width: 230
            height: 34
            radius: 17
            color: row.open ? Theme.alpha(Theme.accent, 0.25) : pick.containsMouse ? Theme.surfaceHigh : Theme.alpha(Theme.surfaceHigh, 0.7)
            Behavior on color { ColorAnimation { duration: Theme.dur(150) } }
            Txt {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.right: arrow.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: row.cur >= 0 ? row.options[row.cur] : (row.value === undefined || row.value === "" ? row.placeholder : String(row.value))
                elide: Text.ElideRight
                size: 13
                weight: Font.Medium
                color: row.cur < 0 && !row.value ? Theme.subtext : Theme.text
            }
            Icon {
                id: arrow
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "󰅀"
                size: 15
                hoverable: false
                color: Theme.subtext
                rotation: row.open ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: Theme.dur(220) } }
            }
            MouseArea {
                id: pick
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    row.open = !row.open
                    search.text = ""
                    if (row.open && row.searchable) search.focusInput()
                }
            }
        }
    }

    Item {
        width: parent.width
        height: row.open ? box.height + 10 : 0
        clip: true
        Behavior on height { NumberAnimation { duration: Theme.dur(260); easing.type: Easing.OutCubic } }

        Rectangle {
            id: box
            y: 4
            width: parent.width
            height: col.implicitHeight + 16
            radius: 18
            color: Theme.surface

            Column {
                id: col
                x: 8
                y: 8
                width: parent.width - 16
                spacing: 6
                Field {
                    id: search
                    visible: row.searchable
                    width: parent.width
                    placeholder: Lang.t.search
                }
                ListView {
                    id: list
                    width: parent.width
                    height: Math.min(220, row.shown.length * 36)
                    clip: true
                    model: row.shown
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: Rectangle {
                        required property int modelData
                        width: list.width
                        height: 36
                        radius: 12
                        color: modelData === row.cur ? Theme.alpha(Theme.accent, 0.2) : itemArea.containsMouse ? Theme.surfaceHigh : "transparent"
                        Txt {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.options[modelData]
                            elide: Text.ElideRight
                            size: 13
                            color: modelData === row.cur ? Theme.accent : Theme.text
                        }
                        MouseArea {
                            id: itemArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                row.open = false
                                row.picked(row.values[modelData])
                            }
                        }
                    }
                }
            }
        }
    }
}
