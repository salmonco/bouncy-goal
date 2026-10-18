class_name HudView
extends CanvasLayer

# 화면 위에 겹쳐 그리는 정보(HUD)입니다. 눈 행성(라비네) 톤에 맞춰 둥근 글꼴(주아체)과 반투명 흰 알약 패널을 씁니다.
#   - 위 가운데: 한 줄짜리 점수 막대. 내 점수와 상대 점수를 각 팀 색으로 쓰고, 그 사이에 남은 시간을 둡니다.
#     마지막 몇 초는 시간이 빨갛게 두근거립니다. 두 줄로 쌓으면 높이 뜬 공을 가리기 쉬워 한 줄로 둡니다.
#   - 가운데: "GOAL!", "WIN" 같은 큰 글자와 그 아래 안내(알약 패널).
#   - 골이 들어가면 화면 전체가 서리 빛으로 번쩍이고, 큰 글자가 튀어나왔다가 제자리로 돌아옵니다.
# 무엇을 보여줄지는 main 이 정하고, 이 클래스는 어떻게 보여줄지만 맡습니다.

const FONT := preload("res://assets/fonts/Jua-Regular.ttf")

const TEXT_COLOR := Color(0.27, 0.32, 0.50)
const PANEL_COLOR := Color(1.0, 1.0, 1.0, 0.78)
const PANEL_BORDER_COLOR := Color(0.72, 0.84, 1.0)
const PANEL_SHADOW_COLOR := Color(0.25, 0.35, 0.65, 0.25)
const TITLE_OUTLINE_COLOR := Color(0.36, 0.56, 0.95)
const TITLE_SHADOW_COLOR := Color(0.20, 0.30, 0.60, 0.35)

const SCORE_FONT_SIZE := 46
const NAME_FONT_SIZE := 24
const TIME_FONT_SIZE := 26
const TITLE_FONT_SIZE := 120
const SUBTITLE_FONT_SIZE := 28

# 남은 시간이 이 초 이하면 시간이 빨갛게 바뀌고 초마다 두근거립니다.
const HURRY_SECONDS := 10
const HURRY_COLOR := Color(0.92, 0.36, 0.42)

const FROST_FLASH_COLOR := Color(0.88, 0.95, 1.0)
const FROST_FLASH_ALPHA := 0.75
const FROST_FLASH_DURATION := 0.7
const TITLE_POP_SCALE := 1.8
const TITLE_POP_DURATION := 0.45

var _frost_flash: ColorRect
var _scoreboard: PanelContainer
var _my_name: Label
var _my_score: Label
var _opponent_name: Label
var _opponent_score: Label
var _time: Label
var _shown_seconds := -1
var _title: Label
var _subtitle: Label
var _subtitle_panel: PanelContainer

func _ready() -> void:
    # 번쩍임이 글자를 덮지 않도록 가장 먼저(맨 뒤에) 둡니다.
    _frost_flash = ColorRect.new()
    _frost_flash.color = Color(FROST_FLASH_COLOR, 0.0)
    _frost_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
    _frost_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_frost_flash)
    _build_scoreboard()
    _build_message()

func update_score(my_team: int, my_score: int, opponent_team: int, opponent_score: int) -> void:
    # 1인칭이라 내 몸이 안 보이니, 점수를 각 팀 색으로 칠해 어느 편인지 알려줍니다.
    _my_name.add_theme_color_override("font_color", TeamColors.of(my_team))
    _my_score.add_theme_color_override("font_color", TeamColors.of(my_team))
    _opponent_name.add_theme_color_override("font_color", TeamColors.of(opponent_team))
    _opponent_score.add_theme_color_override("font_color", TeamColors.of(opponent_team))
    _my_score.text = str(my_score)
    _opponent_score.text = str(opponent_score)

func update_time(seconds: float) -> void:
    # 종료 직전 마지막 tick 에서 살짝 음수가 될 수 있어 0 에서 멈춥니다.
    var total := ceili(maxf(seconds, 0.0))
    if total == _shown_seconds:
        return
    _shown_seconds = total
    @warning_ignore("integer_division")
    _time.text = "%02d:%02d" % [total / 60, total % 60]
    var hurry := total <= HURRY_SECONDS and total > 0
    _time.add_theme_color_override("font_color", HURRY_COLOR if hurry else TEXT_COLOR)
    if hurry:
        _pop(_time, 1.35, 0.3)

