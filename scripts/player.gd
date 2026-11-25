extends CharacterBody3D

signal health_changed(value: float, maximum: float)
signal died

const GRENADE: PackedScene = preload("res://scenes/grenade.tscn")
var speed := 8.5
var jump_velocity := 5.8
var gravity := 18.0
var health := 100.0
var max_health := 100.0
var mouse_sensitivity := 0.0022
var camera: Camera3D
var weapon_root: Node3D
var pistol_ammo := 12
var reserve_ammo := 72
var grenades := 3
var fire_cooldown := 0.0
var sword_cooldown := 0.0
var grenade_cooldown := 0.0
var recoil := 0.0
var bob_time := 0.0
var touch_look_delta := Vector2.ZERO
var mobile_move := Vector2.ZERO
var mobile_fire := false
var mobile_sword := false
var mobile_grenade := false
var is_dead := false
var weapon_mode := "PISTOL"
var muzzle_flash: OmniLight3D

func _ready() -> void:
    add_to_group("player")
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    var capsule := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.42
    shape.height = 1.8
    capsule.shape = shape
    capsule.position.y = 0.9
    add_child(capsule)

    camera = Camera3D.new()
    camera.position = Vector3(0, 1.55, 0)
    camera.fov = 88
    camera.current = true
    add_child(camera)
    weapon_root = Node3D.new()
    weapon_root.position = Vector3(0.34, -0.29, -0.62)
    camera.add_child(weapon_root)
    _build_pistol()
    _build_crosshair_light()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        camera.rotate_x(-event.relative.y * mouse_sensitivity)
        camera.rotation.x = clamp(camera.rotation.x, -1.48, 1.48)
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_1:
            weapon_mode = "SWORD"
            _build_sword()
        elif event.keycode == KEY_2:
            weapon_mode = "PISTOL"
            _build_pistol()

func _physics_process(delta: float) -> void:
    if is_dead:
        return
    fire_cooldown = maxf(0, fire_cooldown - delta)
    sword_cooldown = maxf(0, sword_cooldown - delta)
    grenade_cooldown = maxf(0, grenade_cooldown - delta)
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    if mobile_move.length() > 0.12:
        input_dir = mobile_move
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0, speed * 8 * delta)
        velocity.z = move_toward(velocity.z, 0, speed * 8 * delta)
    if not is_on_floor():
        velocity.y -= gravity * delta
    elif Input.is_action_just_pressed("jump"):
        velocity.y = jump_velocity
    move_and_slide()

    if mobile_fire or Input.is_action_pressed("fire"):
        _fire()
    if mobile_sword or Input.is_action_just_pressed("sword"):
        _swing_sword()
        mobile_sword = false
    if mobile_grenade or Input.is_action_just_pressed("grenade"):
        _throw_grenade()
        mobile_grenade = false
    if Input.is_action_just_pressed("reload"):
        _reload()

    bob_time += delta * (10.0 if input_dir.length() > 0.1 else 2.0)
    var bob := sin(bob_time) * 0.012 * minf(1.0, input_dir.length())
    weapon_root.position.y = lerpf(weapon_root.position.y, -0.29 + bob, delta * 12)
    recoil = lerpf(recoil, 0.0, delta * 9)
    weapon_root.position.z = -0.62 + recoil
    if muzzle_flash:
        muzzle_flash.light_energy = move_toward(muzzle_flash.light_energy, 0, delta * 28)

func _build_crosshair_light() -> void:
    muzzle_flash = OmniLight3D.new()
    muzzle_flash.position = Vector3(0, 0, -1.2)
    muzzle_flash.omni_range = 4
    muzzle_flash.light_color = Color(1, 0.35, 0.08)
    muzzle_flash.light_energy = 0
    camera.add_child(muzzle_flash)

func _build_pistol() -> void:
    _clear_weapon()
    weapon_mode = "PISTOL"
    var packed_resource: Resource = load("res://assets/models/hellforged_handcannon.glb")
    if packed_resource == null or not (packed_resource is PackedScene):
        push_error("Could not load imported model scene: res://assets/models/hellforged_handcannon.glb. Run Godot editor import before launching/exporting.")
        return
    var packed: PackedScene = packed_resource as PackedScene
    var model: Node3D = packed.instantiate()
    model.name = "Hellforged Handcannon"
    model.scale = Vector3.ONE * 0.92
    weapon_root.add_child(model)

