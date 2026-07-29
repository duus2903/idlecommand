extends Node2D

const SAVE_PATH := "user://idlecommand_save.cfg"
const WORLD_WIDTH := 1280.0
const GROUND_Y := 334.0
const DAY_SECONDS := 180.0
const FIRE_POS := Vector2(650, 329)
const TENT_POS := Vector2(1000, 326)
const WOOD_STORE_POS := Vector2(908, 337)
const BRANCH_POSITIONS := [Vector2(250, 334), Vector2(1120, 334)]
const CAMP_BACKGROUND := preload("res://assets/camp_sunset.png")
const CAMP_NIGHT := preload("res://assets/camp_night.png")
const NORA_SPRITES := {
    "idle": preload("res://assets/sprites/nora_idle.png"),
    "sit": preload("res://assets/sprites/nora_sit.png"),
    "warm": preload("res://assets/sprites/nora_warm.png"),
    "sleep": preload("res://assets/sprites/nora_sleep.png")
}
const OTTO_SPRITES := {
    "idle": preload("res://assets/sprites/otto_idle.png"),
    "sit": preload("res://assets/sprites/otto_sit.png"),
    "tend": preload("res://assets/sprites/otto_tend.png"),
    "sleep": preload("res://assets/sprites/otto_sleep.png")
}
const MILO_SPRITES := {
    "idle": preload("res://assets/sprites/milo_stand.png"),
    "sit": preload("res://assets/sprites/milo_sit.png"),
    "rest": preload("res://assets/sprites/milo_rest.png"),
    "sleep": preload("res://assets/sprites/milo_sleep.png")
}
const NORA_WALK_FRAMES := [
    preload("res://assets/sprites/nora_walk_0.png"),
    preload("res://assets/sprites/nora_walk_1.png"),
    preload("res://assets/sprites/nora_walk_2.png"),
    preload("res://assets/sprites/nora_walk_3.png")
]
const OTTO_WALK_FRAMES := [
    preload("res://assets/sprites/otto_walk_0.png"),
    preload("res://assets/sprites/otto_walk_1.png"),
    preload("res://assets/sprites/otto_walk_2.png"),
    preload("res://assets/sprites/otto_walk_3.png")
]
const MILO_WALK_FRAMES := [
    preload("res://assets/sprites/milo_walk_0.png"),
    preload("res://assets/sprites/milo_walk_1.png"),
    preload("res://assets/sprites/milo_walk_2.png"),
    preload("res://assets/sprites/milo_walk_3.png")
]
const FIRE_BASE := preload("res://assets/sprites/fire_base.png")
const FLAME_FRAMES := [
    preload("res://assets/sprites/flame_0.png"),
    preload("res://assets/sprites/flame_1.png"),
    preload("res://assets/sprites/flame_2.png"),
    preload("res://assets/sprites/flame_3.png")
]
const NORA_GATHER_FRAMES := [
    preload("res://assets/sprites/nora_gather_0.png"),
    preload("res://assets/sprites/nora_gather_1.png"),
    preload("res://assets/sprites/nora_gather_2.png")
]
const OTTO_GATHER_FRAMES := [
    preload("res://assets/sprites/otto_gather_0.png"),
    preload("res://assets/sprites/otto_gather_1.png"),
    preload("res://assets/sprites/otto_gather_2.png")
]
const BRANCH_SOURCE_FRAMES := [
    preload("res://assets/sprites/branch_source_low.png"),
    preload("res://assets/sprites/branch_source_half.png"),
    preload("res://assets/sprites/branch_source_full.png")
]
const BRANCH_BUNDLE := preload("res://assets/sprites/branch_bundle.png")

