extends Node2D

const SAVE_PATH := "user://idlecommand_save.cfg"
const WORLD_WIDTH := 1280.0
const GROUND_Y := 334.0
const DAY_SECONDS := 180.0
const FIRE_POS := Vector2(650, 329)
const TENT_POS := Vector2(1000, 326)
const WOOD_STORE_POS := Vector2(908, 337)
const BRANCH_POSITIONS := [Vector2(250, 334), Vector2(1120, 334)]
const CAMP_BACKGROUND := preload("res://assets/neolithic_sunset.png")
const CAMP_NIGHT := preload("res://assets/neolithic_night.png")
const NORA_SPRITES := {
    "idle": preload("res://assets/sprites/neolithic/nora_idle.png"),
    "sit": preload("res://assets/sprites/neolithic/nora_sit.png"),
    "warm": preload("res://assets/sprites/neolithic/nora_warm.png"),
    "sleep": preload("res://assets/sprites/neolithic/nora_sleep.png"),
    "eat": preload("res://assets/sprites/neolithic/nora_eat.png"),
    "strike": preload("res://assets/sprites/neolithic/nora_strike.png"),
    "blow": preload("res://assets/sprites/neolithic/nora_blow.png")
}
const OTTO_SPRITES := {
    "idle": preload("res://assets/sprites/neolithic/otto_idle.png"),
    "sit": preload("res://assets/sprites/neolithic/otto_sit.png"),
    "tend": preload("res://assets/sprites/neolithic/otto_warm.png"),
    "sleep": preload("res://assets/sprites/neolithic/otto_sleep.png"),
    "eat": preload("res://assets/sprites/neolithic/otto_eat.png"),
    "strike": preload("res://assets/sprites/neolithic/otto_strike.png"),
    "blow": preload("res://assets/sprites/neolithic/otto_blow.png")
}
const MILO_SPRITES := {
    "idle": preload("res://assets/sprites/neolithic/milo_idle.png"),
    "sit": preload("res://assets/sprites/neolithic/milo_sit.png"),
    "rest": preload("res://assets/sprites/neolithic/milo_rest.png"),
    "sleep": preload("res://assets/sprites/neolithic/milo_rest.png"),
    "sniff": preload("res://assets/sprites/neolithic/milo_sniff.png"),
    "wag": preload("res://assets/sprites/neolithic/milo_wag.png")
}
const NORA_WALK_FRAMES := [
    preload("res://assets/sprites/neolithic/nora_walk_0.png"),
    preload("res://assets/sprites/neolithic/nora_walk_1.png"),
    preload("res://assets/sprites/neolithic/nora_walk_2.png"),
    preload("res://assets/sprites/neolithic/nora_walk_1.png")
]
const OTTO_WALK_FRAMES := [
    preload("res://assets/sprites/neolithic/otto_walk_0.png"),
    preload("res://assets/sprites/neolithic/otto_walk_1.png"),
    preload("res://assets/sprites/neolithic/otto_walk_2.png"),
    preload("res://assets/sprites/neolithic/otto_walk_1.png")
]
const MILO_WALK_FRAMES := [
    preload("res://assets/sprites/neolithic/milo_walk_0.png"),
    preload("res://assets/sprites/neolithic/milo_walk_1.png"),
    preload("res://assets/sprites/neolithic/milo_walk_2.png"),
    preload("res://assets/sprites/neolithic/milo_walk_1.png")
]
const FIRE_BASE := preload("res://assets/sprites/fire_base.png")
const FLAME_FRAMES := [
    preload("res://assets/sprites/flame_0.png"),
    preload("res://assets/sprites/flame_1.png"),
    preload("res://assets/sprites/flame_2.png"),
    preload("res://assets/sprites/flame_3.png")
]
const NORA_GATHER_FRAMES := [
    preload("res://assets/sprites/neolithic/nora_gather.png"),
    preload("res://assets/sprites/neolithic/nora_gather.png"),
    preload("res://assets/sprites/neolithic/nora_gather.png")
]
const OTTO_GATHER_FRAMES := [
    preload("res://assets/sprites/neolithic/otto_gather.png"),
    preload("res://assets/sprites/neolithic/otto_gather.png"),
    preload("res://assets/sprites/neolithic/otto_gather.png")
]
const BRANCH_SOURCE_FRAMES := [
    preload("res://assets/sprites/neolithic/tinder_patch.png"),
    preload("res://assets/sprites/neolithic/tinder_patch.png"),
    preload("res://assets/sprites/neolithic/tinder_patch.png")
]
const BRANCH_BUNDLE := preload("res://assets/sprites/neolithic/tinder_bundle.png")
const SHELTER_TEXTURES := [
    preload("res://assets/sprites/neolithic/shelter_frame.png"),
    preload("res://assets/sprites/neolithic/shelter_woven.png"),
    preload("res://assets/sprites/neolithic/shelter_complete.png")
]
const SHELTER_WET := preload("res://assets/sprites/neolithic/shelter_wet.png")
const FLINT_PYRITE := preload("res://assets/sprites/neolithic/flint_pyrite.png")
const TINDER_EMBER := preload("res://assets/sprites/neolithic/tinder_ember.png")
const FIRE_COLD := preload("res://assets/sprites/neolithic/fire_cold.png")
const FIRE_EMBERS := preload("res://assets/sprites/neolithic/fire_embers.png")
const FIRE_TINY := preload("res://assets/sprites/neolithic/fire_tiny.png")
const STONE_AXE := preload("res://assets/sprites/neolithic/stone_axe.png")
const BASKET := preload("res://assets/sprites/neolithic/basket.png")
const CLAY_POT := preload("res://assets/sprites/neolithic/clay_pot.png")
const DRYING_RACK := preload("res://assets/sprites/neolithic/drying_rack.png")

var world_time := 0.92
var day_number := 1
var raining := false
var weather_timer := 32.0
var fire_fuel := 5.0
var fire_heat := 0.82
var fire_wetness := 0.0
var stored_branches := 1
var branch_sources: Array[Dictionary] = []
var shelters: Array[Dictionary] = []
var action_counts: Dictionary = {}
var recent_action := ""
var story_line := "Lejren vågner stille."
var story_timer := 0.0
var agents: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var visual_time := 0.0
var capture_requested := false
var capture_finished := false
var nora_otto_bond := 0.18
var milo_attachment := [0.38, 0.32]
var event_history: Array[String] = []
var remembered_moments: Dictionary = {}

