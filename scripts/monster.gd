extends CharacterBody3D

signal killed

var player: Node3D
var wave := 1
var health := 85.0
var speed := 2.7
var attack_timer := 0.0
var hit_flash := 0.0
var body_mesh: Node3D
var eye_lights: Array[OmniLight3D] = []
var gravity := 18.0

func _ready() -> void:
    add_to_group("monsters")
    health = 85.0 + wave * 12.0
    speed = 2.5 + minf(wave * 0.12, 2.0)
    var capsule := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.58
    shape.height = 2.25
    capsule.shape = shape
    capsule.position.y = 1.12
    add_child(capsule)

    var packed: PackedScene = load("res://assets/models/ash_titan.glb")
    body_mesh = packed.instantiate()
    body_mesh.name = "Ash Titan — imported character model"
    body_mesh.scale = Vector3.ONE
    add_child(body_mesh)

func _physics_process(delta: float) -> void:
    if not is_instance_valid(player):
        return
    attack_timer = maxf(0, attack_timer - delta)
    hit_flash = maxf(0, hit_flash - delta)
    if hit_flash > 0:
        body_mesh.scale = Vector3.ONE * 1.08
    else:
        body_mesh.scale = Vector3.ONE
    var target := player.global_position
    var flat := target - global_position
    flat.y = 0
    var distance := flat.length()
    if distance > 1.5:
        var dir := flat.normalized()
        velocity.x = dir.x * speed
        velocity.z = dir.z * speed
        look_at(Vector3(target.x, global_position.y, target.z), Vector3.UP)
    else:
        velocity.x = move_toward(velocity.x, 0, speed * 5 * delta)
        velocity.z = move_toward(velocity.z, 0, speed * 5 * delta)
        if attack_timer <= 0 and player.has_method("take_damage"):
            player.take_damage(12.0 + wave * 0.8)
            attack_timer = 1.05
    if not is_on_floor():
        velocity.y -= gravity * delta
    move_and_slide()

func take_damage(amount: float, hit_position: Vector3) -> void:
    health -= amount
    hit_flash = 0.12
    if health <= 0:
        _die()

func _die() -> void:
    killed.emit()
    var burst := GPUParticles3D.new()
    burst.position = global_position + Vector3.UP
    burst.amount = 28
    burst.lifetime = 0.65
    burst.one_shot = true
    var pm := ParticleProcessMaterial.new()
    pm.direction = Vector3.UP
    pm.spread = 180
    pm.initial_velocity_min = 2
    pm.initial_velocity_max = 8
    pm.gravity = Vector3(0, -7, 0)
    burst.process_material = pm
    var sphere := SphereMesh.new()
    sphere.radius = 0.06
    sphere.height = 0.12
    burst.draw_pass_1 = sphere
    get_tree().current_scene.add_child(burst)
    burst.emitting = true
    get_tree().create_timer(1.0).timeout.connect(burst.queue_free)
    queue_free()