var world_time := 0.92
var day_number := 1
var raining := false
var weather_timer := 32.0
var fire_fuel := 5.0
var fire_heat := 0.82
var fire_wetness := 0.0
var stored_branches := 1
var branch_sources: Array[Dictionary] = []
var story_line := "Lejren vÃ¥gner stille."
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
    capture_requested = user_args.has("capture") or user_args.has("gather_capture") or user_args.has("rain_capture")
    agents = [
        _make_agent("Nora", Vector2(520, GROUND_Y), Color("#d17a74"), false),
        _make_agent("Otto", Vector2(760, GROUND_Y), Color("#7fa6c9"), false),
        _make_agent("Milo", Vector2(700, GROUND_Y + 7), Color("#b99062"), true)
    ]
    branch_sources = [
        {"pos": BRANCH_POSITIONS[0], "amount": 3.0},
        {"pos": BRANCH_POSITIONS[1], "amount": 3.0}
    ]
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
        _say("Regnen stilner af. DrÃ¥berne hÃ¦nger endnu i grÃ¦sset.")
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
        _remember("fire_out_%d" % day_number, "Regnen har efterladt bÃ¥let som mÃ¸rke, rygende glÃ¸der.")
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
        _remember("shared_fire_%d" % day_number,"Nora og Otto deler et stille Ã¸jeblik ved bÃ¥let.")

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
                _say("%s knÃ¦kker et bundt tÃ¸rre grene fri." % agent.name)
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
            _say("%s lÃ¦gger tÃ¸rre grene under teltets lÃ¦." % agent.name)
        "carry_to_fire":
            agent.state = "adding_wood"
            agent.interactiÛw¶‰žËkºwµçy}à°‰½‘å}ä¤°€Äà°½±½È ˆ˜áàåˆˆ¤¤(€€€Ù…È±½Õ‘}Ñ¥¹Ð€èô½±½È À¸ÜØ°€À¸ØÄ°€À¸ØÄ°€À¸Äà€¬‘…å±¥¡Ð€¨€À¸ÄÈ¤(€€€™½È±½Õ¥¸mY•Ñ½ÈÈ ÄäÀ°ÄÈÀ¤°Y•Ñ½ÈÈ ÔÀÔ°àØ¤°Y•Ñ½ÈÈ àÜÀ°ÄÌÐ¤°Y•Ñ½ÈÈ ÄÄÄÀ°ÜØ¥tè(€€€€€€€Ù…È‘É¥™Ð€èô™µ½¡Ù¥ÍÕ…±}Ñ¥µ”€¨€Ä¸Ì€¬±½Õ¹à°€ÄÐÐÀ¸À¤€´€àÀ¸À(€€€€€€€‘É…Ý}±¥¹”¡Y•Ñ½ÈÈ¡‘É¥™Ð€´€Ðà°±½Õ¹ä¤°Y•Ñ½ÈÈ¡‘É¥™Ð€¬€ÔÈ°±½Õ¹ä¤°±½Õ‘}Ñ¥¹Ð°€È¸À¤(€€€€€€€‘É…Ý}¥É±”¡Y•Ñ½ÈÈ¡‘É¥™Ð€´€ÄÔ°±½Õ¹ä€´€Ì¤°€ä°±½Õ‘}Ñ¥¹Ð¤(€€€€€€€‘É…Ý}¥É±”¡Y•Ñ½ÈÈ¡‘É¥™Ð€¬€à°±½Õ¹ä€´€Ü¤°€ÄÌ°±½Õ‘}Ñ¥¹Ð¤()™Õ¹Œ}‘…å±¥¡Ñ}…µ½Õ¹Ð ¤€´ø™±½…Ðè(€€€É•ÑÕÉ¸±…µÁ˜¡Í¥¸¡Ý½É±‘}Ñ¥µ”€¨A$¤°€À¸À°€Ä¸À¤()™Õ¹Œ}‘É…Ý}±…¹‘Í…Á” ¤€´øÙ½¥è(€€€Ù…È±¥¡Ð€èô}‘…å±¥¡Ñ}…µ½Õ¹Ð ¤(€€€Ù…È™…È€èô½±½È ˆŒÔàØàÜÔˆ¤¹‘…É­•¹•  Ä¸À€´±¥¡Ð¤€¨€À¸Ô¤(€€€Ù…ÈÉ•…É}¡¥±±Ì€èôA…­•‘Y•Ñ½ÈÉÉÉ…ä¡mY•Ñ½ÈÈ À°ÈÌä¤±Y•Ñ½ÈÈ ÄÀÔ°ÄäÀ¤±Y•Ñ½ÈÈ ÄàÔ°ÈÈà¤±Y•Ñ½ÈÈ ÈÜÔ°ÄØä¤±Y•Ñ½ÈÈ ÌØÔ°ÈÌÄ¤±Y•Ñ½ÈÈ ÐÜÀ°ÄàÀ¤±Y•Ñ½ÈÈ ÔÜÀ°ÈÈÈ¤±Y•Ñ½ÈÈ ØàÔ°ÄÔä¤±Y•Ñ½ÈÈ ÜäÀ°ÈÈØ¤±Y•Ñ½ÈÈ äÀÀ°ÄÜÈ¤±Y•Ñ½ÈÈ ÄÀÄÈ°ÈÈà¤±Y•Ñ½ÈÈ ÄÄÌà°ÄÜÜ¤±Y•Ñ½ÈÈ ÄÈàÀ°ÈÈÌ¤±Y•Ñ½ÈÈ ÄÈàÀ°ÈäÀ¤±Y•Ñ½ÈÈ À°ÈäÀ¥t¤(€€€‘É…Ý}½±½É•‘}Á½±å½¸¡É•…É}¡¥±±Ì°™…È¤(€€€Ù…È™É½¹Ñ}¡¥±±Ì€èôA…­•‘Y•Ñ½ÈÉÉÉ…ä¡mY•Ñ½ÈÈ À°ÈÔÐ¤±Y•Ñ½ÈÈ ÄÈà°ÈÄØ¤±Y•Ñ½ÈÈ ÈÐÔ°ÈÔÄ¤±Y•Ñ½ÈÈ ÌÜÀ°ÈÀÜ¤±Y•Ñ½ÈÈ ÐäÔ°ÈÔÌ¤±Y•Ñ½ÈÈ ØÄÈ°ÈÄÐ¤±Y•Ñ½ÈÈ ÜÐÀ°ÈÔÀ¤±Y•Ñ½ÈÈ àÜÈ°ÈÀÔ¤±Y•Ñ½ÈÈ ÄÀÄÀ°ÈÔÈ¤±Y•Ñ½ÈÈ ÄÄÐÀ°ÈÄà¤±Y•Ñ½ÈÈ ÄÈàÀ°ÈÐà¤±Y•Ñ½ÈÈ ÄÈàÀ°ÌÀÀ¤±Y•Ñ½ÈÈ À°ÌÀÀ¥t¤(€€€‘É…Ý}½±½É•‘}Á½±å½¸¡™É½¹Ñ}¡¥±±Ì°½±½È ˆŒÌÐÐàÑ„ˆ¤¹±•ÉÀ¡½±½È ˆŒÐäØÌÕ„ˆ¤°±¥¡Ð€¨€À¸ÌÔ¤¤(€€€Ù…ÈÉ½Õ¹€èô½±½È ˆŒÈØÍÉˆ¤¹±•ÉÀ¡½±½È ˆŒÍ˜ÕˆÌàˆ¤°±¥¡Ð€¨€À¸ÐÔ¤(€€€‘É…Ý}É•Ð¡I•ÐÈ À°I=U9}d°]=I1}]%Q °€àÈ¤°É½Õ¹¤(€€€‘É…Ý}±¥¹”¡Y•Ñ½ÈÈ À°I=U9}d¤°Y•Ñ½ÈÈ¡]=I1}]%Q °I=U9}d¤°½±½È ˆŒÜÄàÀÔÄˆ¤¹‘…É­•¹•  Ä¸Àµ±¥¡Ð¤¨À¸Ð¤°€Ì¸À¤(€€€‘É…Ý}É•Ð¡I•ÐÈ À°€ÌÄÐ°]=I1}]%Q °€ÐØ¤°½±½È ˆŒÄàÈÌÅ˜ˆ¤¹±•ÉÀ¡½±½È ˆŒÈØÌÄÈàˆ¤°±¥¡Ð€¨€À¸È¤¤(€€€™½Èà¥¸É…¹” ´ÈÀ°€ÄÌÄÀ°€Ìà¤è(€€€€€€€Ù…ÈÍÑ½¹•}ä€èô€ÌÄØ¸À€¬™µ½¡™±½…Ð¡à€¨€ÄÄ€¬€ÐÌ¤°€ÄÜ¸À¤(€€€€€€€Ù…ÈÍÑ½¹•}½±½È€èô½±½È ˆŒÌÀÌàÌÌˆ¤¹±•ÉÀ¡½±½È ˆŒÐÔÑ„ÐÀˆ¤°±¥¡Ð€¨€À¸ÈÔ¤(€€€€€€€‘É…Ý}¥É±”¡Y•Ñ½ÈÈ¡à°ÍÑ½¹•}ä¤°€ÄÌ¸À€¬™µ½¡™±½…Ð¡à¤°€Ü¸À¤°ÍÑ½¹•}½±½È¤(€€€€€€€‘É…Ý}…ÉŒ¡Y•Ñ½ÈÈ¡à°ÍÑ½¹•}ä¤°€ÄÌ¸À°A$°QT°€à°ÍÑ½¹•}½±½È¹±¥¡Ñ•¹• À¸ÄÈ¤°€Ä¸Ì¤()™Õ¹Œ}‘É…Ý}™…É}™½É•ÍÐ ¤€´øÙ½¥è(€€€Ù…È¹¥¡Ñ}™…‘”€èô€ Ä¸À€´}‘…å±¥¡Ñ}…µ½Õ¹Ð ¤¤€¨€À¸ÌÔ(€€€™½Èà¥¸É…¹” ´ÄÀ°€ÄÌÀÀ°€ÈÜ¤è(€€€€€€€Ù…È¡•¥¡Ð€èô€ÈÔ¸À€¬™µ½¡™±½…Ð¡à€¨€ÄÌ€¬€Üä¤°€ÌÈ¸À¤(€€€€€€€}‘É…Ý}Á¥¹”¡Y•Ñ½ÈÈ¡à°I=U9}d€¬€È¤°¡•¥¡Ð°½±½È ˆŒÈÐÍ„ÌÈˆ¤¹‘…É­•¹•¡¹¥¡Ñ}™…‘”¤°Í¥¸¡Ù¥ÍÕ…±}Ñ¥µ”€¨€À¸ÈÈ€¬à¤€¨€À¸Ì¤(€€€}‘É…Ý}Á¥¹”¡Y•Ñ½ÈÈ àà°I=U9}d€¬€Ð¤°€ÄÄØ°½±½È ˆŒÄÜÉˆÈÌˆ¤°Í¥¸¡Ù¥ÍÕ…±}Ñ¥µ”€¨€À¸Äà¤€¨€À¸à¤(€€€}‘É…Ý}Á¥¹”¡Y•Ñ½ÈÈ ÄÄàÔ°I=U9}d€¬€Ð¤°€ÄÌÐ°½±½È ˆŒÄØÈäÈÀˆ¤°Í¥¸¡Ù¥ÍÕ…±}Ñ¥µ”€¨€À¸ÄÜ€¬€Ä¸À¤¤(€€€}‘É…Ý}Á¥¹”¡Y•Ñ½ÈÈ ÄÄÀÔ°I=U9}d€¬€È¤°€àÈ°½±½È ˆŒÅ”ÌÌÈÜˆ¤°Í¥¸¡Ù¥ÍÕ…±}Ñ¥µ”€¨€À¸È€¬€È¸À¤€¨€À¸Ü¤()™Õ¹Œ}‘É…Ý}Á¥¹”¡‰…Í”èY•Ñ½ÈÈ°¡•¥¡Ðè™±½…Ð°½±½Èè½±½È°ÍÝ…äè™±½…Ð¤€´øÙ½¥è(€€€‘É…Ý}É•Ð¡I•ÐÈ¡‰…Í”¹à€´€È°‰…Í”¹ä€´¡•¥¡Ð€¨€À¸ÐÈ°€Ð°¡•¥¡Ð€¨€À¸ÐÐ¤°½±½È ˆŒÐÐÌÌÈØˆ¤¤(€€€™½È±…å•È¥¸É…¹” Ð¤è(€€€€€€€Ù…Èä€èô‰…Í”¹ä€´¡•¥¡Ð€¬±…å•È€¨¡•¥¡Ð€¨€À¸Ää(€€€€€€€Ù…È¡…±˜€èô¡•¥¡Ð€¨€ À¸ÄÔ€¬±…å•È€¨€À¸ÀÔÔ¤(€€€€€€€‘É…Ý}½±½É•‘}Á½±å½¸¡A…­•‘Y•Ñ½ÈÉÉÉ…ä¡mY•Ñ½ÈÈ¡‰…Í”¹à€¬ÍÝ…ä±ä¤±Y•Ñ½ÈÈ¡‰…Í”¹àµ¡…±˜±ä­¡•¥¡Ð¨À¸ÌÐ¤±Y•Ñ½ÈÈ¡‰…Í”¹à­¡…±˜±ä­¡•¥¡Ð¨À¸ÌÐ¥t¤±½±½È¹±¥¡Ñ•¹•¡±…å•È¨À¸ÀÈÔ¤¤()™Õ¹Œ}‘É…Ý}Ñ•¹Ð ¤€´øÙ½¥è(€€€Ù…È…¹Ù…Ì€èô½±½È ˆ„àÜÌÑ˜ˆ¤¹‘…É­•¹•  Ä¸À€´}‘…å±¥¡Ñ}…µ½Õ¹Ð ¤¤€¨€À¸ÈÐ¤(€€€‘É…Ý}¥É±”¡Q9Q}A=L€¬Y•Ñ½ÈÈ À°´Èà¤°€ÔÐ°½±½È Ä¸À°À¸Ðà°À¸Äà°À¸ÀÌÔ¥˜}¥Í}¹¥¡Ð ¤•±Í”€À¸ÀÄ¤¤(€€€Ù…ÈÑ•¹Ð€èôA…­•‘Y•Ñ½ÈÉÉÉ…ä¡mY•Ñ½ÈÈ àÌÔ°ÈÜà¤±Y•Ñ½ÈÈ äÀÀ°ÈÀÔ¤±Y•Ñ½ÈÈ äÜÀ°ÈÜà¥t¤(€€€‘É…Ý}½±½É•‘}Á½±å½¸¡Ñ•¹Ð°…¹Ù…Ì¤(€€€‘É…Ý}Á½±å±¥¹”¡A…­•‘Y•Ñ½ÈÉÉÉ…ä¡mY•Ñ½ÈÈ àÌÔ°ÈÜà¤±Y•Ñ½ÈÈ äÀÀ°ÈÀÔ¤±Y•Ñ½ÈÈ äÜÀ°ÈÜà¥t¤°½±½È ˆŒØàÑ„ÌÔˆ¤°€Ð¸À¤(€€€‘É…Ý}±¥¹”¡Y•Ñ½ÈÈ äÀÀ°ÈÀÄ¤±Y•Ñ½ÈÈ äÀÀ°ÈàÀ¤±½±½È ˆŒÐäÌÐÈäˆ¤°Ì¸À¤(€€€‘É…Ý}½±½É•‘}Á½±å½¸¡A…­•‘Y•Ñ½ÈÉÉÉ…ä¡mY•Ñ½ÈÈ äÀÀ°ÈÜà¤±Y•Ñ½ÈÈ äÀÀ°ÈÌÈ¤±Y•Ñ½ÈÈ äÈä°ÈÜà¥t¤±½±½È ˆŒÍˆÌÀÉ„ˆ¤¤(€€€‘É…Ý}±¥¹”¡Y•Ñ½ÈÈ äÀÀ°ÈÀÔ¤°Y•Ñ½ÈÈ àÄà°ÈàÄ¤°½±½È ˆÁ„ÐÜÜˆ¤°€Ä¸Ô¤(€€€‘É…Ý}±¥¹”¡Y•Ñ½ÈÈ äÀÀ°ÈÀÔ¤°Y•Ñ½ÈÈ äàØ°ÈàÄ¤°½±½È ˆÁ„ÐÜÜˆ¤°€Ä¸Ô¤(€€€‘É…Ý}¥É±”¡Y•Ñ½ÈÈ àÄÜ°ÈàÄ¤°€È¸Ô°½±½È ˆŒåˆÜäÔàˆ¤¤(€€€‘É…Ý}¥É±”¡Y•Ñ½ÈÈ äàÜ°ÈàÄ¤°€È¸Ô°½±½È ˆŒåˆÜäÔàˆ¤¤()™Õ¹Œ}‘É…Ý}™¥É” ¤€´øÙ½¥è(€€€Ù…ÈÍÑÉ•¹Ñ €èô±…µÁ˜¡™¥É•}¡•…Ð°À¸À°Ä¸À¤(€€€¥˜ÍÑÉ•¹Ñ €ø€À¸ÀÌè(€€€€€€€™½ÈÉ…‘¥ÕÌ¥¸É…¹” ØÈ°ÈÀ°´Ø¤è(€€€€€€€€€€€‘É…Ý}¥É±”¡%I}A=L­Y•Ñ½ÈÈ À°Ü¤±É…‘¥ÕÌ©ÍÑÉ•¹Ñ ±½±½È Ä¸À°À¸ÐÈ°À¸Ä°À¸ÀÄÐ©ÍÑÉ•¹Ñ ¤¤(€€€Ù…ÈÉ½Õ¹‘}…¹¡½È€èô%I}A=L€¬Y•Ñ½ÈÈ À°Äà¤(€€€Ù…È‰…Í•}Í¥é”€èô%I}	M¹•Ñ}Í¥é” ¤(€€€‘É…Ý}Ñ•áÑÕÉ”¡%I}	M±É½Õ¹‘}…¹¡½ÈµY•Ñ½ÈÈ¡‰…Í•}Í¥é”¹à¨¸Ô±‰…Í•}Í¥é”¹ä¤¤(€€€¥˜ÍÑÉ•¹Ñ €ø€À¸ÀÌÔè(€€€€€€€Ù…È™±…µ”èQ•áÑÕÉ”É€ô15}I5Mm¥¹Ð¡Ù¥ÍÕ…±}Ñ¥µ”¨Ô¸À¤•15}I5L¹Í¥é” ¥t(€€€€€€€Ù…È™±…µ•}Í¥é”€èô™±…µ”¹•Ñ}Í¥é” ¤(€€€€€€€Ù…È™±…µ•}Í…±”€èô±•ÉÁ˜ À¸ÌÐ°Ä¸À±ÍÑÉ•¹Ñ ¤(€€€€€€€‘É…Ý}Í•Ñ}ÑÉ…¹Í™½É´¡É½Õ¹‘}…¹¡½ÈµY•Ñ½ÈÈ À°ÄÀ¤°À¸À±Y•Ñ½ÈÈ¡™±…µ•}Í…±”±™±…µ•}Í…±”¤¤(€€€€€€€‘É…Ý}Ñ•áÑÕÉ”¡™±…µ”±Y•Ñ½ÈÈ µ™±…µ•}Í¥é”¹à¨¸Ô°µ™±…µ•}Í¥é”¹ä¤¤(€€€€€€€‘É…Ý}Í•Ñ}ÑÉ…¹Í™½É´¡Y•Ñ½ÈÈ¹iI<°À¸À±Y•Ñ½ÈÈ¹=9¤(€€€Ù…ÈÍµ½­•}…µ½Õ¹Ð€èô±…µÁ˜¡™¥É•}Ý•Ñ¹•ÍÌ¨Ä¸Ð¬ Ä¸ÀµÍÑÉ•¹Ñ ¤¨À¸ÌÔ°À¸Àà°Ä¸À¤(€€€™½È¤¥¸É…¹” Ô¤è(€€€€€€€Ù…È±¥™”€èô™µ½¡Ù¥ÍÕ…±}Ñ¥µ”¨ À¸ÀÜ­™¥É•}Ý•Ñ¹•ÍÌ¨¸ÀÐ¤­™±½…Ð¡¤¤¨À¸È°Ä¸À¤(€€€€€€€Ù…ÈÍµ½­”€èôÉ½Õ¹‘}…¹¡½È­Y•Ñ½ÈÈ¡Í¥¸¡±¥™”¨Ô¸À­¤¤¨ÄÀ¸À°´ÈÔ¸Àµ±¥™”¨àÈ¸À¤(€€€€€€€‘É…Ý}¥É±”¡Íµ½­”° Ì¸À­±¥™”¨ÄÀ¸À¤©Íµ½­•}…µ½Õ¹Ð±½±½È À¸ØÈ°À¸ØÐ°À¸ØÐ° Ä¸Àµ±¥™”¤¨À¸Äà©Íµ½­•}…µ½Õ¹Ð¤¤(€€€¥˜ÍÑÉ•¹Ñ €ø€À¸ÀÔè(€€€€€€€™½È¤¥¸É…¹” Ø¤è(€€€€€€€€€€€Ù…È•µ‰•È€èô™µ½¡Ù¥ÍÕ…±}Ñ¥µ”¨À¸Ì­™±½…Ð¡¤¤¨À¸ÄØ°Ä¸À¤(€€€€€€€€€€€‘É…Ý}¥É±”¡%I}A=L­Y•Ñ½ÈÈ¡Í¥¸¡™±½…Ð¡¤¤¨à¸À¤¨ÄÈ¸À°´ÄÈµ•µ‰•È¨ÐÔ¤°Ä¸È±½±½È Ä¸À°À¸ØÔ°À¸Äà° Ä¸Àµ•µ‰•È¤©ÍÑÉ•¹Ñ ¤¤()™Õ¹Œ}‘É…Ý}…•¹Ð¡…•¹Ðè¥Ñ¥½¹…Éä¤€´øÙ½¥è(€€€Ù…ÈÁ½ÌèY•Ñ½ÈÈ€ô…•¹Ð¹Á½Ì(€€€Ù…ÈÍ±••Á¥¹œè‰½½°€ô…•¹Ð¹ÍÑ…Ñ”€ôô€‰Í±••Àˆ…¹Á½Ì¹‘¥ÍÑ…¹•}Ñ¼¡…•¹Ð¹Ñ…É•Ð¤€ð€à¸À(€€€Ù…Èµ½Ù¥¹œè‰½½°€ô…•¹Ð¹Á½Ì¹‘¥ÍÑ…¹•}Ñ¼¡…•¹Ð¹Ñ…É•Ð¤€ø€Ì¸À(€€€Ù…ÈÝ…±­}™É…µ”€èô¥¹Ð¡Ù¥ÍÕ…±}Ñ¥µ”€¨€ à¸À¥˜…•¹Ð¹‘½œ•±Í”€Ø¸À¤¤€”€Ð(€€€Ù…È‰É•…Ñ¡¥¹œ€èôÍ¥¸¡Ù¥ÍÕ…±}Ñ¥µ”€¨€ Ä¸È¥˜…•¹Ð¹‘½œ•±Í”€À¸ÜÔ¤€¬Á½Ì¹à€¨€À¸ÀÈ¤€¨€À¸à(€€€Á½Ì¹ä€¬ô€ ´Ä¸À¥˜µ½Ù¥¹œ…¹Ý…±­}™É…µ”€”€È€ôô€Ä•±Í”‰É•…Ñ¡¥¹œ¤(€€€Ù…ÈÑ•áÑÕÉ”èQ•áÑÕÉ”É(€€€Ù…ÈÁ½Í”€èô€‰¥‘±”ˆ(€€€¥˜…•¹Ð¹‘½œè(€€€€€€€¥˜Í±••Á¥¹œè(€€€€€€€€€€€Á½Í”€ô€‰Í±••Àˆ(€€€€€€€•±¥˜…•¹Ð¹ÍÑ…Ñ”€ôô€‰Í¥Ðˆè(€€€€€€€€€€€Á½Í”€ô€‰É•ÍÐˆ(€€€€€€€•±¥˜µ½Ù¥¹œè(€€€€€€€€€€€Á½Í”€ô€‰¥‘±”ˆ(€€€€€€€•±¥˜…•¹Ð¹ÍÑ…Ñ”€ôô€‰Í¡•±Ñ•Èˆè(€€€€€€€€€€€Á½Í”€ô€‰Í¥Ðˆ(€€€€€€€Ñ•áÑÕÉ”€ô5%1=}MAI%QMmÁ½Í•t(€€€€€€€¥˜µ½Ù¥¹œè(€€€€€€€€€€€Ñ•áÑÕÉ”€ô5%1=}]1-}I5MmÝ…±­}™É…µ•t(€€€•±Í”è(€€€€€€€¥˜Í±••Á¥¹œè(€€€€€€€€€€€Á½Í”€ô€‰Í±••Àˆ(€€€€€€€•±¥˜…•¹Ð¹ÍÑ…Ñ”€ôô€‰‰É•…­¥¹}‰É…¹ ˆè(€€€€€€€€€€€Ù…È…Ñ¡•É}ÁÉ½É•ÍÌ€èô±…µÁ˜  È¸àµ™±½…Ð¡…•¹Ð¹¥¹Ñ•É…Ñ¥½¸¤¤¼È¸à°À¸À°À¸äää¤(€€€€€€€€€€€Ù…È…Ñ¡•É}¥¹‘•à€èôµ¥¹¤ È±¥¹Ð¡…Ñ¡•É}ÁÉ½É•ÍÌ¨Ì¸À¤¤(€€€€€€€€€€€Ñ•áÑÕÉ”€ô9=I}Q!I}I5Mm…Ñ¡•É}¥¹‘•át¥˜…•¹Ð¹¹…µ”€ôô€‰9½É„ˆ•±Í”=QQ=}Q!I}I5Mm…Ñ¡•É}¥¹‘•át(€€€€€€€•±¥˜µ½Ù¥¹œè(€€€€€€€€€€€Á½Í”€ô€‰¥‘±”ˆ(€€€€€€€•±¥˜…•¹Ð¹ÍÑ…Ñ”€ôô€‰Í¥Ðˆè(€€€€€€€€€€€Á½Í”€ô€‰Í¥Ðˆ(€€€€€€€•±¥˜…•¹Ð¹ÍÑ…Ñ”€ôô€‰•…Ðˆè(€€€€€€€€€€€Á½Í”€ô€‰Í¥Ðˆ(€€€€€€€•±¥˜…•¹Ð¹ÍÑ…Ñ”¥¸l‰™••‘}™¥É”ˆ°‰…‘‘¥¹}Ý½½ˆ°‰É•±¥¡Ñ¥¹œ‰tè(€€€€€€€€€€€Á½Í”€ô€‰Ý…É´ˆ¥˜…•¹Ð¹¹…µ”€ôô€‰9½É„ˆ•±Í”€‰Ñ•¹ˆ(€€€€€€€¥˜Ñ•áÑÕÉ”€ôô¹Õ±°è(€€€€€€€€€€€Ñ•áÑÕÉ”€ô9=I}MAI%QMmÁ½Í•t¥˜…•¹Ð¹¹…µ”€ôô€‰9½É„ˆ•±Í”=QQ=}MAI%QMmÁ½Í•t(€€€€€€€¥˜µ½Ù¥¹œ…¹…•¹Ð¹ÍÑ…Ñ”€„ô€‰‰É•…­¥¹}‰É…¹ ˆè(€€€€€€€€€€€Ñ•áÑÕÉ”€ô9=I}]1-}I5MmÝ…±­}™É…µ•t¥˜…•¹Ð¹¹…µ”€ôô€‰9½É„ˆ•±Í”=QQ=}]1-}I5MmÝ…±­}™É…µ•t(€€€Ù…ÈÍ¡•±Ñ•É}…±Á¡„€èô€Ä¸À(€€€¥˜É…¥¹¥¹œ…¹…•¹Ð¹ÍÑ…Ñ”€ôô€‰Í¡•±Ñ•Èˆè(€€€€€€€Í¡•±Ñ•É}…±Á¡„€ô±…µÁ˜¡…•¹Ð¹Á½Ì¹‘¥ÍÑ…¹•}Ñ¼¡…•¹Ð¹Ñ…É•Ð¤€¼€ÈÀ¸À°À¸À°Ä¸À¤(€€€€€€€¥˜Í¡•±Ñ•É}…±Á¡„€ðô€À¸ÀÈè(€€€€€€€€€€€É•ÑÕÉ¸(€€€Ù…ÈÍÁÉ¥Ñ•}Í¥é”€èôÑ•áÑÕÉ”¹•Ñ}Í¥é” ¤(€€€Ù…È™±¥À€èô€´Ä¸À¥˜…•¹Ð¹™…¥¹œ€ð€À¸À…¹¹½ÐÍ±••Á¥¹œ•±Í”€Ä¸À(€€€‘É…Ý}Í•Ñ}ÑÉ…¹Í™½É´¡Á½Ì€¬Y•Ñ½ÈÈ À°€ÄÌ¤°€À¸À°Y•Ñ½ÈÈ¡™±¥À°Ä¸À¤¤(€€€‘É…Ý}Ñ•áÑÕÉ”¡Ñ•áÑÕÉ”°Y•Ñ½ÈÈ µÍÁÉ¥Ñ•}Í¥é”¹à€¨€À¸Ô°€µÍÁÉ¥Ñ•}Í¥é”¹ä¤±½±½È Ä°Ä°Ä±Í¡•±Ñ•É}…±Á¡„¤¤(€€€¥˜…•¹Ð¹…ÉÉå¥¹œ…¹µ½Ù¥¹œ…¹¹½Ð…•¹Ð¹‘½œè(€€€€€€€Ù…È‰Õ¹‘±•}Í¥é”€èô	I9!}	U91¹•Ñ}Í¥é” ¤(€€€€€€€‘É…Ý}Ñ•áÑÕÉ”¡	I9!}	U91±Y•Ñ½ÈÈ µ‰Õ¹‘±•}Í¥é”¹à¨¸Ô¬Ô°µ‰Õ¹‘±•}Í¥é”¹ä´ÈÌ¤±½±½È Ä°Ä°Ä±Í¡•±Ñ•É}…±Á¡„¤¤(€€€‘É…Ý}Í•Ñ}ÑÉ…¹Í™½É´¡Y•Ñ½ÈÈ¹iI<°À¸À±Y•Ñ½ÈÈ¹=9¤(€€€¥˜Í±••Á¥¹œè(€€€€€€€Ù…Èé}Á½Ì€èôÁ½Ì€¬Y•Ñ½ÈÈ¡ÍÁÉ¥Ñ•}Í¥é”¹à¨¸Èà°µÍÁÉ¥Ñ•}Í¥é”¹ä´Ì¤(€€€€€€€‘É…Ý}ÍÑÉ¥¹œ¡Q¡•µ•¹™…±±‰…­}™½¹Ð±é}Á½Ì°‰èˆ±!=I%i=9Q1}1%959Q}1P°´Ä°ÄÄ±½±½È Ä°Ä°À¸àØ°À¸Ôà¤¤()™Õ¹Œ}‘É…Ý}•±±¥ÁÍ•}Í¡…Á”¡•¹Ñ•ÈèY•Ñ½ÈÈ°É…‘¥¤èY•Ñ½ÈÈ°½±½Èè½±½È¤€´øÙ½¥è(€€€Ù…ÈÁ½¥¹ÑÌ€èôA…­•‘Y•Ñ½ÈÉÉÉ…ä ¤(€€€™½È¤¥¸É…¹” ÈÐ¤è(€€€€€€€Ù…È„€èôQT€¨™±½…Ð¡¤¤€¼€ÈÐ¸À(€€€€€€€Á½¥¹ÑÌ¹…ÁÁ•¹¡•¹Ñ•È€¬Y•Ñ½ÈÈ¡½Ì¡„¤©É…‘¥¤¹à±Í¥¸¡„¤©É…‘¥¤¹ä¤¤(€€€‘É…Ý}½±½É•‘}Á½±å½¸¡Á½¥¹ÑÌ±½±½È¤()™Õ¹Œ}‘É…Ý}É…¥¸ ¤€´øÙ½¥è(€€€Ù…ÈÐ€èôQ¥µ”¹•Ñ}Ñ¥­Í}µÍ•Œ ¤€¨€À¸ÈÔ(€€€™½È¤¥¸É…¹” ÜÔ¤è(€€€€€€€Ù…Èà€èô™µ½¡™±½…Ð¡¤€¨€àÌ¤€¬Ð°]=I1}]%Q €¬€ÐÀ¸À¤€´€ÈÀ¸À(€€€€€€€Ù…Èä€èô™µ½¡™±½…Ð¡¤€¨€ÐÜ¤€¬Ð€¨€Ä¸Ü°€ÌÄÔ¸À¤(€€€€€€€‘É…Ý}±¥¹”¡Y•Ñ½ÈÈ¡à±ä¤±Y•Ñ½ÈÈ¡à´Ü±ä¬ÄØ¤±½±½È À¸ÜÔ°À¸àØ°À¸äÈ°À¸Ðà¤°Ä¸È¤()™Õ¹Œ}‘É…Ý}±¥Ù¥¹}‘•Ñ…¥±Ì ¤€´øÙ½¥è(€€€™½Èà¥¸É…¹” ÐÈÀ°€àÜÔ°€ÌÄ¤è(€€€€€€€Ù…È‰…Í”€èôY•Ñ½ÈÈ¡à°€ÌÐÜ€¬™µ½¡™±½…Ð¡à¤°€Ô¸À¤¤(€€€€€€€Ù…ÈÍÝ…ä€èôÍ¥¸¡Ù¥ÍÕ…±}Ñ¥µ”€¨€À¸Ô€¬à€¨€À¸Àä¤€¨€Ä¸Ô(€€€€€€€‘É…Ý}±¥¹”¡‰…Í”±‰…Í”­Y•Ñ½ÈÈ¡ÍÝ…ä´È°´Ü¤±½±½È À¸ÌÐ°À¸Ðà°À¸ÈÔ°À¸ÜÔ¤°Ä¸À¤(€€€™½È¤¥¸É…¹” Ì¤è(€€€€€€€Ù…Èµ½Ñ”€èô™µ½¡Ù¥ÍÕ…±}Ñ¥µ”€¨€ À¸ÀÄà€¬¤¨¸ÀÀÐ¤€¬¤¨¸ÌÄ°Ä¸À¤(€€€€€€€‘É…Ý}¥É±”¡Y•Ñ½ÈÈ ÔÀÔ­¤¨ÄÈà€¬Í¥¸¡Ù¥ÍÕ…±}Ñ¥µ”¨¸Ü­¤¤¨ÄÈ°ÈàØµµ½Ñ”¨ÌÈ¤°Ä¸À±½±½È Ä¸À°À¸ÜÐ°À¸ÈÔ° Ä¸Àµµ½Ñ”¤¨¸ÐÔ¤¤(€€€¥˜}¥Í}¹¥¡Ð ¤è(€€€€€€€Ù…ÈÍÑ…É}å±”€èô™µ½¡Ù¥ÍÕ…±}Ñ¥µ”°ÈÌ¸À¤(€€€€€€€¥˜ÍÑ…É}å±”€ð€Ä¸Ðè(€€€€€€€€€€€Ù…ÈÍÑ…É}Á½Ì€èôY•Ñ½ÈÈ äÌÀ¸À­ÍÑ…É}å±”¨ÜÀ¸À°ÜØ¸À­ÍÑ…É}å±”¨ÈÈ¸À¤(€€€€€€€€€€€‘É…Ý}±¥¹”¡ÍÑ…É}Á½Ì±ÍÑ…É}Á½ÌµY•Ñ½ÈÈ Äà°Ø¤±½±½È À¸äÔ°À¸äÌ°À¸ÜØ°Ä¸ÀµÍÑ…É}å±”¼Ä¸Ð¤°Ä¸È¤(€€€•±¥˜¹½ÐÉ…¥¹¥¹œè(€€€€€€€Ù…È‰¥É‘}à€èô™µ½¡Ù¥ÍÕ…±}Ñ¥µ”¨ä¸À°ÄÐÔÀ¸À¤´àÀ¸À(€€€€€€€‘É…Ý}…ÉŒ¡Y•Ñ½ÈÈ¡‰¥É‘}à°äÈ¤°Ü±A$¬À¸È±QT´À¸È°Ü±½±½È À¸ÄØ°À¸ÈÀ°À¸ÈÌ°À¸ÔÔ¤°Ä¸Ä¤(€€€€€€€‘É…Ý}…ÉŒ¡Y•Ñ½ÈÈ¡‰¥É‘}à¬ÄÌ°äÈ¤°Ü±A$¬À¸È±QT´À¸È°Ü±½±½È À¸ÄØ°À¸ÈÀ°À¸ÈÌ°À¸ÔÔ¤°Ä¸Ä¤(€€€¥˜É…¥¹¥¹œè(€€€€€€€™½È¤¥¸É…¹” Ð¤è(€€€€€€€€€€€Ù…ÈÉ¥ÁÁ±”€èô™µ½¡Ù¥ÍÕ…±}Ñ¥µ”¨¸Ü­™±½…Ð¡¤¤¨¸ÈÐ°Ä¸À¤(€€€€€€€€€€€‘É…Ý}…ÉŒ¡Y•Ñ½ÈÈ ÌÔÀ­¤¨ÄäÀ°ÌÔÀ¤°Ì¸À­É¥ÁÁ±”¨ÄÌ¸À°À±QT°ÈÐ±½±½È À¸ØÔ°À¸Üà°À¸àÐ° Ä¸ÀµÉ¥ÁÁ±”¤¨¸ÌÔ¤°Ä¸À¤()™Õ¹Œ}‘É…Ý}™½É•É½Õ¹‘}‘•Ñ…¥±Ì ¤€´øÙ½¥è(€€€™½Èà¥¸É…¹” ÄÐ°€ÄÈÜÀ°€Äà¤è(€€€€€€€Ù…ÈÍÝ…ä€èôÍ¥¸¡Ù¥ÍÕ…±}Ñ¥µ”€¨€À¸Ðà€¬à€¨€À¸ÀÜ¤€¨€È¸È(€€€€€€€Ù…È‰…Í”€èôY•Ñ½ÈÈ¡à°I=U9}d€¬€à€¬™µ½¡™±½…Ð¡à€¨€Ü¤°€ÄÐ¸À¤¤(€€€€€€€‘É…Ý}±¥¹”¡‰…Í”°‰…Í”€¬Y•Ñ½ÈÈ ´Ì€¬ÍÝ…ä°€´ÄÄ€´™µ½¡™±½…Ð¡à¤°€Ü¸À¤¤°½±½È ˆŒØààÀÔÈˆ¤¹‘…É­•¹•  Ä¸Àµ}‘…å±¥¡Ñ}…µ½Õ¹Ð ¤¤¨¸Ð¤°€Ä¸Ð¤(€€€™½ÈÀ¥¸mY•Ñ½ÈÈ ÈàÀ°ÈàÔ¤±Y•Ñ½ÈÈ ÌÈØ°ÈäÀ¤±Y•Ñ½ÈÈ ÄÀÌà°ÈàØ¤±Y•Ñ½ÈÈ ÄÀàà°ÈäÈ¤±Y•Ñ½ÈÈ ÐÐÀ°ÈàÜ¥tè(€€€€€€€‘É…Ý}±¥¹”¡À±À­Y•Ñ½ÈÈ¡Í¥¸¡Ù¥ÍÕ…±}Ñ¥µ”¨¸Ð­À¹à¤¨Ä¸Ô°´ÄÀ¤±½±½È ˆŒÔÔÜÄÐÜˆ¤°Ä¸Ô¤(€€€€€€€‘É…Ý}¥É±”¡À­Y•Ñ½ÈÈ À°´ÄÈ¤°È¸È±½±½È ˆÑ„ÐÑ”ˆ¥˜¥¹Ð¡À¹à¤”Ì•±Í”€ˆåŒå„Ôˆ¤¤(€€€™½ÈÀ¥¸mY•Ñ½ÈÈ ÌàÔ°ÈäÌ¤±Y•Ñ½ÈÈ ÜäÔ°ÈäÈ¤±Y•Ñ½ÈÈ ÄÀÄÀ°Èää¥tè(€€€€€€€‘É…Ý}¥É±”¡À°à±½±½È ˆŒÍŒÐÔÐÀˆ¤¤(€€€€€€€‘É…Ý}…ÉŒ¡À°à±A$±QT°à±½±½È ˆŒØÐÙ„ØÀˆ¤°Ä¸Ì¤(€€€€Œ¥É”É¥¹œ°Í•…ÑÌ…¹„™•Ü±¥Ù•µ¥¸…µÀÑÉ…•Ì¸(€€€™½È…¹±”¥¸É…¹” À°€ÌØÀ°€ÐÔ¤è(€€€€€€€Ù…ÈÉ…€èô‘•}Ñ½}É…¡™±½…Ð¡…¹±”¤¤(€€€€€€€Ù…ÈÉ½¬€èô%I}A=L€¬Y•Ñ½ÈÈ¡½Ì¡É…¤€¨€ÈÐ¸À°€ÄÜ¸À€¬Í¥¸¡É…¤€¨€Ü¸À¤(€€€€€€€‘É…Ý}¥É±”¡É½¬°€Ð¸Ô°½±½È ˆŒÕˆÕ„ÑŒˆ¤¤(€€€‘É…Ý}±¥¹”¡Y•Ñ½ÈÈ ÔÔÔ°ÈàØ¤°Y•Ñ½ÈÈ ØÀà°Èàä¤°½±½È ˆŒÕ„ÌäÈÔˆ¤°€ÄÀ¸À¤(€€€‘É…Ý}¥É±”¡Y•Ñ½ÈÈ ØÀà°Èàä¤°€Ô¸À°½±½È ˆ„ÀÜÄÐÌˆ¤¤(€€€‘É…Ý}±¥¹”¡Y•Ñ½ÈÈ ÜÀØ°ÈäÄ¤°Y•Ñ½ÈÈ ÜÔÄ°ÈàÜ¤°½±½È ˆŒÔÌÌÔÈÌˆ¤°€ä¸À¤(€€€‘É…Ý}¥É±”¡Y•Ñ½ÈÈ ÜÀØ°ÈäÄ¤°€Ð¸Ô°½±½È ˆŒäÔØàÍ˜ˆ¤¤(€€€™½Èà¥¸lÈÀÔ°€ÈÈÌ°€ÄÀàÈ°€ÄÄÀÁtè(€€€€€€€‘É…Ý}±¥¹”¡Y•Ñ½ÈÈ¡à°ÈäÈ¤±Y•Ñ½ÈÈ¡à¬ÄÜ°ÈàÈ¤±½±½È ˆŒÜÈÔÀÌàˆ¤°Ì¸À¤()™Õ¹Œ}‘É…Ý}Ý¡¥ÍÁ•É}Ñ•áÐ ¤€´øÙ½¥è(€€€¥˜ÍÑ½Éå}Ñ¥µ•È€ðô€À¸Àè(€€€€€€€É•ÑÕÉ¸(€€€Ù…È…±Á¡„€èô±…µÁ˜¡ÍÑ½Éå}Ñ¥µ•È€¼€È¸À°À¸À°Ä¸À¤(€€€Ù…ÈÑ•áÐ€èô€‰…œ€•€ƒ
Ü€€•Ìˆ€”m‘…å}¹Õµ‰•È°ÍÑ½Éå}±¥¹•t(€€€Ù…ÈÝ¥‘Ñ €èôQ¡•µ•¹™…±±‰…­}™½¹Ð¹•Ñ}ÍÑÉ¥¹}Í¥é”¡Ñ•áÐ±!=I%i=9Q1}1%959Q}1P°´Ä°ÄØ¤¹à(€€€‘É…Ý}ÍÑÉ¥¹œ¡Q¡•µ•¹™…±±‰…­}™½¹Ð±Y•Ñ½ÈÈ ¡]=I1}]%Q µÝ¥‘Ñ ¤¨À¸Ô°ÌÈ¤±Ñ•áÐ±!=I%i=9Q1}1%959Q}1P°´Ä°ÄØ±½±½È À¸äØ°À¸äÐ°À¸àÔ±…±Á¡„¤¤()™Õ¹Œ}Í…Ù•}Ý½É± ¤€´øÙ½¥è(€€€Ù…È™œ€èô½¹™¥¥±”¹¹•Ü ¤(€€€™œ¹Í•Ñ}Ù…±Õ” ‰Ý½É±ˆ°‰Ñ¥µ”ˆ±Ý½É±‘}Ñ¥µ”¤(€€€™œ¹Í•Ñ}Ù…±Õ” ‰Ý½É±ˆ°‰‘…äˆ±‘…å}¹Õµ‰•È¤(€€€™œ¹Í•Ñ}Ù…±Õ” ‰Ý½É±ˆ°‰™¥É•}™Õ•°ˆ±™¥É•}™Õ•°¤(€€€™œ¹Í•Ñ}Ù…±Õ” ‰Ý½É±ˆ°‰™¥É•}¡•…Ðˆ±™¥É•}¡•…Ð¤(€€€™œ¹Í•Ñ}Ù…±Õ” ‰Ý½É±ˆ°‰™¥É•}Ý•Ñ¹•ÍÌˆ±™¥É•}Ý•Ñ¹•ÍÌ¤(€€€™œ¹Í•Ñ}Ù…±Õ” ‰Ý½É±ˆ°‰ÍÑ½É•‘}‰É…¹¡•Ìˆ±ÍÑ½É•‘}‰É…¹¡•Ì¤(€€€™½È¤¥¸É…¹”¡‰É…¹¡}Í½ÕÉ•Ì¹Í¥é” ¤¤è(€€€€€€€™œ¹Í•Ñ}Ù…±Õ” ‰Ý½É±ˆ°‰‰É…¹¡|•ˆ€”¤±™±½…Ð¡‰É…¹¡}Í½ÕÉ•Ím¥t¹…µ½Õ¹Ð¤¤(€€€™œ¹Í•Ñ}Ù…±Õ” ‰Ý½É±ˆ°‰Õ¹¥á}Ñ¥µ”ˆ±Q¥µ”¹•Ñ}Õ¹¥á}Ñ¥µ•}™É½µ}ÍåÍÑ•´ ¤¤(€€€™œ¹Í•Ñ}Ù…±Õ” ‰ÍÑ½Éäˆ°‰¹½É…}½ÑÑ½}‰½¹ˆ±¹½É…}½ÑÑ½}‰½¹¤(€€€™œ¹Í•Ñ}Ù…±Õ” ‰ÍÑ½Éäˆ°‰µ¥±½}…ÑÑ…¡µ•¹Ðˆ±µ¥±½}…ÑÑ…¡µ•¹Ð¤(€€€™œ¹Í•Ñ}Ù…±Õ” ‰ÍÑ½Éäˆ°‰•Ù•¹Ñ}¡¥ÍÑ½Éäˆ±•Ù•¹Ñ}¡¥ÍÑ½Éä¤(€€€™œ¹Í•Ñ}Ù…±Õ” ‰ÍÑ½Éäˆ°‰É•µ•µ‰•É•‘}µ½µ•¹ÑÌˆ±É•µ•µ‰•É•‘}µ½µ•¹ÑÌ¤(€€€™½È¤¥¸É…¹”¡…•¹ÑÌ¹Í¥é” ¤¤è(€€€€€€€™œ¹Í•Ñ}Ù…±Õ” ‰…•¹Ñ|•ˆ€”¤°‰Á½Í¥Ñ¥½¸ˆ±…•¹ÑÍm¥t¹Á½Ì¤(€€€€€€€™œ¹Í•Ñ}Ù…±Õ” ‰…•¹Ñ|•ˆ€”¤°‰•¹•Éäˆ±…•¹ÑÍm¥t¹•¹•Éä¤(€€€€€€€™œ¹Í•Ñ}Ù…±Õ” ‰…•¹Ñ|•ˆ€”¤°‰¡Õ¹•Èˆ±…•¹ÑÍm¥t¹¡Õ¹•È¤(€€€™œ¹Í…Ù”¡MY}AQ ¤()™Õ¹Œ}±½…‘}Ý½É± ¤€´øÙ½¥è(€€€Ù…È™œ€èô½¹™¥¥±”¹¹•Ü ¤(€€€¥˜™œ¹±½…¡MY}AQ ¤€„ô=,è(€€€€€€€É•ÑÕÉ¸(€€€Ý½É±‘}Ñ¥µ”€ô™±½…Ð¡™œ¹•Ñ}Ù…±Õ” ‰Ý½É±ˆ°‰Ñ¥µ”ˆ±Ý½É±‘}Ñ¥µ”¤¤(€€€‘…å}¹Õµ‰•È€ô¥¹Ð¡™œ¹•Ñ}Ù…±Õ” ‰Ý½É±ˆ°‰‘…äˆ±‘…å}¹Õµ‰•È¤¤(€€€™¥É•}™Õ•°€ô™±½…Ð¡™œ¹•Ñ}Ù…±Õ” ‰Ý½É±ˆ°‰™¥É•}™Õ•°ˆ±™¥É•}™Õ•°¤¤(€€€™¥É•}¡•…Ð€ô™±½…Ð¡™œ¹•Ñ}Ù…±Õ” ‰Ý½É±ˆ°‰™¥É•}¡•…Ðˆ±™¥É•}¡•…Ð¤¤(€€€™¥É•}Ý•Ñ¹•ÍÌ€ô™±½…Ð¡™œ¹•Ñ}Ù…±Õ” ‰Ý½É±ˆ°‰™¥É•}Ý•Ñ¹•ÍÌˆ±™¥É•}Ý•Ñ¹•ÍÌ¤¤(€€€ÍÑ½É•‘}‰É…¹¡•Ì€ô¥¹Ð¡™œ¹•Ñ}Ù…±Õ” ‰Ý½É±ˆ°‰ÍÑ½É•‘}‰É…¹¡•Ìˆ±ÍÑ½É•‘}‰É…¹¡•Ì¤¤(€€€™½È¤¥¸É…¹”¡‰É…¹¡}Í½ÕÉ•Ì¹Í¥é” ¤¤è(€€€€€€€‰É…¹¡}Í½ÕÉ•Ím¥t¹…µ½Õ¹Ð€ô™±½…Ð¡™œ¹•Ñ}Ù…±Õ” ‰Ý½É±ˆ°‰‰É…¹¡|•ˆ€”¤±‰É…¹¡}Í½ÕÉ•Ím¥t¹…µ½Õ¹Ð¤¤(€€€¹½É…}½ÑÑ½}‰½¹€ô™±½…Ð¡™œ¹•Ñ}Ù…±Õ” ‰ÍÑ½Éäˆ°‰¹½É…}½ÑÑ½}‰½¹ˆ±¹½É…}½ÑÑ½}‰½¹¤¤(€€€µ¥±½}…ÑÑ…¡µ•¹Ð€ô™œ¹•Ñ}Ù…±Õ” ‰ÍÑ½Éäˆ°‰µ¥±½}…ÑÑ…¡µ•¹Ðˆ±µ¥±½}…ÑÑ…¡µ•¹Ð¤(€€€Ù…È±½…‘•‘}¡¥ÍÑ½ÉäèÉÉ…ä€ô™œ¹•Ñ}Ù…±Õ” ‰ÍÑ½Éäˆ°‰•Ù•¹Ñ}¡¥ÍÑ½Éäˆ±mt¤(€€€•Ù•¹Ñ}¡¥ÍÑ½Éä¹…ÍÍ¥¸¡±½…‘•‘}¡¥ÍÑ½Éä¤(€€€É•µ•µ‰•É•‘}µ½µ•¹ÑÌ€ô™œ¹•Ñ}Ù…±Õ” ‰ÍÑ½Éäˆ°‰É•µ•µ‰•É•‘}µ½µ•¹ÑÌˆ±É•µ•µ‰•É•‘}µ½µ•¹ÑÌ¤(€€€Ù…ÈÑ¡•¸€èô¥¹Ð¡™œ¹•Ñ}Ù…±Õ” ‰Ý½É±ˆ°‰Õ¹¥á}Ñ¥µ”ˆ±Q¥µ”¹•Ñ}Õ¹¥á}Ñ¥µ•}™É½µ}ÍåÍÑ•´ ¤¤¤(€€€Ù…È•±…ÁÍ•€èô±…µÁ¤¡¥¹Ð¡Q¥µ”¹•Ñ}Õ¹¥á}Ñ¥µ•}™É½µ}ÍåÍÑ•´ ¤¤€´Ñ¡•¸°À°àØÐÀÀ€¨€Ü¤(€€€Ý½É±‘}Ñ¥µ”€¬ô™±½…Ð¡•±…ÁÍ•¤€¼e}M=9L(€€€‘…å}¹Õµ‰•È€¬ô¥¹Ð¡™±½½È¡Ý½É±‘}Ñ¥µ”¤¤(€€€Ý½É±‘}Ñ¥µ”€ô™µ½¡Ý½É±‘}Ñ¥µ”°Ä¸À¤(€€€™¥É•}™Õ•°€ôµ…á˜ À¸À±™¥É•}™Õ•°µ•±…ÁÍ•¨¸ÀÀÀÜ¤(€€€™¥É•}¡•…Ð€ôµ¥¹˜¡™¥É•}¡•…Ð±±…µÁ˜¡™¥É•}™Õ•°¼Ð¸À°À¸À°Ä¸À¤¤(€€€™½È¤¥¸É…¹”¡…•¹ÑÌ¹Í¥é” ¤¤è(€€€€€€€…•¹ÑÍm¥t¹Á½Ì€ô™œ¹•Ñ}Ù…±Õ” ‰…•¹Ñ|•ˆ€”¤°‰Á½Í¥Ñ¥½¸ˆ±…•¹ÑÍm¥t¹Á½Ì¤(€€€€€€€¥˜…•¹ÑÍm¥t¹Á½Ì¹ä€ðI=U9}d€´€Äà¸Àè(€€€€€€€€€€€…•¹ÑÍm¥t¹Á½Ì¹ä€ôI=U9}d€¬€ Ü¸À¥˜…•¹ÑÍm¥t¹‘½œ•±Í”€À¸À¤(€€€€€€€…•¹ÑÍm¥t¹Ñ…É•Ð€ô…•¹ÑÍm¥t¹Á½Ì(€€€€€€€…•¹ÑÍm¥t¹•¹•Éä€ô™±½…Ð¡™œ¹•Ñ}Ù…±Õ” ‰…•¹Ñ|•ˆ€”¤°‰•¹•Éäˆ±…•¹ÑÍm¥t¹•¹•Éä¤¤(€€€€€€€…•¹ÑÍm¥t¹¡Õ¹•È€ô™±½…Ð¡™œ¹•Ñ}Ù…±Õ” ‰…•¹Ñ|•ˆ€”¤°‰¡Õ¹•Èˆ±…•¹ÑÍm¥t¹¡Õ¹•È¤¤(€€€}Í…ä ‰Y•É‘•¸¡…È±•Ù•ÐÙ¥‘•É”°µ•¹Ì‘ÔÙ…ÈÛ™¬¸ˆ¤(