func _build_sword() -> void:
    _clear_weapon()
    weapon_mode = "SWORD"
    var packed_resource: Resource = load("res://assets/models/oathbreaker_greatsword.glb")
    if packed_resource == null or not (packed_resource is PackedScene):
        push_error("Could not load imported model scene: res://assets/models/oathbreaker_greatsword.glb. Run Godot editor import before launching/exporting.")
        return
    var packed: PackedScene = packed_resource as PackedScene
    var model: Node3D = packed.instantiate()
    model.name = "Oathbreaker Greatsword"
    model.scale = Vector3.ONE * 0.78
    weapon_root.add_child(model)

func _clear_weapon() -> void:
    for child in weapon_root.get_children():
        child.queue_free()

func _fire() -> void:
    if weapon_mode != "PISTOL" or fire_cooldown > 0:
        return
    if pistol_ammo <= 0:
        _reload()
        return
    pistol_ammo -= 1
    fire_cooldown = 0.19
    recoil = 0.12
    muzzle_flash.light_energy = 5.5
    _ray_damage()

func _ray_damage() -> void:
    var from := camera.global_position
    var to := from + (-camera.global_basis.z * 90.0)
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [self]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit:
        var target = hit.collider
        if target and target.has_method("take_damage"):
            var local_hit: Vector3 = target.to_local(hit.position)
            var multiplier := 1.0
            if local_hit.y > 1.25:
                multiplier = 3.0
            elif local_hit.y < 0.42:
                multiplier = 0.55
            target.take_damage(24.0 * multiplier, hit.position)
        _impact(hit.position, hit.normal)

func _impact(pos: Vector3, normal: Vector3) -> void:
    var spark := GPUParticles3D.new()
    spark.position = pos
    spark.amount = 10
    spark.lifetime = 0.22
    spark.one_shot = true
    var process := ParticleProcessMaterial.new()
    process.direction = normal
    process.spread = 65
    process.initial_velocity_min = 2
    process.initial_velocity_max = 7
    process.gravity = Vector3(0, -5, 0)
    spark.process_material = process
    var draw := SphereMesh.new()
    draw.radius = 0.035
    draw.height = 0.07
    spark.draw_pass_1 = draw
    get_tree().current_scene.add_child(spark)
    spark.emitting = true
    get_tree().create_timer(0.5).timeout.connect(spark.queue_free)

func _swing_sword() -> void:
    if weapon_mode != "SWORD":
        _build_sword()
    if sword_cooldown > 0:
        return
    sword_cooldown = 0.95
    var tween := create_tween()
    weapon_root.rotation = Vector3(-0.2, -0.5, 0.7)
    weapon_root.position = Vector3(0.34, -0.29, -0.62)
    tween.tween_property(weapon_root, "rotation", Vector3(-1.0, 0.85, -1.5), 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    tween.tween_property(weapon_root, "rotation", Vector3(0, 0, 0), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    var center := camera.global_position + -camera.global_basis.z * 2.6
    for mob in get_tree().get_nodes_in_group("monsters"):
        if mob.global_position.distance_to(center) < 4.3:
            var to_mob: Vector3 = (mob.global_position - camera.global_position).normalized()
            if camera.global_basis.z.dot(-to_mob) > -0.25:
                mob.take_damage(78.0, mob.global_position)

func _throw_grenade() -> void:
    if grenades <= 0 or grenade_cooldown > 0:
        return
    grenades -= 1
    grenade_cooldown = 0.55
    var grenade: RigidBody3D = GRENADE.instantiate()
    get_tree().current_scene.add_child(grenade)
    grenade.global_position = camera.global_position + -camera.global_basis.z * 0.8
    grenade.launch(-camera.global_basis.z * 12.0 + Vector3.UP * 5.5)

func _reload() -> void:
    if pistol_ammo >= 12 or reserve_ammo <= 0:
        return
    var amount := mini(12 - pistol_ammo, reserve_ammo)
    pistol_ammo += amount
    reserve_ammo -= amount

func take_damage(amount: float) -> void:
    if is_dead:
        return
    health = maxf(0, health - amount)
    health_changed.emit(health, max_health)
    if health <= 0:
        is_dead = true
        died.emit()

func mobile_action(action: String) -> void:
    match action:
        "fire": mobile_fire = true
        "fire_release": mobile_fire = false
        "sword": mobile_sword = true
        "grenade": mobile_grenade = true
        "jump": velocity.y = jump_velocity

func set_mobile_move(value: Vector2) -> void:
    mobile_move = value

func add_touch_look(delta_value: Vector2) -> void:
    rotate_y(-delta_value.x * mouse_sensitivity * 1.5)
    camera.rotate_x(-delta_value.y * mouse_sensitivity * 1.5)
    camera.rotation.x = clamp(camera.rotation.x, -1.48, 1.48)
