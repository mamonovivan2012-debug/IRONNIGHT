extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const MonsterScript = preload("res://scripts/monster.gd")
const HUDScript = preload("res://scripts/hud.gd")

var player: CharacterBody3D
var hud: CanvasLayer
var wave := 1
var kills := 0
var spawn_timer := 0.0
var alive_to_spawn := 0
var game_over := false
var arena_radius := 34.0

func _ready() -> void:
    _build_world()
    player = CharacterBody3D.new()
    player.set_script(PlayerScript)
    player.name = "Player"
    add_child(player)
    player.position = Vector3(0, 1.2, 8)
    player.health_changed.connect(_on_health_changed)
    player.died.connect(_on_player_died)
    hud = CanvasLayer.new()
    hud.set_script(HUDScript)
    add_child(hud)
    hud.bind_game(self, player)
    _start_wave()

func _process(delta: float) -> void:
    if game_over:
        return
    if alive_to_spawn > 0:
        spawn_timer -= delta
        if spawn_timer <= 0.0:
            _spawn_monster()
            alive_to_spawn -= 1
            spawn_timer = max(0.55, 1.7 - wave * 0.07)
    if get_tree().get_nodes_in_group("monsters").is_empty() and alive_to_spawn == 0:
        await get_tree().create_timer(2.0).timeout
        if not game_over and get_tree().get_nodes_in_group("monsters").is_empty() and alive_to_spawn == 0:
            wave += 1
            _start_wave()

func _start_wave() -> void:
    alive_to_spawn = mini(3 + wave * 2, 18)
    spawn_timer = 0.8
    if is_instance_valid(hud):
        hud.set_wave(wave)

func _spawn_monster() -> void:
    var mob := CharacterBody3D.new()
    mob.set_script(MonsterScript)
    mob.player = player
    mob.wave = wave
    add_child(mob)
    var angle := randf() * TAU
    var distance := randf_range(19.0, 29.0)
    mob.global_position = Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
    mob.killed.connect(_on_monster_killed)

func _on_monster_killed() -> void:
    kills += 1
    if is_instance_valid(hud):
        hud.set_kills(kills)

func _on_health_changed(value: float, maximum: float) -> void:
    if is_instance_valid(hud):
        hud.set_health(value, maximum)

func _on_player_died() -> void:
    game_over = true
    if is_instance_valid(hud):
        hud.show_game_over(kills, wave)

func _build_world() -> void:
    randomize()
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.008, 0.018, 0.055)
    sky_mat.sky_horizon_color = Color(0.20, 0.055, 0.075)
    sky_mat.ground_bottom_color = Color(0.008, 0.009, 0.016)
    sky_mat.ground_horizon_color = Color(0.07, 0.025, 0.04)
    sky.sky_material = sky_mat
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.30, 0.34, 0.48)
    env.ambient_light_energy = 0.55
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.glow_enabled = true
    env.glow_intensity = 0.65
    env.glow_bloom = 0.12
    env.fog_enabled = true
    env.fog_light_color = Color(0.16, 0.055, 0.075)
    env.fog_density = 0.012
    world.environment = env
    add_child(world)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -28, 0)
    sun.light_energy = 1.35
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 70
    add_child(sun)

    _make_box("Arena floor", Vector3(0, -0.6, 0), Vector3(72, 1, 72), Color(0.045, 0.052, 0.075), true)
    _make_box("Outer wall north", Vector3(0, 2, -36), Vector3(72, 5, 1), Color(0.075, 0.075, 0.105), true)
    _make_box("Outer wall south", Vector3(0, 2, 36), Vector3(72, 5, 1), Color(0.075, 0.075, 0.105), true)
    _make_box("Outer wall east", Vector3(36, 2, 0), Vector3(1, 5, 72), Color(0.075, 0.075, 0.105), true)
    _make_box("Outer wall west", Vector3(-36, 2, 0), Vector3(1, 5, 72), Color(0.075, 0.075, 0.105), true)

    for i in range(12):
        var a := TAU * float(i) / 12.0
        var p := Vector3(cos(a) * 27, 0, sin(a) * 27)
        _make_box("Gothic pillar", p + Vector3(0, 2.4, 0), Vector3(1.8, 5, 1.8), Color(0.09, 0.095, 0.14), true)
        _make_sphere_light(p + Vector3(0, 4.7, 0), Color(1.0, 0.12, 0.055), 2.5, 5.5)
    for i in range(18):
        var x := randf_range(-23, 23)
        var z := randf_range(-23, 23)
        if Vector2(x, z).length() > 9:
            _make_box("Ruin cover", Vector3(x, 0.8, z), Vector3(randf_range(2, 4), randf_range(1.2, 2.5), randf_range(2, 4)), Color(0.065, 0.075, 0.105), true)
    for x in range(-30, 31, 6):
        _make_box("Floor rune", Vector3(x, -0.075, 0), Vector3(0.06, 0.025, 55), Color(0.22, 0.025, 0.035), false, true)

func _make_box(label: String, pos: Vector3, size: Vector3, color: Color, collision: bool, emissive := false) -> void:
    var body := StaticBody3D.new() if collision else Node3D.new()
    body.name = label
    body.position = pos
    add_child(body)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.78
    if emissive:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = 1.8
    mesh.material_override = mat
    body.add_child(mesh)
    if collision:
        var shape := CollisionShape3D.new()
        var box_shape := BoxShape3D.new()
        box_shape.size = size
        shape.shape = box_shape
        body.add_child(shape)

func _make_sphere_light(pos: Vector3, color: Color, energy: float, range_value: float) -> void:
    var lamp := OmniLight3D.new()
    lamp.position = pos
    lamp.light_color = color
    lamp.light_energy = energy
    lamp.omni_range = range_value
    lamp.shadow_enabled = false
    add_child(lamp)
    var orb := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.22
    sphere.height = 0.44
    orb.mesh = sphere
    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color = color
    mat.emission_enabled = true
    mat.emission = color
    mat.emission_energy_multiplier = 4.0
    orb.material_override = mat
    orb.position = pos
    add_child(orb)
