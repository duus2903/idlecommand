extends Control

signal flow_finished(success: bool)

enum FlowState { IDLE, RECEIVED, CODING, TESTING, PASSED, FAILED, DELIVERED }

@onready var status_label: Label = %StatusLabel
@onready var detail_label: Label = %DetailLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var start_button: Button = %StartButton
@onready var retry_button: Button = %RetryButton
@onready var knowledge_label: Label = %KnowledgeLabel
@onready var energy_label: Label = %EnergyLabel
@onready var trust_label: Label = %TrustLabel

var current_state := FlowState.IDLE
var knowledge := 0
var energy := 0
var trust := 0
var rng := RandomNumberGenerator.new()
var stage_progress := 0.0
var animation_time := 0.0

const BG := Color("#101917")
const WALL := Color("#20332c")
const WOOD := Color("#8c5a2c")
const WOOD_DARK := Color("#4c311f")
const GOLD := Color("#f0b64f")
const GREEN := Color("#67d58b")
const BLUE := Color("#56a9e8")
const PURPLE := Color("#a06be8")
const RED := Color("#e46258")
const CREAM := Color("#f3e4c3")

func _ready() -> void:
    rng.randomize()
    start_button.pressed.connect(_start_flow)
    retry_button.pressed.connect(_start_flow)
    resized.connect(queue_redraw)
    _style_ui()
    _set_idle()
    set_process(true)

func _process(delta: float) -> void:
    animation_time += delta
    queue_redraw()

func _style_ui() -> void:
    var panel := StyleBoxFlat.new()
    panel.bg_color = Color("#182520")
    panel.border_color = Color("#456454")
    panel.set_border_width_all(2)
    panel.set_corner_radius_all(18)
    %StatusCard.add_theme_stylebox_override("panel", panel)

    var button := StyleBoxFlat.new()
    button.bg_color = Color("#315f43")
    button.border_color = GREEN
    button.set_border_width_all(2)
    button.set_corner_radius_all(12)
    start_button.add_theme_stylebox_override("normal", button)
    retry_button.add_theme_stylebox_override("normal", button)

func _start_flow() -> void:
    start_button.disabled = true
    retry_button.visible = false
    await _run_stage(FlowState.RECEIVED, "Ny opgave er landet", "Carsten gennemgår briefet og sender pakken til Kode-Kaj.", 1.5)
    await _run_stage(FlowState.CODING, "Kode-Kaj bygger", "Skærmene lyser, kaffe bliver drukket, og koden tager form.", 3.4)
    await _run_stage(FlowState.TESTING, "Test-Tove undersøger", "Pakken køres gennem testkammeret og kvalitetstjekkes.", 2.8)

    var success := rng.randf() > 0.24
    if success:
        await _run_stage(FlowState.PASSED, "Alle tests bestået", "Test-Tove har sat det grønne kvalitetsstempel på pakken.", 1.3)
        await _run_stage(FlowState.DELIVERED, "Leveret!", "Delivery hatch åbner, og Carsten fejrer dagens leverance.", 2.0)
        knowledge += 25
        energy += 10
        trust += 15
        flow_finished.emit(true)
    else:
        await _run_stage(FlowState.FAILED, "En bug slap løs", "Test-Tove fandt en fejl. Kaj er allerede klar til et nyt forsøg.", 2.0)
        energy += 5
        trust += 2
        retry_button.visible = true
        flow_finished.emit(false)

    _update_resources()
    start_button.disabled = false

func _run_stage(state: FlowState, title: String, detail: String, duration: float) -> void:
    current_state = state
    status_label.text = title
    detail_label.text = detail
    stage_progress = 0.0
    progress_bar.value = 0

    var elapsed := 0.0
    while elapsed < duration:
        await get_tree().process_frame
        elapsed += get_process_delta_time()
        stage_progress = clamp(elapsed / duration, 0.0, 1.0)
        progress_bar.value = stage_progress * 100.0

func _set_idle() -> void:
    current_state = FlowState.IDLE
    status_label.text = "Værkstedet er klar"
    detail_label.text = "Tryk Start opgave og se Carsten, Kode-Kaj og Test-Tove gennemføre en leverance."
    progress_bar.value = 0
    retry_button.visible = false
    _update_resources()

func _update_resources() -> void:
    knowledge_label.text = "📘 Viden  %d" % knowledge
    energy_label.text = "⚡ Energi  %d" % energy
    trust_label.text = "❤️ Tillid  %d" % trust