func _ready() -> void:
    rng.randomize()
    var user_args := OS.get_cmdline_user_args()
    capture_requested = user_args.has("capture") or user_args.has("gather_capture") or user_args.has("rain_capture") or user_args.has("kindle_capture") or user_args.has("pose_capture")
    agents = [
        _make_agent("Nora", Vector2(520, GROUND_Y), Color("#d17a74"), false),
        _make_agent("Otto", Vector2(760, GROUND_Y), Color("#7fa6c9"), false),
        _make_agent("Milo", Vector2(700, GROUND_Y + 7), Color("#b99062"), true)
    ]
    branch_sources = [
        {"pos": BRANCH_POSITIONS[0], "amount": 3.0},
        {"pos": BRANCH_POSITIONS[1], "amount": 3.0}
    ]
    shelters = [{"pos": TENT_POS, "stage": 2}]
    if not capture_requested:
        _load_world()
    elif user_args.has("gather_capture"):
        world_time = 0.47
        agents[0].pos = BRANCH_POSITIONS[0]
        agents[0].target = agents[0].pos
        agents[0].state = "breaking_branch"
        agents[0].interaction = 2.8
        agents[0].source_index = 0
        agents[0].decision = 2.8
        agents[1].pos = FIRE_POS+Vector2(54,0)
        agents[1].target = agents[1].pos
        agents[1].state = "sit"
        agents[1].decision = 8.0
    elif user_args.has("rain_capture"):
        world_time = 0.88
        raining = true
        weather_timer = 30.0
        fire_heat = 0.025
        fire_wetness = 0.88
        fire_fuel = 2.4
        _send_everyone_to_shelter()
        for i in range(agents.size()):
            agents[i].pos = agents[i].target
    elif user_args.has("kindle_capture"):
        world_time = 0.52
        fire_heat = 0.02
        fire_wetness = 0.34
        agents[0].pos = FIRE_POS+Vector2(-34,8)
        agents[0].target = agents[0].pos
        agents[0].state = "relighting"
        agents[0].interaction = 3.2
        agents[0].decision = 3.2
        agents[1].pos = FIRE_POS+Vector2(62,0)
        agents[1].target = agents[1].pos
        agents[1].state = "sit"
        agents[1].decision = 8.0
    elif user_args.has("pose_capture"):
        world_time = 0.50
        fire_heat = 0.62
        agents[0].pos = FIRE_POS+Vector2(-58,8)
        agents[0].target = agents[0].pos
        agents[0].state = "sit"
        agents[0].decision = 8.0
        agents[1].pos = FIRE_POS+Vector2(58,8)
        agents[1].target = agents[1].pos
        agents[1].state = "sit"
        agents[1].decision = 8.0
        agents[2].pos = FIRE_POS+Vector2(104,14)
        agents[2].target = agents[2].pos
        agents[2].state = "sit"
        agents[2].decision = 8.0
    set_process(true)
    queue_redraw()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        _save_world()
        get_tree().quit()

func _make_agent(display_name: String, start: Vector2, tint: Color, dog: bool) -> Dictionary:
    return {
        "name": display_name,
        "pos": start,
        "target": start,
        "color": tint,
        "dog": dog,
        "state": "idle",
        "energy": rng.randf_range(0.70, 0.95),
        "hunger": rng.randf_range(0.15, 0.35),
        "decision": rng.randf_range(2.0, 6.0),
        "carrying": false,
        "interaction": 0.0,
        "source_index": -1,
        "facing": 1.0
    }

func _process(delta: float) -> void:
    visual_time += delta
    _advance_time(delta)
    _advance_weather(delta)
    _advance_fire(delta)
    _advance_agents(delta)
    _advance_relationships(delta)
    story_timer = maxf(0.0, story_timer - delta)
    queue_redraw()
    if capture_requested and not capture_finished and visual_time > 1.0:
        capture_finished = true
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png("res://scene_capture.png")
        get_tree().quit()

func _advance_time(delta: float) -> void:
    world_time += delta / DAY_SECONDS
    if world_time >= 1.0:
        world_time -= 1.0
        day_number += 1
        _say("Dag %d begynder over den lille lejr." % day_number)
        _save_world()

func _advance_weather(delta: float) -> void:
    weather_timer -= delta
    if weather_timer > 0.0:
        return
    if raining:
        raining = false
        weather_timer = rng.randf_range(35.0, 70.0)
        _release_shelter()
        _say("Regnen stilner af. Dråberne hænger endnu i græsset.")
    else:
        raining = rng.randf() < 0.42
        weather_timer = rng.randf_range(22.0, 55.0)
        if raining:
            _send_everyone_to_shelter()
            _say("En stille regn glider ind over lejren.")

func _send_everyone_to_shelter() -> void:
    var shelter_offsets := [Vector2(-14,12),Vector2(8,12),Vector2(28,16)]
    for i in range(agents.size()):
        agents[i].state = "shelter"
        agents[i].target = TENT_POS + shelter_offsets[i]
        agents[i].decision = weather_timer

func _release_shelter() -> void:
    for i in range(agents.size()):
        agents[i].state = "idle"
        agents[i].target = agents[i].pos
        agents[i].decision = 0.0

func _advance_fire(delta: float) -> void:
    var was_lit := fire_heat > 0.06
    if raining:
        fire_wetness = minf(1.0, fire_wetness + delta * 0.026)
        fire_heat = maxf(0.0, fire_heat - delta * (0.018 + fire_wetness * 0.055))
        fire_fuel = maxf(0.0, fire_fuel - delta * 0.004)
    else:
        fire_wetness = maxf(0.0, fire_wetness - delta * 0.006)
        if fire_fuel > 0.05 and fire_heat > 0.03:
            var desired_heat := clampf((fire_fuel / 5.0) * (1.0 - fire_wetness * 0.55), 0.12, 1.0)
            fire_heat = move_toward(fire_heat, desired_heat, delta * 0.022)
            fire_fuel = maxf(0.0, fire_fuel - delta * (0.012 if _is_night() else 0.006))
        else:
            fire_heat = maxf(0.0, fire_heat - delta * 0.012)
    if fire_fuel <= 0.05:
        fire_heat = maxf(0.0, fire_heat - delta * 0.04)
    if was_lit and fire_heat <= 0.06:
        _record_action("fire_extinguished","",["Regnen efterlader ildstedet som mørke, rygende gløder.","Vandet vinder langsomt over de sidste gløder."])
    for source in branch_sources:
        source.amount = minf(3.0, float(source.amount) + delta * 0.0035)

