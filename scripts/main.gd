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
var visual_time := 0.0
var capture_requested := false
var capture_finished := false

func _ready() -> void:
    rng.randomize()
    agents = [
        _make_agent("Nora", Vector2(520, GROUND_Y), Color("#d17a74"), false),
        _make_agent("Otto", Vector2(760, GROUND_Y), Color("#7fa6c9"), false),
        _make_agent("Milo", Vector2(700, GROUND_Y + 7), Color("#b99062"), true)
    ]
    _load_world()
    capture_requested = "--capture" in OS.get_cmdline_user_args()
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
    visual_time += delta
    _advance_time(delta)
    _advance_weather(delta)
    _advance_fire(delta)
    _advance_agents(delta)
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
            agents[i] = agent
            _choose_action(i)
            agent = agents[i]

        agents[i] = agent
        _apply_arrival(i, delta)

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
    _draw_far_forest()
    _draw_tent()
    _draw_fire()
    for agent in agents:
        _draw_agent(agent)
    if raining:
        _draw_rain()
    _draw_foreground_details()
    _draw_whisper_text()

func _draw_sky() -> void:
    var daylight := _daylight_amount()
    var night_top := Color("#121b30")
    var day_top := Color("#6f91ad")
    var top := night_top.lerp(day_top, daylight)
    var night_horizon := Color("#26304a")
    var day_horizon := Color("#e6a27f")
    var horizon := night_horizon.lerp(day_horizon, daylight)
    for y in range(0, 282, 3):
        var blend := smoothstep(0.0, 1.0, float(y) / 282.0)
        draw_rect(Rect2(0, y, WORLD_WIDTH, 4), top.lerp(horizon, blend))

    var sun_x := world_time * WORLD_WIDTH
    var arc := sin(world_time * PI)
    var body_y := 210.0 - arc * 150.0
    if _is_night():
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
    draw_line(FIRE_POS + Vector2(-19,11), FIRE_POS + Vector2(18,20), Color("#4a2d20"), 6.0)
    draw_line(FIRE_POS + Vector2(19,11), FIRE_POS + Vector2(-18,20), Color("#4a2d20"), 6.0)
    if fire_fuel <= 0.15:
        return
    var flicker := sin(visual_time * 12.0) * 3.0 + sin(visual_time * 19.0) * 1.5
    var strength := clampf(fire_fuel / 5.0, 0.35, 1.0)
    for radius in range(62, 20, -6):
        draw_circle(FIRE_POS + Vector2(0, -3), radius * strength, Color(1.0,0.42,0.1,0.012))
    draw_colored_polygon(PackedVector2Array([FIRE_POS+Vector2(-13,12),FIRE_POS+Vector2(-5,-22-flicker),FIRE_POS+Vector2(2,-7),FIRE_POS+Vector2(10,-31+flicker),FIRE_POS+Vector2(15,12)]),Color("#e98232"))
    draw_colored_polygon(PackedVector2Array([FIRE_POS+Vector2(-7,12),FIRE_POS+Vector2(0,-14+flicker),FIRE_POS+Vector2(8,12)]),Color("#f5d36a"))
    for i in range(5):
        var life := fmod(visual_time * 0.10 + float(i) * 0.2, 1.0)
        var smoke := FIRE_POS + Vector2(sin(life * 5.0 + i) * 8.0, -30.0 - life * 86.0)
        draw_circle(smoke, 4.0 + life * 8.0, Color(0.72,0.68,0.62,(1.0-life)*0.13))
    for i in range(6):
        var ember := fmod(visual_time * 0.3 + float(i) * 0.16, 1.0)
        draw_circle(FIRE_POS + Vector2(sin(float(i)*8.0)*12.0,-20-ember*45),1.2,Color(1.0,0.65,0.18,1.0-ember))

func _draw_agent(agent: Dictionary) -> void:
    var pos: Vector2 = agent.pos
    var sleeping: bool = agent.state == "sleep" and pos.distance_to(agent.target) < 8.0
    var breathing := sin(visual_time * (1.2 if agent.dog else 0.75) + pos.x * 0.02) * 0.8
    pos.y += breathing
    if agent.dog:
        _draw_ellipse_shape(pos + Vector2(0, -8), Vector2(15, 9), agent.color)
        draw_circle(pos + Vector2(13 * agent.facing, -13), 7, agent.color)
        var tail_wag := sin(visual_time * 2.2) * (5.0 if agent.state == "follow" else 2.0)
        draw_line(pos + Vector2(-13 * agent.facing,-11), pos + Vector2((-22-tail_wag) * agent.facing,-20), agent.color, 3.0)
        if not sleeping:
            draw_circle(pos + Vector2(16 * agent.facing,-14),1.5,Color("#1d1c18"))
    else:
        draw_line(pos + Vector2(-5,0),pos + Vector2(-7,13),Color("#342b29"),4.0)
        draw_line(pos + Vector2(5,0),pos + Vector2(7,13),Color("#342b29"),4.0)
        draw_rect(Rect2(pos + Vector2(-10,-30),Vector2(20,31)),agent.color)
        draw_circle(pos + Vector2(0,-40),10,Color("#e2b28e"))
        draw_arc(pos + Vector2(0,-43),11,PI,TAU,12,Color("#51372d"),5.0)
        draw_circle(pos + Vector2(-3 * agent.facing,-40),1.0,Color("#2a211e"))
        if agent.carrying:
            draw_line(pos+Vector2(-14,-16),pos+Vector2(-28,-28),Color("#5e4028"),4.0)
    if sleeping:
        draw_string(ThemeDB.fallback_font,pos+Vector2(14,-45),"z",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color(1,1,1,0.65))

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

