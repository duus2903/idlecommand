extends Node2D

const SAVE_PATH := "user://idlecommand_save.cfg"
const WORLD_WIDTH := 1280.0
const GROUND_Y := 278.0
const DAY_SECONDS := 180.0
const FIRE_POS := Vector2(650, 260)
const TENT_POS := Vector2(900, 250)
const BRANCH_POSITIONS := [Vector2(210, 265), Vector2(330, 267), Vector2(1080, 266)]

var world_time := 0.30
var day_number := 1
var raining := false
var weather_timer := 32.0
var fire_fuel := 5.0
var story_line := "Lejren vågner stille."
var story_timer := 0.0
var agents: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.randomize()
    agents = [
        _make_agent("Nora", Vector2(520, GROUND_Y), Color("#d17a74"), false),
        _make_agent("Otto", Vector2(760, GROUND_Y), Color("#7fa6c9"), false),
        _make_agent("Milo", Vector2(700, GROUND_Y + 7), Color("#b99062"), true)
    ]
    _load_world()
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
        "facing": 1.0
    }

func _process(delta: float) -> void:
    _advance_time(delta)
    _advance_weather(delta)
    _advance_fire(delta)
    _advance_agents(delta)
    story_timer = maxf(0.0, story_timer - delta)
    queue_redraw()

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
        _say("Regnen stilner af. Dråberne hænger endnu i græsset.")
    else:
        raining = rng.randf() < 0.42
        weather_timer = rng.randf_range(22.0, 55.0)
        if raining:
            _say("En stille regn glider ind over lejren.")

func _advance_fire(delta: float) -> void:
    var night := _is_night()
    if night and fire_fuel > 0.0:
        fire_fuel = maxf(0.0, fire_fuel - delta * 0.018)
    elif not night:
        fire_fuel = maxf(0.0, fire_fuel - delta * 0.004)

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
        elif agent.decision <= 0.0:
            _choose_action(i)

        _apply_arrival(i, delta)
        agents[i] = agent

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
        var person_index := rng.randi_range(0, 1)
        agent.state = "follow"
        agent.target = agents[person_index].pos + Vector2(rng.randf_range(-35, 35), 5)
    elif fire_fuel < 3.2 and not agent.carrying:
        agent.state = "gather"
        agent.target = BRANCH_POSITIONS[rng.randi_range(0, BRANCH_POSITIONS.size() - 1)]
    elif agent.carrying:
        agent.state = "feed_fire"
        agent.target = FIRE_POS + Vector2(rng.randf_range(-30, 30), 8)
    elif _is_night() or rng.randf() < 0.45:
        agent.state = "sit"
        agent.target = FIRE_POS + Vector2(-58 if index == 0 else 58, 9)
    else:
        agent.state = "wander"
        agent.target = Vector2(rng.randf_range(120, 1160), GROUND_Y)

    agents[index] = agent

func _apply_arrival(index: int, delta: float) -> void:
    var agent := agents[index]
    if agent.pos.distance_to(agent.target) > 5.0:
        return

    match agent.state:
        "gather":
            agent.carrying = true
            agent.state = "feed_fire"
            agent.target = FIRE_POS + Vector2(rng.randf_range(-26, 26), 8)
            agent.decision = 3.0
            _say("%s finder nogle tørre grene." % agent.name)
        "feed_fire":
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
        "shelter":
            agent.energy = minf(1.0, agent.energy + delta * 0.008)
        _:
            pass
    agents[index] = agent

func _is_night() -> bool:
    return world_time < 0.22 or world_time > 0.76

func _say(text: String) -> void:
    story_line = text
    story_timer = 8.0

func _draw() -> void:
    _draw_sky()
    _draw_landscape()
    _draw_tent()
    _draw_fire()
    for agent in agents:
        _draw_agent(agent)
    if raining:
        _draw_rain()
    _draw_whisper_text()

func _draw_sky() -> void:
    var daylight := _daylight_amount()
    var night_color := Color("#101729")
    var day_color := Color("#8bb8c9")
    var sky := night_color.lerp(day_color, daylight)
    draw_rect(Rect2(0, 0, WORLD_WIDTH, 360), sky)

    var sun_x := world_time * WORLD_WIDTH
    var arc := sin(world_time * PI)
    var body_y := 210.0 - arc * 150.0
    if _is_night():
        draw_circle(Vector2(sun_x, body_y), 18, Color("#d8dfd5"))
        for p in [Vector2(110,55),Vector2(240,95),Vector2(420,48),Vector2(790,80),Vector2(1040,45),Vector2(1180,110)]:
            draw_circle(p, 1.8, Color("#e6e5cf"))
    else:
        draw_circle(Vector2(sun_x, body_y), 22, Color("#f5d789"))

func _daylight_amount() -> float:
    return clampf(sin(world_time * PI), 0.0, 1.0)