func _advance_agents(delta: float) -> void:
    for i in range(agents.size()):
        var agent := agents[i]
        agent.energy = clampf(agent.energy - delta * (0.0012 if agent.dog else 0.0010), 0.0, 1.0)
        agent.hunger = clampf(agent.hunger + delta * 0.0008, 0.0, 1.0)
        agent.decision -= delta

        if agent.pos.distance_to(agent.target) > 3.0:
            var direction: Vector2 = agent.pos.direction_to(agent.target)
            agent.facing = signf(direction.x) if absf(direction.x) > 0.05 else agent.facing
            var speed := 54.0 if agent.dog else 38.0
            agent.pos += direction * speed * delta
        agents[i] = agent
        _apply_arrival(i, delta)
        agent = agents[i]
        var busy: bool = agent.state in ["breaking_branch", "adding_wood", "relighting"]
        if agent.pos.distance_to(agent.target) <= 3.0 and agent.decision <= 0.0 and not busy:
            _choose_action(i)

func _choose_action(index: int) -> void:
    var agent := agents[index]
    agent.decision = rng.randf_range(4.0, 10.0)

    if raining:
        agent.state = "shelter"
        agent.target = TENT_POS + Vector2(rng.randf_range(-28, 28), 12)
    elif _is_night() and agent.energy < 0.42:
        agent.state = "sleep"
        agent.target = TENT_POS + Vector2(rng.randf_range(-22, 22), 14)
    elif agent.dog:
        var person_index := 0 if milo_attachment[0] >= milo_attachment[1] else 1
        if rng.randf() < 0.28:
            person_index = 1 - person_index
        if fire_heat > 0.28 and (_is_night() or agent.energy < 0.52) and rng.randf() < 0.48:
            agent.state = "warm_fire"
            agent.target = FIRE_POS + Vector2(82 if rng.randf() < 0.5 else -82,14)
        elif not _is_night() and rng.randf() < 0.14:
            agent.state = "sniff_branches"
            var dog_source := _best_branch_source()
            agent.target = branch_sources[dog_source].pos + Vector2(rng.randf_range(-20,20),5)
        elif agent.energy < 0.38:
            agent.state = "sit"
            agent.target = agents[person_index].pos + Vector2(rng.randf_range(-24,24),7)
        else:
            agent.state = "follow"
            agent.target = agents[person_index].pos + Vector2(rng.randf_range(-35, 35), 5)
    elif agent.hunger > 0.72:
        agent.state = "eat"
        agent.target = FIRE_POS + Vector2(-45 if index == 0 else 45, 14)
    elif (fire_heat < 0.12 or fire_fuel < 2.8) and not agent.carrying:
        if stored_branches > 0 and fire_heat < 0.12:
            agent.state = "take_stored_wood"
            agent.target = WOOD_STORE_POS
        else:
            _begin_branch_gather(index,agent)
            return
    elif agent.carrying:
        agent.state = "carry_to_fire"
        agent.target = FIRE_POS + Vector2(-30 if index == 0 else 30, 8)
    elif stored_branches < 3 and not _is_night() and rng.randf() < 0.16:
        _begin_branch_gather(index,agent,true)
        return
    elif _is_night() and rng.randf() < 0.16:
        agent.state = "stargaze"
        agent.target = Vector2(390 if index == 0 else 1080, GROUND_Y)
    elif nora_otto_bond > 0.24 and rng.randf() < 0.32:
        _begin_shared_fire_moment(index)
        return
    elif _is_night() or rng.randf() < 0.38:
        agent.state = "sit"
        agent.target = FIRE_POS + Vector2(-58 if index == 0 else 58, 9)
    else:
        agent.state = "wander"
        agent.target = Vector2(rng.randf_range(120, 1160), GROUND_Y)

    agents[index] = agent

func _begin_shared_fire_moment(initiator: int) -> void:
    var duration := rng.randf_range(10.0,16.0)
    for i in range(2):
        agents[i].state = "sit"
        agents[i].target = FIRE_POS+Vector2(-52 if i == 0 else 52,9)
        agents[i].decision = duration+float(i)*0.8
    if rng.randf() < 0.45:
        _remember("shared_fire_%d" % day_number,"Nora og Otto deler et stille øjeblik ved bålet.")

func _best_branch_source() -> int:
    var best := 0
    for i in range(1,branch_sources.size()):
        if float(branch_sources[i].amount) > float(branch_sources[best].amount):
            best = i
    return best

func _begin_branch_gather(index: int, agent: Dictionary, for_storage: bool = false) -> void:
    var source_index := _best_branch_source()
    if float(branch_sources[source_index].amount) < 0.35:
        agent.state = "sit"
        agent.target = FIRE_POS + Vector2(-55 if index == 0 else 55,9)
        agent.decision = 4.0
    else:
        agent.state = "gather"
        agent.source_index = source_index
        agent.target = branch_sources[source_index].pos
        agent.decision = 8.0
        agent["gather_for_storage"] = for_storage
    agents[index] = agent