# title 이 비어 있으면 가운데 글자를 숨깁니다. subtitle 이 비어 있으면 아래 안내 패널을 숨깁니다.
func show_message(title: String, subtitle := "") -> void:
    _title.text = title
    _title.visible = title != ""
    _subtitle.text = subtitle
    _subtitle_panel.visible = subtitle != ""

# 경기 전(대기 중)에는 점수 막대를 숨깁니다.
func show_scoreboard(shown: bool) -> void:
    _scoreboard.visible = shown

func celebrate_goal() -> void:
    _frost_flash.color.a = FROST_FLASH_ALPHA
    create_tween().tween_property(_frost_flash, "color:a", 0.0, FROST_FLASH_DURATION).set_ease(Tween.EASE_OUT)
    _pop(_title, TITLE_POP_SCALE, TITLE_POP_DURATION)

# 크게 튀어나왔다가 살짝 넘치며 제자리로 돌아옵니다.
func _pop(control: Control, from_scale: float, duration: float) -> void:
    control.pivot_offset = control.size / 2
    control.scale = Vector2.ONE * from_scale
    create_tween().tween_property(control, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _build_scoreboard() -> void:
    var row := HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_theme_constant_override("separation", 12)
    _my_name = _label("나", NAME_FONT_SIZE)
    _my_score = _label("0", SCORE_FONT_SIZE)
    _time = _label("00:00", TIME_FONT_SIZE)
    # 시간 양옆을 조금 띄워 두 점수와 구분합니다.
    _time.custom_minimum_size.x = TIME_FONT_SIZE * 4
    _opponent_score = _label("0", SCORE_FONT_SIZE)
    _opponent_name = _label("상대", NAME_FONT_SIZE)
    for child in [_my_name, _my_score, _time, _opponent_score, _opponent_name]:
        row.add_child(child)
    var bar := _panel(row, 24, Vector2(24, 0))
    bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
    bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
    bar.position.y = 14
    add_child(bar)
    _scoreboard = bar

func _build_message() -> void:
    var center := VBoxContainer.new()
    center.set_anchors_preset(Control.PRESET_CENTER)
    center.grow_horizontal = Control.GROW_DIRECTION_BOTH
    center.grow_vertical = Control.GROW_DIRECTION_BOTH
    center.alignment = BoxContainer.ALIGNMENT_CENTER
    center.add_theme_constant_override("separation", 12)
    center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(center)

    _title = Label.new()
    _title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var title_style := LabelSettings.new()
    title_style.font = FONT
    title_style.font_size = TITLE_FONT_SIZE
    title_style.font_color = Color.WHITE
    title_style.outline_size = 22
    title_style.outline_color = TITLE_OUTLINE_COLOR
    title_style.shadow_size = 0
    title_style.shadow_color = TITLE_SHADOW_COLOR
    title_style.shadow_offset = Vector2(0, 8)
    _title.label_settings = title_style
    center.add_child(_title)

    _subtitle = _label("", SUBTITLE_FONT_SIZE)
    _subtitle_panel = _panel(_subtitle, 20, Vector2(20, 4))
    _subtitle_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    center.add_child(_subtitle_panel)
    show_message("")

func _label(text: String, font_size: int) -> Label:
    var label := Label.new()
    label.text = text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_override("font", FONT)
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", TEXT_COLOR)
    return label

# 반투명 흰 알약 모양 패널에 얼음빛 테두리와 은은한 그림자를 둡니다. margin 은 안쪽 여백(가로, 세로)입니다.
func _panel(content: Control, radius: int, margin: Vector2) -> PanelContainer:
    var style := StyleBoxFlat.new()
    style.bg_color = PANEL_COLOR
    style.set_corner_radius_all(radius)
    style.set_border_width_all(3)
    style.border_color = PANEL_BORDER_COLOR
    style.shadow_color = PANEL_SHADOW_COLOR
    style.shadow_size = 8
    style.shadow_offset = Vector2(0, 3)
    style.content_margin_left = margin.x
    style.content_margin_right = margin.x
    style.content_margin_top = margin.y
    style.content_margin_bottom = margin.y
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", style)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_child(content)
    return panel
