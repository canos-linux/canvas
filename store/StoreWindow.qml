import QtQuick
import Quickshell
import Quickshell.Widgets
import "../core"
import "../services"
import "../ui"
import "../settings"

LazyLoader {
    active: Store.open

    FloatingWindow {
        id: win
        title: "Canvas Store"
        implicitWidth: 980
        implicitHeight: 660
        color: Theme.base
        onVisibleChanged: if (!visible) Store.open = false

        property string cat: "featured"
        property string query: ""
        readonly property var catNames: ({ featured: Lang.t.storeFeatured, games: Lang.t.storeGames, internet: Lang.t.storeInternet, media: Lang.t.storeMedia, creative: Lang.t.storeCreative, office: Lang.t.storeOffice, tools: Lang.t.storeTools, installed: Lang.t.storeInstalled })
        readonly property var catIcons: ({ featured: "󰓎", games: "󰊴", internet: "󰖟", media: "󰎆", creative: "󰏘", office: "󰈙", tools: "󰒓", installed: "󰄬" })
        readonly property var apps: query.length >= 2 ? Store.catalog.filter(a => (a.name + " " + Store.desc(a)).toLowerCase().indexOf(query.toLowerCase()) !== -1).concat(Store.results.filter(r => !Store.catalog.some(a => a.pkg === r.pkg && r.pkg || a.flatpak === r.flatpak && r.flatpak)))
            : cat === "featured" ? Store.catalog.filter(a => a.featured)
            : cat === "installed" ? Store.catalog.filter(a => Store.isInstalled(a))
            : Store.catalog.filter(a => a.cat === cat)

        Timer {
            id: searchDelay
            interval: 400
            onTriggered: Store.search(win.query)
        }

        Rectangle {
            id: side
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 220
            color: Theme.surface

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 2
                Row {
                    spacing: 10
                    bottomPadding: 16
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 12
                        color: Theme.accent
                        Icon { anchors.centerIn: parent; text: "󰏓"; size: 20; color: Theme.base; hoverable: false }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Txt { text: "Store"; size: 17; weight: Font.Bold }
                        Txt { text: "Canvas"; size: 12; color: Theme.subtext }
                    }
                }
                Repeater {
                    model: Store.cats.concat(["installed"])
                    Rectangle {
                        width: parent.width
                        height: 40
                        radius: 14
                        readonly property bool on: win.cat === modelData && win.query === ""
                        color: on ? Theme.alpha(Theme.accent, 0.2) : catHov.hovered ? Theme.surfaceHigh : "transparent"
                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12
                            Icon { anchors.verticalCenter: parent.verticalCenter; text: win.catIcons[modelData]; size: 18; hoverable: false; color: parent.parent.on ? Theme.accent : Theme.text }
                            Txt { anchors.verticalCenter: parent.verticalCenter; text: win.catNames[modelData]; weight: parent.parent.on ? Font.DemiBold : Font.Normal }
                        }
                        HoverHandler { id: catHov }
                        TapHandler {
                            onTapped: {
                                Sounds.play("click")
                                win.cat = modelData
                                search.text = ""
                            }
                        }
                    }
                }
            }
        }

        Item {
            anchors.left: side.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 26

            Field {
                id: search
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                placeholder: Lang.t.storeSearch
                onTextChanged: {
                    win.query = text.trim()
                    searchDelay.restart()
                }
            }

            Txt {
                id: heading
                anchors.top: search.bottom
                anchors.topMargin: 20
                text: win.query.length >= 2 ? (Store.searching ? Lang.t.storeSearching : Lang.t.storeResults) : win.catNames[win.cat]
                size: 24
                weight: Font.Bold
            }

            Txt {
                anchors.top: heading.bottom
                anchors.topMargin: 4
                width: parent.width
                visible: Store.error !== ""
                text: Store.error
                size: 12
                color: "#ff7a7a"
                elide: Text.ElideRight
            }

            Flickable {
                anchors.top: heading.bottom
                anchors.topMargin: 26
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                contentHeight: grid.height
                clip: true

                Grid {
                    id: grid
                    width: parent.width
                    columns: 2
                    spacing: 12
                    Repeater {
                        model: win.apps
                        Rectangle {
                            id: appCard
                            required property var modelData
                            readonly property bool inst: Store.isInstalled(modelData)
                            readonly property bool working: Store.busy === Store.key(modelData)
                            readonly property bool queued: Store.queue.some(q => Store.key(q.app) === Store.key(modelData))
                            readonly property string iconPath: Quickshell.iconPath(modelData.icon || "", true)
                            width: (grid.width - 12) / 2
                            height: 86
                            radius: 20
                            color: Theme.surface

                            Rectangle {
                                id: ic
                                anchors.left: parent.left
                                anchors.leftMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                width: 48
                                height: 48
                                radius: 14
                                color: appCard.iconPath !== "" ? "transparent" : Theme.alpha(Theme.accent, 0.2)
                                IconImage {
                                    anchors.fill: parent
                                    visible: appCard.iconPath !== ""
                                    source: appCard.iconPath
                                }
                                Txt {
                                    anchors.centerIn: parent
                                    visible: appCard.iconPath === ""
                                    text: appCard.modelData.name.charAt(0).toUpperCase()
                                    size: 22
                                    weight: Font.Bold
                                    color: Theme.accent
                                }
                            }
                            Column {
                                anchors.left: ic.right
                                anchors.leftMargin: 14
                                anchors.right: btns.left
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Txt { width: parent.width; text: appCard.modelData.name; size: 15; weight: Font.DemiBold; elide: Text.ElideRight }
                                Txt { width: parent.width; text: Store.desc(appCard.modelData); size: 12; color: Theme.subtext; elide: Text.ElideRight }
                                Txt { text: appCard.modelData.flatpak ? "Flathub" : (appCard.modelData.repo || "CanOS / Arch"); size: 10; color: Theme.alpha(Theme.subtext, 0.7) }
                            }
                            Row {
                                id: btns
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6
                                Spinner { visible: appCard.working; anchors.verticalCenter: parent.verticalCenter }
                                Icon {
                                    visible: appCard.inst && !appCard.working
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰆴"
                                    size: 17
                                    color: Theme.subtext
                                    onClicked: Store.remove(appCard.modelData)
                                }
                                PillButton {
                                    visible: !appCard.working
                                    width: 96
                                    text: appCard.queued ? Lang.t.storeQueued : appCard.inst ? Lang.t.storeOpen : Lang.t.storeGet
                                    primary: !appCard.inst
                                    onClicked: appCard.inst ? Store.launch(appCard.modelData) : Store.install(appCard.modelData)
                                }
                            }
                        }
                    }
                }
            }

            Txt {
                anchors.centerIn: parent
                visible: win.apps.length === 0 && !Store.searching
                text: win.query.length >= 2 ? Lang.t.storeNothing : Lang.t.storeEmpty
                color: Theme.subtext
            }
        }
    }
}