func _apply_arrival(index: int, delta: float) -> void:
    var agent := agents[index]
    if agent.pos.distance_to(agent.target) > 5.0:
        return
    if agent.state in ["carry_to_fire","adding_wood","relighting","sit","eat","warm_fire"]:
        agent.facing = 1.0 if agent.pos.x < FIRE_POS.x else -1.0

    match agent.state:
        "gather":
            agent.state = "breaking_branch"
            agent.interaction = 2.8
            agent.decision = 2.8
        "breaking_branch":
            agent.interaction -= delta
            agent.decision = agent.interaction
            if agent.interaction <= 0.0:
                var source_index := int(agent.source_index)
                branch_sources[source_index].amount = maxf(0.0,float(branch_sources[source_index].amount)-1.0)
                agent.carrying = true
                if bool(agent.get("gather_for_storage",false)) and fire_heat >= 0.12:
                    agent.state = "carry_to_store"
                    agent.target = WOOD_STORE_POS
                else:
                    agent.state = "carry_to_fire"
                    agent.target = FIRE_POS + Vector2(-30 if index == 0 else 30,8)
                agent.decision = 6.0
                _record_action("gather_tinder",agent.name,["%s samler tørt græs og birkebark under træerne.","%s finder en håndfuld tør tinder i skovbunden."])
        "take_stored_wood":
            if stored_branches > 0:
                stored_branches -= 1
                agent.carrying = true
                agent.state = "carry_to_fire"
                agent.target = FIRE_POS + Vector2(-30 if index == 0 else 30,8)
                agent.decision = 5.0
            else:
                agent.decision = 0.0
        "carry_to_store":
            stored_branches = mini(4,stored_branches+1)
            agent.carrying = false
            agent.state = "idle"
            agent.decision = rng.randf_range(4.0,8.0)
            _record_action("store_tinder",agent.name,["%s lægger den tørre tinder i læ ved skindhytten.","%s gemmer birkebarken, hvor regnen ikke kan nå den."])
        "carry_to_fire":
            agent.state = "adding_wood"
            agent.interaction = 1.8
            agent.decision = 1.8
        "adding_wood":
            agent.interaction -= delta
            agent.decision = agent.interaction
            if agent.interaction <= 0.0:
                agent.carrying = false
                fire_fuel = minf(8.0,fire_fuel+2.2)
                if fire_heat <= 0.12:
                    agent.state = "relighting"
                    agent.interaction = 3.2
                    agent.decision = 3.2
                else:
                    fire_heat = minf(1.0,fire_heat+0.16)
                    agent.state = "sit"
                    agent.decision = rng.randf_range(6.0,11.0)
                    _record_action("feed_fire",agent.name,["%s lægger tørre kviste over gløderne.","%s giver ilden et lille bundt brændsel."])
        "relighting":
            agent.interaction -= delta
            agent.decision = agent.interaction
            if agent.interaction <= 0.0:
                if fire_wetness > 0.48:
                    fire_wetness = maxf(0.0,fire_wetness-0.20)
                    fire_heat = 0.035
                    agent.state = "sit"
                    agent.decision = 3.5
                    _record_action("kindle_failed",agent.name,["%s slår gnister, men den fugtige tinder vil ikke tage fat.","Røgen vælter op, mens %s forsigtigt puster til tinderen."])
                else:
                    fire_heat = 0.42
                    fire_wetness = maxf(0.0,fire_wetness-0.12)
                    agent.state = "sit"
                    agent.decision = rng.randf_range(7.0,12.0)
                    _record_action("fire_relit",agent.name,["%s får en gnist fra flint og pyrit til at leve.","En lille flamme vokser frem, mens %s beskytter den med hænderne."])
        "sniff_branches":
            if float(agent.interaction) <= 0.0:
                agent.interaction = 3.2
                agent.decision = 3.2
            else:
                agent.interaction -= delta
                agent.decision = agent.interaction
                if agent.interaction <= 0.0:
                    agent.state = "sit"
                    agent.decision = rng.randf_range(4.0,7.0)
        "warm_fire":
            if float(agent.interaction) <= 0.0:
                agent.interaction = 2.8
                agent.decision = 2.8
            else:
                agent.interaction -= delta
                agent.decision = agent.interaction
                if agent.interaction <= 0.0:
                    agent.state = "sit"
                    agent.decision = rng.randf_range(7.0,13.0)
        "legacy_gather":
            agent.carrying = true
            agent.state = "feed_fire"
            agent.target = FIRE_POS + Vector2(rng.randf_range(-26, 26), 8)
            agent.decision = 3.0
            _say("%s finder nogle tørre grene." % agent.name)
        "legacy_feed_fire":
            if agent.carrying:
                agent.carrying = false
                fire_fuel = minf(8.0, fire_fuel + 2.2)
                _say("%s lægger grene på bålet." % agent.name)
            agent.state = "sit"
            agent.decision = rng.randf_range(7.0, 13.0)
        "sleep":
            agent.energy = minf(1.0, agent.energy + delta * 0.035)
            agent.decision = maxf(agent.decision, 2.0)
        "sit":
            agent.energy = minf(1.0, agent.energy + delta * 0.004)
        "eat":
            agent.hunger = maxf(0.08, agent.hunger - delta * 0.055)
            agent.energy = minf(1.0, agent.energy + delta * 0.003)
            if agent.hunger < 0.25:
                _remember("meal_%d_%s" % [day_number, agent.name], "%s spiser stille ved bålet." % agent.name)
                agent.state = "sit"
                agent.decision = rng.randf_range(5.0,9.0)
        "stargaze":
            _remember("sky_%d_%s" % [day_number, agent.name], "%s bliver stående lidt under aftenhimlen." % agent.name)
            agent.state = "watching_sky"
            agent.decision = rng.randf_range(8.0,14.0)
        "shelter":
            agent.energy = minf(1.0, agent.energy + delta * 0.008)
        _:
            pass
    agents[index] = agent

func _advance_relationships(delta: float) -> void:
    if agents.size() < 3:
        return
    var nora: Dictionary = agents[0]
    var otto: Dictionary = agents[1]
    var milo: Dictionary = agents[2]
    var quietly_together: bool = nora.pos.distance_to(otto.pos) < 92.0 and nora.state in ["sit","eat","shelter"] and otto.state in ["sit","eat","shelter"]
    if quietly_together:
        nora_otto_bond = minf(1.0,nora_otto_bond + delta * 0.0012)
        if nora_otto_bond >= 0.25:
            _remember("bond_first_fire", "Nora og Otto har fundet deres faste pladser ved bålet.")
        if nora_otto_bond >= 0.55:
            _remember("bond_trusted", "Stilheden mellem Nora og Otto føles efterhånden tryg.")
    for i in range(2):
        if milo.pos.distance_to(agents[i].pos) < 58.0:
            milo_attachment[i] = minf(1.0,float(milo_attachment[i]) + delta * 0.0008)