func _draw_landscape() -> void:
    var far := Color("#526f68").darkened((1.0 - _daylight_amount()) * 0.45)
    var ground := Color("#405a3d").darkened((1.0 - _daylight_amount()) * 0.42)
    var hills := PackedVector2Array([Vector2(0,235),Vector2(160,175),Vector2(350,224),Vector2(560,165),Vector2(790,218),Vector2(1010,174),Vector2(1280,225),Vector2(1280,360),Vector2(0,360)])
    draw_colored_polygon(hills, far)
    draw_rect(Rect2(0, GROUND_Y, WORLD_WIDTH, 82), ground)
    for x in range(20, 1280, 34):
        var sway := sin(Time.get_ticks_msec() * 0.001 + x) * 3.0
        draw_line(Vector2(x, GROUND_Y + 8), Vector2(x + sway, GROUND_Y - 5), Color("#78906a"), 2.0)

func _draw_tent() -> void:
    var canvas := Color("#a87d56").darkened((1.0 - _daylight_amount()) * 0.25)
    var tent := PackedVector2Array([Vector2(835,278),Vector2(900,205),Vector2(970,278)])
    draw_colored_polygon(tent, canvas)
    draw_polyline(PackedVector2Array([Vector2(835,278),Vector2(900,205),Vector2(970,278)]), Color("#684a35"), 4.0)
    draw_line(Vector2(900,205),Vector2(900,278),Color("#684a35"),3.0)
    draw_colored_polygon(PackedVector2Array([Vector2(900,278),Vector2(900,232),Vector2(929,278)]),Color("#3b302a"))

func _draw_fire() -> void:
    draw_line(FIRE_POS + Vector2(-19,11), FIRE_POS + Vector2(18,20), Color("#4a2d20"), 6.0)
    draw_line(FIRE_POS + Vector2(19,11), FIRE_POS + Vector2(-18,20), Color("#4a2d20"), 6.0)
    if fire_fuel <= 0.15:
        return
    var flicker := sin(Time.get_ticks_msec() * 0.012) * 3.0
    var strength := clampf(fire_fuel / 5.0, 0.35, 1.0)
    draw_circle(FIRE_POS + Vector2(0, -4), 30 * strength, Color(1.0,0.55,0.2,0.10))
    draw_colored_polygon(PackedVector2Array([FIRE_POS+Vector2(-13,12),FIRE_POS+Vector2(-5,-22-flicker),FIRE_POS+Vector2(2,-7),FIRE_POS+Vector2(10,-31+flicker),FIRE_POS+Vector2(15,12)]),Color("#e98232"))
    draw_colored_polygon(PackedVector2Array([FIRE_POS+Vector2(-7,12),FIRE_POS+Vector2(0,-14+flicker),FIRE_POS+Vector2(8,12)]),Color("#f5d36a"))

func _draw_agent(agent: Dictionary) -> void:
    var pos: Vector2 = agent.pos
    var sleeping := agent.state == "sleep" and pos.distance_to(agent.target) < 8.0
    if agent.dog:
        draw_ellipse(pos + Vector2(0, -8), Vector2(15, 9), agent.color)
        draw_circle(pos + Vector2(13 * agent.facing, -13), 7, agent.color)
        draw_line(pos + Vector2(-13 * agent.facing,-11), pos + Vector2(-22 * agent.facing,-20), agent.color, 3.0)
        if not sleeping:
            draw_circle(pos + Vector2(16 * agent.facing,-14),1.5,Color("#1d1c18"))
    else:
        draw_line(pos + Vector2(-5,0),pos + Vector2(-7,13),Color("#342b29"),4.0)
        draw_line(pos + Vector2(5,0),pos + Vector2(7,13),Color("#342b29"),4.0)
        draw_rect(Rect2(pos + Vector2(-10,-30),Vector2(20,31)),agent.color)
        draw_circle(pos + Vector2(0,-40),10,Color("#e2b28e"))
        draw_arc(pos + Vector2(0,-43),11,PI,TAU,12,Color("#51372d"),5.0)
        if agent.carrying:
            draw_line(pos+Vector2(-14,-16),pos+Vector2(-28,-28),Color("#5e4028"),4.0)
    if sleeping:
        draw_string(ThemeDB.fallback_font,pos+Vector2(14,-45),"z",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color(1,1,1,0.65))

func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
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
    cfg.set_value("world","unix_time",Time.get_unix_time_from_system())
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
    var then := int(cfg.get_value("world","unix_time",Time.get_unix_time_from_system()))
    var elapsed := clampi(int(Time.get_unix_time_from_system()) - then,0,86400 * 7)
    world_time += float(elapsed) / DAY_SECONDS
    day_number += int(floor(world_time))
    world_time = fmod(world_time,1.0)
    fire_fuel = maxf(0.5,fire_fuel - elapsed * 0.0007)
    for i in range(agents.size()):
        agents[i].pos = cfg.get_value("agent_%d" % i,"position",agents[i].pos)
        agents[i].target = agents[i].pos
        agents[i].energy = float(cfg.get_value("agent_%d" % i,"energy",agents[i].energy))
        agents[i].hunger = float(cfg.get_value("agent_%d" % i,"hunger",agents[i].hunger))
    _say("Verden har levet videre, mens du var væk.")
