class_name TeamColors
extends RefCounted

const COLORS: Array[Color] = [Color.ROYAL_BLUE, Color.DARK_ORANGE]
const NO_TEAM_COLOR := Color.GRAY

static func of(team: int) -> Color:
    if team < 0 or team >= COLORS.size():
        return NO_TEAM_COLOR
    return COLORS[team]