func _remember(key: String, text: String) -> void:
    if remembered_moments.has(key):
        return
    remembered_moments[key] = true
    event_history.append("Dag %d · %s" % [day_number,text])
    if event_history.size() > 32:
        event_history.pop_front()
    _say(text)

func _is_night() -> bool:
    return world_time < 0.22 or world_time > 0.76

func _say(text: String) -> void:
    story_line = text
    story_timer = 8.0

func _record_action(action_id: String, actor_name: String, variants: Array) -> void:
    action_counts[action_id] = int(action_counts.get(action_id,0))+1
    var variant_index := rng.randi_range(0,variants.size()-1)
    if variants.size() > 1 and recent_action == "%s:%d" % [action_id,variant_index]:
        variant_index = (variant_index+1)%variants.size()
    recent_action = "%s:%d" % [action_id,variant_index]
    var line := String(variants[variant_index])
    if line.contains("%s"):
        line = line % actor_name
    _say(line)

func _draw() -> void:
    _draw_background_art()
    _draw_shelters_and_craft()
    _draw_world_items()
    _draw_fire()
    for agent in agents:
        _draw_agent(agent)
    if raining:
        _draw_rain()
    _draw_living_details()
    _draw_whisper_text()

func _draw_background_art() -> void:
    draw_texture_rect(CAMP_BACKGROUND, Rect2(0, 0, 1280, 360), false)
    var night_strength := 0.0
    if world_time < 0.22:
        night_strength = 1.0
    elif world_time < 0.34:
        night_strength = 1.0-smoothstep(0.22,0.34,world_time)
    elif world_time > 0.64:
        night_strength = smoothstep(0.64,0.76,world_time)
    if night_strength > 0.0:
        draw_texture_rect(CAMP_NIGHT,Rect2(0,0,1280,360),false,Color(1,1,1,night_strength))
    elif world_time > 0.22 and world_time < 0.62:
        draw_rect(Rect2(0,0,1280,360),Color(1.0,0.89,0.68,0.05))

func _draw_world_items() -> void:
    for source in branch_sources:
        var amount := float(source.amount)
        var frame_index := 0
        if amount > 2.0:
            frame_index = 2
        elif amount > 1.0:
            frame_index = 1
        var texture: Texture2D = BRANCH_SOURCE_FRAMES[frame_index]
        var size := texture.get_size()
        var alpha := clampf(amount + 0.18,0.24,1.0)
        draw_texture(texture,Vector2(source.pos.x-size.x*.5,GROUND_Y+15-size.y),Color(1,1,1,alpha))
    for i in range(stored_branches):
        var bundle_size := BRANCH_BUNDLE.get_size()
        var offset := Vector2(float(i % 2) * 10.0 - 5.0,-float(i / 2) * 7.0)
        draw_texture(BRANCH_BUNDLE,WOOD_STORE_POS+offset-Vector2(bundle_size.x*.5,bundle_size.y))

func _draw_shelters_and_craft() -> void:
    for shelter in shelters:
        var stage := clampi(int(shelter.get("stage",2)),0,SHELTER_TEXTURES.size()-1)
        var texture: Texture2D = SHELTER_WET if raining and stage == 2 else SHELTER_TEXTURES[stage]
        var position: Vector2 = shelter.pos
        var size := texture.get_size()
        if _is_night() and stage == 2:
            draw_circle(position+Vector2(0,-25),24,Color(1.0,0.45,0.16,0.055))
        draw_texture(texture,position+Vector2(-size.x*.5,18-size.y))
        if _is_night() and stage == 2 and not raining:
            draw_circle(position+Vector2(-2,-20),5,Color(1.0,0.53,0.20,0.38))
    _draw_grounded_prop(BASKET,Vector2(914,GROUND_Y+14))
    _draw_grounded_prop(CLAY_POT,Vector2(852,GROUND_Y+14))
    _draw_grounded_prop(DRYING_RACK,Vector2(1090,GROUND_Y+15))
    _draw_grounded_prop(STONE_AXE,Vector2(956,GROUND_Y+15))
    _draw_grounded_prop(FLINT_PYRITE,FIRE_POS+Vector2(48,19))

func _draw_grounded_prop(texture: Texture2D, position: Vector2) -> void:
    var size := texture.get_size()
    draw_texture(texture,position-Vector2(size.x*.5,size.y))

func _draw_sky() -> void:
    var daylight := _daylight_amount()
    var night_top := Color("#121b30")
    var day_top := Color("#6f91ad")
    var top := night_top.lerp(day_top, daylight)
    var night_horizon := Color("#26304a")
    var day_horizon := Color("#e6a27f")
    var dusk := smoothstep(0.64, 0.88, world_time) * (1.0 - smoothstep(0.97, 1.0, world_time))
    var horizon := night_horizon.lerp(day_horizon, maxf(daylight, dusk * 0.92))
    for y in range(0, 282, 3):
        var blend := smoothstep(0.0, 1.0, float(y) / 282.0)
        draw_rect(Rect2(0, y, WORLD_WIDTH, 4), top.lerp(horizon, blend))

    var sun_x := world_time * WORLD_WIDTH
    var arc := sin(world_time * PI)
    var body_y := 210.0 - arc * 150.0
    var celestial_night := world_time < 0.18 or world_time > 0.97
    if celestial_night:
        draw_circle(Vector2(sun_x, body_y), 16, Color("#d8dfd5"))
        for p in [Vector2(110,55),Vector2(240,95),Vector2(420,48),Vector2(790,80),Vector2(1040,45),Vector2(1180,110)]:
            draw_circle(p, 1.3 + sin(visual_time * 0.4 + p.x) * 0.25, Color("#e6e5cf"))
    else:
        for radius in range(52, 20, -4):
            draw_circle(Vector2(sun_x, body_y), radius, Color(1.0, 0.67, 0.35, 0.008))
        draw_circle(Vector2(sun_x, body_y), 18, Color("#f8d89b"))
    var cloud_tint := Color(0.76, 0.61, 0.61, 0.18 + daylight * 0.12)
    for cloud in [Vector2(190,120), Vector2(505,86), Vector2(870,134), Vector2(1110,76)]:
        var drift := fmod(visual_time * 1.3 + cloud.x, 1440.0) - 80.0
        draw_line(Vector2(drift - 48, cloud.y), Vector2(drift + 52, cloud.y), cloud_tint, 2.0)
        draw_circle(Vector2(drift - 15, cloud.y - 3), 9, cloud_tint)
        draw_circle(Vector2(drift + 8, cloud.y - 7), 13, cloud_tint)

