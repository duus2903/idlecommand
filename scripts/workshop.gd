extends Control

signal flow_finished(success: bool)

enum FlowState { IDLE, RECEIVED, CODING, TESTING, PASSED, FAILED, DELIVERED }

@onready var status_label: Label = %StatusLabel
@onready var detail_label: Label = %DetailLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var start_button: Button = %StartButton
@onready var retry_button: Button = %RetryButton
@onready var task_card: PanelContainer = %TaskCard
@onready var code_station: PanelContainer = %CodeStation
@onready var test_station: PanelContainer = %TestStation
@onready var delivery_station: PanelContainer = %DeliveryStation
@onready var carsten: Label = %Carsten
@onready var kaj: Label = %Kaj
@onready var tove: Label = %Tove
@onready var knowledge_label: Label = %KnowledgeLabel
@onready var energy_label: Label = %EnergyLabel
@onready var trust_label: Label = %TrustLabel

var current_state := FlowState.IDLE
var knowledge := 0
var energy := 0
var trust := 0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.randomize()
    start_button.pressed.connect(_start_flow)
    retry_button.pressed.connect(_start_flow)
    _set_idle()

func _start_flow() -> void:
    start_button.disabled = true
    retry_button.visible = false
    await _run_stage(FlowState.RECEIVED, "Ny opgave ankommet", "Carsten læser opgaven og sender den videre.", task_card, 1.2)
    await _run_stage(FlowState.CODING, "Kode-Kaj arbejder", "Implementerer login-flow og gør pakken klar til test.", code_station, 3.0)
    await _run_stage(FlowState.TESTING, "Test-Tove tester", "Kører unit tests, integration og kvalitetstjek.", test_station, 2.6)

    var success := rng.randf() > 0.28
    if success:
        await _run_stage(FlowState.PASSED, "Alle tests bestået", "Pakken er godkendt og klar til levering.", test_station, 1.2)
        await _run_stage(FlowState.DELIVERED, "Leveret!", "Carsten fejrer. Du optjente Viden, Energi og Tillid.", delivery_station, 1.8)
        knowledge += 25
        energy += 10
        trust += 15
        carsten.text = "🧑‍💼  CARSTEN  🎉"
        flow_finished.emit(true)
    else:
        await _run_stage(FlowState.FAILED, "En bug slap igennem", "Test-Tove fandt en fejl. Kode-Kaj gør klar til et nyt forsøg.", test_station, 1.8)
        energy += 5
        trust += 2
        retry_button.visible = true
        carsten.text = "🧑‍💼  CARSTEN  🤔"
        flow_finished.emit(false)

    _update_resources()
    start_button.disabled = false

func _run_stage(state: FlowState, title: String, detail: String, station: Control, duration: float) -> void:
    current_state = state
    status_label.text = title
    detail_label.text = detail
    progress_bar.value = 0
    _reset_station_styles()
    _highlight(station)
    _update_characters(state)

    var elapsed := 0.0
    while elapsed < duration:
        await get_tree().process_frame
        elapsed += get_process_delta_time()
        progress_bar.value = clamp((elapsed / duration) * 100.0, 0.0, 100.0)

func _set_idle() -> void:
    current_state = FlowState.IDLE
    status_label.text = "Værkstedet er klar"
    detail_label.text = "Tryk Start opgave for at køre den første simulerede GitHub-leverance."
    progress_bar.value = 0
    retry_button.visible = false
    carsten.text = "🧑‍💼  CARSTEN"
    kaj.text = "🧑‍💻  KODE-KAJ"
    tove.text = "🧑‍🔬  TEST-TOVE"
    _reset_station_styles()
    _update_resources()

func _update_characters(state: FlowState) -> void:
    carsten.text = "🧑‍💼  CARSTEN"
    kaj.text = "🧑‍💻  KODE-KAJ"
    tove.text = "🧑‍🔬  TEST-TOVE"
    match state:
        FlowState.RECEIVED:
            carsten.text += "  📋"
        FlowState.CODING:
            kaj.text += "  ⌨️"
        FlowState.TESTING:
            tove.text += "  🔍"
        FlowState.PASSED:
            tove.text += "  ✅"
        FlowState.FAILED:
            kaj.text += "  🐛"
            tove.text += "  ❌"
        FlowState.DELIVERED:
            carsten.text += "  🚀"

func _highlight(control: Control) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#244d3b")
    style.border_color = Color("#73d58b")
    style.set_border_width_all(3)
    style.set_corner_radius_all(18)
    control.add_theme_stylebox_override("panel", style)

func _reset_station_styles() -> void:
    for station in [task_card, code_station, test_station, delivery_station]:
        station.remove_theme_stylebox_override("panel")

func _update_resources() -> void:
    knowledge_label.text = "📘 Viden  %d" % knowledge
    energy_label.text = "⚡ Energi  %d" % energy
    trust_label.text = "❤️ Tillid  %d" % trust
