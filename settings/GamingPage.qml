import QtQuick
import "../core"
import "../services"
import "../ui"

Column {
    width: parent ? parent.width : 400

    SettingRow {
        title: Lang.t.gameNow
        sub: Gaming.active ? (Gaming.auto ? Lang.t.gameAutoActive : Lang.t.gameOn) : Lang.t.gameOff
        Toggle { checked: Gaming.active; onToggled: Gaming.toggle() }
    }
    SettingRow {
        title: Lang.t.gameAuto
        sub: Lang.t.gameAutoSub
        Toggle { checked: Config.opt.gameAuto; onToggled: v => Config.opt.gameAuto = v }
    }

    Txt {
        text: Lang.t.gameWhat
        size: 13
        weight: Font.DemiBold
        color: Theme.accent
        topPadding: 18
        bottomPadding: 4
    }
    SettingRow {
        title: Lang.t.gameDnd
        sub: Lang.t.gameDndSub
        Toggle { checked: Config.opt.gameDnd; onToggled: v => Config.opt.gameDnd = v }
    }
    SettingRow {
        title: Lang.t.gameHideIsland
        sub: Lang.t.gameHideIslandSub
        Toggle { checked: Config.opt.gameHideIsland; onToggled: v => Config.opt.gameHideIsland = v }
    }
    SettingRow {
        title: Lang.t.gamePerformance
        sub: Lang.t.gamePerformanceSub
        Toggle { checked: Config.opt.gamePerformance; onToggled: v => Config.opt.gamePerformance = v }
    }
    SettingRow {
        title: Lang.t.gameNoAnim
        sub: Lang.t.gameNoAnimSub
        Toggle { checked: Config.opt.gameNoAnim; onToggled: v => Config.opt.gameNoAnim = v }
    }
    SettingRow {
        title: Lang.t.gameMuteSounds
        sub: Lang.t.gameMuteSoundsSub
        Toggle { checked: Config.opt.gameMuteSounds; onToggled: v => Config.opt.gameMuteSounds = v }
    }
}