func _daylight_amount() -> float:
    return clampf(sin(world_time * PI), 0.0, 1.0)

func _draw_landscape() -> void:
    var light := _daylight_amount()
    var far := Color("#586875").darkened((1.0 - light) * 0.5)
    var rear_hills := PackedVector2Array([Vector2(0,239),Vector2(105,190),Vector2(185,228),Vector2(275,169),Vector2(365,231),Vector2(470,180),Vector2(570,222),Vector2(685,159),Vector2(790,226),Vector2(900,172),Vector2(1012,228),Vector2(1138,177),Vector2(1280,223),Vector2(1280,290),Vector2(0,290)])
    draw_colored_polygon(rear_hills, far)
    var front_hills := PackedVector2Array([Vector2(0,254),Vector2(128,216),Vector2(245,251),Vector2(370,207),Vector2(495,253),Vector2(612,214),Vector2(740,250),Vector2(872,205),Vector2(1010,252),Vector2(1140,218),Vector2(1280,248),Vector2(1280,300),Vector2(0,300)])
    draw_colored_polygon(front_hills, Color("#34484a").lerp(Color("#49635a"), light * 0.35))
    var ground := Color("#263d2d").lerp(Color("#3f5b38"), light * 0.45)
    draw_rect(Rect2(0, GROUND_Y, WORLD_WIDTH, 82), ground)
    draw_line(Vector2(0, GROUND_Y), Vector2(WORLD_WIDTH, GROUND_Y), Color("#718051").darkened((1.0-light)*0.4), 3.0)
    draw_rect(Rect2(0, 314, WORLD_WIDTH, 46), Color("#18231f").lerp(Color("#263128"), light * 0.2))
    for x in range(-20, 1310, 38):
        var stone_y := 316.0 + fmod(float(x * 11 + 43), 17.0)
        var stone_color := Color("#303833").lerp(Color("#454a40"), light * 0.25)
        draw_circle(Vector2(x, stone_y), 13.0 + fmod(float(x), 7.0), stone_color)
        draw_arc(Vector2(x, stone_y), 13.0, PI, TAU, 8, stone_color.lightened(0.12), 1.3)

func _draw_far_forest() -> void:
    var night_fade := (1.0 - _daylight_amount()) * 0.35
    for x in range(-10, 1300, 27):
        var height := 25.0 + fmod(float(x * 13 + 79), 32.0)
        _draw_pine(Vector2(x, GROUND_Y + 2), height, Color("#243a32").darkened(night_fade), sin(visual_time * 0.22 + x) * 0.3)
    _draw_pine(Vector2(88, GROUND_Y + 4), 116, Color("#172b23"), sin(visual_time * 0.18) * 0.8)
    _draw_pine(Vector2(1185, GROUND_Y + 4), 134, Color("#162920"), sin(visual_time * 0.17 + 1.0))
    _draw_pine(Vector2(1105, GROUND_Y + 2), 82, Color("#1e3327"), sin(visual_time * 0.2 + 2.0) * 0.7)

func _draw_pine(base: Vector2, height: float, color: Color, sway: float) -> void:
    draw_rect(Rect2(base.x - 2, base.y - height * 0.42, 4, height * 0.44), Color("#443326"))
    for layer in range(4):
        var y := base.y - height + layer * height * 0.19
        var half := height * (0.15 + layer * 0.055)
        draw_colored_polygon(PackedVector2Array([Vector2(base.x + sway,y),Vector2(base.x-half,y+height*0.34),Vector2(base.x+half,y+height*0.34)]),color.lightened(layer*0.025))

func _draw_tent() -> void:
    var canvas := Color("#a8734f").darkened((1.0 - _daylight_amount()) * 0.24)
    draw_circle(TENT_POS + Vector2(0,-28), 54, Color(1.0,0.48,0.18,0.035 if _is_night() else 0.01))
    var tent := PackedVector2Array([Vector2(835,278),Vector2(900,205),Vector2(970,278)])
    draw_colored_polygon(tent, canvas)
    draw_polyline(PackedVector2Array([Vector2(835,278),Vector2(900,205),Vector2(970,278)]), Color("#684a35"), 4.0)
    draw_line(Vector2(900,201),Vector2(900,280),Color("#493429"),3.0)
    draw_colored_polygon(PackedVector2Array([Vector2(900,278),Vector2(900,232),Vector2(929,278)]),Color("#3b302a"))
    draw_line(Vector2(900,205), Vector2(818,281), Color("#d0a477"), 1.5)
    draw_line(Vector2(900,205), Vector2(986,281), Color("#d0a477"), 1.5)
    draw_circle(Vector2(817,281), 2.5, Color("#9b7958"))
    draw_circle(Vector2(987,281), 2.5, Color("#9b7958"))