func _draw() -> void:
    var view := size
    draw_rect(Rect2(Vector2.ZERO, view), BG)
    var sx := view.x / 1280.0
    var sy := view.y / 720.0
    var s := min(sx, sy)
    var offset := Vector2((view.x - 1280.0 * s) * 0.5, 0)

    draw_set_transform(offset, 0.0, Vector2(s, s))
    _draw_room()
    _draw_station(Vector2(175, 355), "TASK INBOX", GREEN, current_state == FlowState.RECEIVED)
    _draw_station(Vector2(430, 355), "CODE STATION", BLUE, current_state == FlowState.CODING)
    _draw_station(Vector2(850, 355), "TEST LAB", PURPLE, current_state in [FlowState.TESTING, FlowState.PASSED, FlowState.FAILED])
    _draw_station(Vector2(1100, 355), "DELIVERY", GOLD, current_state == FlowState.DELIVERED)

    var carsten_bob := sin(animation_time * 2.0) * 3.0
    var kaj_bob := sin(animation_time * 4.0) * (4.0 if current_state == FlowState.CODING else 2.0)
    var tove_bob := sin(animation_time * 3.3) * (4.0 if current_state == FlowState.TESTING else 2.0)
    _draw_agent(Vector2(640, 338 + carsten_bob), "C", Color("#2f6b4a"), "CARSTEN")
    _draw_agent(Vector2(430, 432 + kaj_bob), "K", Color("#2f6594"), "KODE-KAJ")
    _draw_agent(Vector2(850, 432 + tove_bob), "T", Color("#714aa0"), "TEST-TOVE")

    _draw_package()
    _draw_ambient_lights()
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_room() -> void:
    draw_rect(Rect2(55, 78, 1170, 500), WALL)
    draw_rect(Rect2(55, 500, 1170, 78), WOOD_DARK)
    for x in range(55, 1225, 58):
        draw_line(Vector2(x, 500), Vector2(x - 24, 578), Color("#654329"), 2)
    for y in range(520, 579, 28):
        draw_line(Vector2(55, y), Vector2(1225, y), Color("#654329"), 2)

    draw_rect(Rect2(495, 102, 290, 120), Color("#13221e"))
    draw_rect(Rect2(502, 109, 276, 106), Color("#1b3530"), false, 3)
    _text(Vector2(548, 137), "MISSION CONTROL", 22, GOLD)
    _text(Vector2(530, 174), "TASK  →  CODE  →  TEST  →  SHIP", 17, CREAM)

    draw_rect(Rect2(505, 272, 270, 155), WOOD)
    draw_rect(Rect2(520, 287, 240, 125), WOOD_DARK)
    draw_circle(Vector2(640, 350), 54, Color("#315443"))
    draw_arc(Vector2(640, 350), 58, 0, TAU, 32, GOLD, 3)

    for p in [Vector2(95, 105), Vector2(1170, 105), Vector2(315, 102), Vector2(950, 102)]:
        draw_line(p, p + Vector2(0, 32), GOLD, 2)
        draw_circle(p + Vector2(0, 38), 8, Color("#ffd879"))

    _draw_plant(Vector2(95, 465))
    _draw_plant(Vector2(1180, 465))
    _draw_plant(Vector2(780, 460))

func _draw_station(center: Vector2, title: String, accent: Color, active: bool) -> void:
    var rect := Rect2(center - Vector2(92, 78), Vector2(184, 156))
    draw_rect(rect, Color("#17231f"))
    draw_rect(rect, accent if active else Color("#456054"), false, 4 if active else 2)
    draw_rect(Rect2(rect.position + Vector2(12, 18), Vector2(160, 74)), Color("#0e1715"))
    for i in range(3):
        draw_line(rect.position + Vector2(26, 38 + i * 16), rect.position + Vector2(155, 38 + i * 16), accent, 2)
    draw_rect(Rect2(rect.position + Vector2(25, 102), Vector2(134, 34)), WOOD)
    _text(center + Vector2(-70, -98), title, 16, accent)
    if active:
        draw_circle(center + Vector2(72, -62), 8 + sin(animation_time * 6.0) * 2, accent)

func _draw_agent(pos: Vector2, initial: String, shirt: Color, name: String) -> void:
    draw_ellipse(pos + Vector2(0, 24), Vector2(26, 34), shirt)
    draw_circle(pos, 25, Color("#efb183"))
    draw_circle(pos + Vector2(-9, -3), 5, Color.WHITE)
    draw_circle(pos + Vector2(9, -3), 5, Color.WHITE)
    draw_circle(pos + Vector2(-9, -3), 2, Color("#20302b"))
    draw_circle(pos + Vector2(9, -3), 2, Color("#20302b"))
    draw_arc(pos + Vector2(0, 5), 10, 0.2, PI - 0.2, 12, Color("#6b3429"), 2)
    draw_arc(pos, 27, PI, TAU, 18, Color("#3a251c"), 10)
    _text(pos + Vector2(-6, 30), initial, 16, CREAM)
    _text(pos + Vector2(-42, 72), name, 13, CREAM)

func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i in range(32):
        var a := TAU * float(i) / 32.0
        points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
    draw_colored_polygon(points, color)

func _draw_package() -> void:
    if current_state == FlowState.IDLE:
        return
    var points := [Vector2(175, 430), Vector2(430, 430), Vector2(850, 430), Vector2(1100, 430)]
    var from := points[0]
    var to := points[0]
    match current_state:
        FlowState.RECEIVED:
            from = Vector2(90, 430); to = points[0]
        FlowState.CODING:
            from = points[0]; to = points[1]
        FlowState.TESTING, FlowState.PASSED, FlowState.FAILED:
            from = points[1]; to = points[2]
        FlowState.DELIVERED:
            from = points[2]; to = points[3]
    var p := from.lerp(to, stage_progress)
    var package_color := RED if current_state == FlowState.FAILED else (GREEN if current_state in [FlowState.PASSED, FlowState.DELIVERED] else GOLD)
    draw_rect(Rect2(p - Vector2(24, 18), Vector2(48, 36)), Color("#b77b3e"))
    draw_rect(Rect2(p - Vector2(24, 18), Vector2(48, 36)), package_color, false, 4)
    draw_line(p + Vector2(0, -18), p + Vector2(0, 18), package_color, 3)

func _draw_ambient_lights() -> void:
    for i in range(12):
        var x := 80.0 + float(i) * 98.0
        var pulse := 2.0 + sin(animation_time * 1.8 + i) * 1.2
        draw_circle(Vector2(x, 88), pulse, Color("#ffd879"))

func _draw_plant(pos: Vector2) -> void:
    draw_rect(Rect2(pos - Vector2(14, 0), Vector2(28, 30)), Color("#7b4b28"))
    for d in [Vector2(-16, -18), Vector2(0, -28), Vector2(16, -18), Vector2(-8, -38), Vector2(8, -38)]:
        draw_ellipse(pos + d, Vector2(9, 18), Color("#4d8b52"))

func _text(pos: Vector2, text: String, font_size: int, color: Color) -> void:
    draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