func _draw_fire() -> void:
    var strength := clampf(fire_heat,0.0,1.0)
    if strength > 0.03:
        for radius in range(62,20,-6):
            draw_circle(FIRE_POS+Vector2(0,7),radius*strength,Color(1.0,0.42,0.1,0.014*strength))
    var ground_anchor := FIRE_POS + Vector2(0,18)
    var fire_bed: Texture2D = FIRE_COLD
    if strength > 0.18:
        fire_bed = FIRE_EMBERS
    elif strength > 0.035:
        fire_bed = FIRE_TINY
    var base_size := fire_bed.get_size()
    draw_texture(fire_bed,ground_anchor-Vector2(base_size.x*.5,base_size.y))
    if strength > 0.18:
        var flame: Texture2D = FLAME_FRAMES[int(visual_time*5.0)%FLAME_FRAMES.size()]
        var flame_size := flame.get_size()
        var flame_scale := lerpf(0.34,1.0,strength)
        draw_set_transform(ground_anchor-Vector2(0,18),0.0,Vector2(flame_scale,flame_scale))
        draw_texture(flame,Vector2(-flame_size.x*.5,-flame_size.y))
        draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
    var smoke_amount := clampf(fire_wetness*1.4+(1.0-strength)*0.35,0.08,1.0)
    for i in range(5):
        var life := fmod(visual_time*(0.07+fire_wetness*.04)+float(i)*0.2,1.0)
        var smoke := ground_anchor+Vector2(sin(life*5.0+i)*10.0,-25.0-life*82.0)
        draw_circle(smoke,(3.0+life*10.0)*smoke_amount,Color(0.62,0.64,0.64,(1.0-life)*0.18*smoke_amount))
    if strength > 0.05:
        for i in range(6):
            var ember := fmod(visual_time*0.3+float(i)*0.16,1.0)
            draw_circle(FIRE_POS+Vector2(sin(float(i)*8.0)*12.0,-12-ember*45),1.2,Color(1.0,0.65,0.18,(1.0-ember)*strength))

func _draw_agent(agent: Dictionary) -> void:
    var pos: Vector2 = agent.pos
    var sleeping: bool = agent.state == "sleep" and pos.distance_to(agent.target) < 8.0
    var moving: bool = agent.pos.distance_to(agent.target) > 3.0
    var walk_frame := int(visual_time * (8.0 if agent.dog else 6.0)) % 4
    var breathing := sin(visual_time * (1.2 if agent.dog else 0.75) + pos.x * 0.02) * 0.8
    pos.y += (-1.0 if moving and walk_frame % 2 == 1 else breathing)
    var texture: Texture2D
    var pose := "idle"
    if agent.dog:
        if sleeping:
            pose = "sleep"
        elif agent.state == "sniff_branches":
            pose = "sniff"
        elif agent.state == "warm_fire":
            pose = "wag"
        elif agent.state == "sit":
            pose = "rest"
        elif moving:
            pose = "idle"
        elif agent.state == "shelter":
            pose = "sit"
        texture = MILO_SPRITES[pose]
        if moving:
            texture = MILO_WALK_FRAMES[walk_frame]
    else:
        if sleeping:
            pose = "sleep"
        elif agent.state == "breaking_branch":
            var gather_progress := clampf((2.8-float(agent.interaction))/2.8,0.0,0.999)
            var gather_index := mini(2,int(gather_progress*3.0))
            texture = NORA_GATHER_FRAMES[gather_index] if agent.name == "Nora" else OTTO_GATHER_FRAMES[gather_index]
        elif moving:
            pose = "idle"
        elif agent.state == "sit":
            pose = "sit"
        elif agent.state == "eat":
            pose = "eat"
        elif agent.state == "relighting":
            pose = "strike" if float(agent.interaction) > 1.6 else "blow"
        elif agent.state in ["feed_fire","adding_wood"]:
            pose = "warm" if agent.name == "Nora" else "tend"
        if texture == null:
            texture = NORA_SPRITES[pose] if agent.name == "Nora" else OTTO_SPRITES[pose]
        if moving and agent.state != "breaking_branch":
            texture = NORA_WALK_FRAMES[walk_frame] if agent.name == "Nora" else OTTO_WALK_FRAMES[walk_frame]
    var shelter_alpha := 1.0
    if raining and agent.state == "shelter":
        shelter_alpha = clampf(agent.pos.distance_to(agent.target) / 20.0,0.0,1.0)
        if shelter_alpha <= 0.02:
            return
    var sprite_size := texture.get_size()
    var flip := -1.0 if agent.facing < 0.0 and not sleeping else 1.0
    draw_set_transform(pos + Vector2(0, 13), 0.0, Vector2(flip,1.0))
    draw_texture(texture, Vector2(-sprite_size.x * 0.5, -sprite_size.y),Color(1,1,1,shelter_alpha))
    if agent.carrying and moving and not agent.dog:
        var bundle_size := BRANCH_BUNDLE.get_size()
        draw_texture(BRANCH_BUNDLE,Vector2(-bundle_size.x*.5+5,-bundle_size.y-23),Color(1,1,1,shelter_alpha))
    draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
    if sleeping:
        var z_pos := pos + Vector2(sprite_size.x*.28,-sprite_size.y-3)
        draw_string(ThemeDB.fallback_font,z_pos,"z",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(1,1,0.86,0.58))

func _draw_ellipse_shape(center: Vector2, radii: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i in range(24):
        var a := TAU * float(i) / 24.0
        points.append(center + Vector2(cos(a)*radii.x,sin(a)*radii.y))
    draw_colored_polygon(points,color)

func _draw_rain() -> void:
    var t := Time.get_ticks_msec() * 0.25
    for i in range(75):
        var x := fmod(float(i * 83) + t, WORLD_WIDTH + 40.0) - 20.0
        var y := fmod(float(i * 47) + t * 1.7, 315.0)
        draw_line(Vector2(x,y),Vector2(x-7,y+16),Color(0.75,0.86,0.92,0.48),1.2)

func _draw_living_details() -> void:
    if _is_night():
        var star_cycle := fmod(visual_time,23.0)
        if star_cycle < 1.4:
            var star_pos := Vector2(930.0+star_cycle*70.0,76.0+star_cycle*22.0)
            draw_line(star_pos,star_pos-Vector2(18,6),Color(0.95,0.93,0.76,1.0-star_cycle/1.4),1.2)
    elif not raining:
        var bird_x := fmod(visual_time*9.0,1450.0)-80.0
        draw_arc(Vector2(bird_x,92),7,PI+0.2,TAU-0.2,7,Color(0.16,0.20,0.23,0.55),1.1)
        draw_arc(Vector2(bird_x+13,92),7,PI+0.2,TAU-0.2,7,Color(0.16,0.20,0.23,0.55),1.1)
    if raining:
        for i in range(4):
            var ripple := fmod(visual_time*.7+float(i)*.24,1.0)
            draw_arc(Vector2(350+i*190,350),3.0+ripple*13.0,0,TAU,24,Color(0.65,0.78,0.84,(1.0-ripple)*.35),1.0)

func _draw_foreground_details() -> void:
    for x in range(14, 1270, 18):
        var sway := sin(visual_time * 0.48 + x * 0.07) * 2.2
        var base := Vector2(x, GROUND_Y + 8 + fmod(float(x * 7), 14.0))
        draw_line(base, base + Vector2(-3 + sway, -11 - fmod(float(x), 7.0)), Color("#688052").darkened((1.0-_daylight_amount())*.4), 1.4)
    for p in [Vector2(280,285),Vector2(326,290),Vector2(1038,286),Vector2(1088,292),Vector2(440,287)]:
        draw_line(p,p+Vector2(sin(visual_time*.4+p.x)*1.5,-10),Color("#557147"),1.5)
        draw_circle(p+Vector2(0,-12),2.2,Color("#d4a44e" if int(p.x)%3 else "#d9c9a5"))
    for p in [Vector2(385,293),Vector2(795,292),Vector2(1010,299)]:
        draw_circle(p,8,Color("#3c4540"))
        draw_arc(p,8,PI,TAU,8,Color("#646a60"),1.3)
    # Fire ring, seats and a few lived-in camp traces.
    for angle in range(0, 360, 45):
        var rad := deg_to_rad(float(angle))
        var rock := FIRE_POS + Vector2(cos(rad) * 24.0, 17.0 + sin(rad) * 7.0)
        draw_circle(rock, 4.5, Color("#5b5a4c"))
    draw_line(Vector2(555,286), Vector2(608,289), Color("#5a3925"), 10.0)
    draw_circle(Vector2(608,289), 5.0, Color("#a07143"))
    draw_line(Vector2(706,291), Vector2(751,287), Color("#533523"), 9.0)
    draw_circle(Vector2(706,291), 4.5, Color("#95683f"))
    for x in [205, 223, 1082, 1100]:
        draw_line(Vector2(x,292),Vector2(x+17,282),Color("#725038"),3.0)

func _draw_whisper_text() -> void:
    if story_timer <= 0.0:
        return
    var alpha := clampf(story_timer / 2.0,0.0,1.0)
    var text := "Dag %d  ·  %s" % [day_number, story_line]
    var width := ThemeDB.fallback_font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
    draw_string(ThemeDB.fallback_font,Vector2((WORLD_WIDTH-width)*0.5,32),text,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(0.96,0.94,0.85,alpha))

func _save_world() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("world","time",world_time)
    cfg.set_value("world","day",day_number)
    cfg.set_value("world","fire_fuel",fire_fuel)
    cfg.set_value("world","fire_heat",fire_heat)
    cfg.set_value("world","fire_wetness",fire_wetness)
    cfg.set_value("world","stored_branches",stored_branches)
    for i in range(branch_sources.size()):
        cfg.set_value("world","branch_%d" % i,float(branch_sources[i].amount))
    cfg.set_value("world","unix_time",Time.get_unix_time_from_system())
    cfg.set_value("story","nora_otto_bond",nora_otto_bond)
    cfg.set_value("story","milo_attachment",milo_attachment)
    cfg.set_value("story","event_history",event_history)
    cfg.set_value("story","remembered_moments",remembered_moments)
    cfg.set_value("story","action_counts",action_counts)
    cfg.set_value("world","shelter_stage",int(shelters[0].stage) if shelters.size() > 0 else 2)
    for i in range(agents.size()):
        cfg.set_value("agent_%d" % i,"position",agents[i].pos)
        cfg.set_value("agent_%d" % i,"energy",agents[i].energy)
        cfg.set_value("agent_%d" % i,"hunger",agents[i].hunger)
    cfg.save(SAVE_PATH)

func _load_world() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    world_time = float(cfg.get_value("world","time",world_time))
    day_number = int(cfg.get_value("world","day",day_number))
    fire_fuel = float(cfg.get_value("world","fire_fuel",fire_fuel))
    fire_heat = float(cfg.get_value("world","fire_heat",fire_heat))
    fire_wetness = float(cfg.get_value("world","fire_wetness",fire_wetness))
    stored_branches = int(cfg.get_value("world","stored_branches",stored_branches))
    for i in range(branch_sources.size()):
        branch_sources[i].amount = float(cfg.get_value("world","branch_%d" % i,branch_sources[i].amount))
    nora_otto_bond = float(cfg.get_value("story","nora_otto_bond",nora_otto_bond))
    milo_attachment = cfg.get_value("story","milo_attachment",milo_attachment)
    var loaded_history: Array = cfg.get_value("story","event_history",[])
    event_history.assign(loaded_history)
    remembered_moments = cfg.get_value("story","remembered_moments",remembered_moments)
    action_counts = cfg.get_value("story","action_counts",action_counts)
    if shelters.size() > 0:
        shelters[0].stage = int(cfg.get_value("world","shelter_stage",shelters[0].stage))
    var then := int(cfg.get_value("world","unix_time",Time.get_unix_time_from_system()))
    var elapsed := clampi(int(Time.get_unix_time_from_system()) - then,0,86400 * 7)
    world_time += float(elapsed) / DAY_SECONDS
    day_number += int(floor(world_time))
    world_time = fmod(world_time,1.0)
    fire_fuel = maxf(0.0,fire_fuel-elapsed*.0007)
    fire_heat = minf(fire_heat,clampf(fire_fuel/4.0,0.0,1.0))
    for i in range(agents.size()):
        agents[i].pos = cfg.get_value("agent_%d" % i,"position",agents[i].pos)
        if agents[i].pos.y < GROUND_Y - 18.0:
            agents[i].pos.y = GROUND_Y + (7.0 if agents[i].dog else 0.0)
        agents[i].target = agents[i].pos
        agents[i].energy = float(cfg.get_value("agent_%d" % i,"energy",agents[i].energy))
        agents[i].hunger = float(cfg.get_value("agent_%d" % i,"hunger",agents[i].hunger))
    _say("Verden har levet videre, mens du var væk.")
