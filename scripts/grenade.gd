extends RigidBody3D

var fuse := 3.0
var exploded := false

func _ready() -> void:
    var packed_resource: Resource = load("res://assets/models/hellfire_grenade.glb")
    if packed_resource == null or not (packed_resource is PackedScene):
        push_error("Could not load imported model scene: res://assets/models/hellfire_grenade.glb. Run Godot editor import before launching/exporting.")
        return
    var packed: PackedScene = packed_resource as PackedScene
    var model: Node3D = packed.instantiate()
    model.name = "Hellfire fragmentation grenade"
    add_child(model)
    var shape_node := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = 0.17
    shape_node.shape = shape
    add_child(shape_node)
    var light := OmniLight3D.new()
    light.light_color = Color(1, 0.12, 0.025)
    light.light_energy = 1.2
    light.omni_range = 3.5
    add_child(light)
    var timer := Timer.new()
    timer.wait_time = fuse
    timer.one_shot = true
    timer.timeout.connect(_explode)
    add_child(timer)
    timer.start()

func launch(initial_velocity: Vector3) -> void:
    apply_central_impulse(initial_velocity)

func _physics_process(delta: float) -> void:
    if exploded:
        return
    var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.018) * 0.18
    scale = Vector3.ONE * pulse

func _explode() -> void:
    if exploded:
        return
    exploded = true
    var center := global_position
    for candidate: Node in get_tree().get_nodes_in_group("monsters"):
        var mob: Node3D = candidate as Node3D
        if mob == null or not mob.has_method("take_damage"):
            continue
        var distance: float = mob.global_position.distance_to(center)
        if distance < 9.0:
            mob.call("take_damage", 155.0 * (1.0 - distance / 12.0), center)
    var flash := OmniLight3D.new()
    flash.position = center
    flash.light_color = Color(1.0, 0.22, 0.045)
    flash.light_energy = 12
    flash.omni_range = 15
    get_tree().current_scene.add_child(flash)
    var particles := GPUParticles3D.new()
    particles.position = center
    particles.amount = 100
    particles.lifetime = 0.85
    particles.one_shot = true
    var pm := ParticleProcessMaterial.new()
    pm.direction = Vector3.UP
    pm.spread = 180
    pm.initial_velocity_min = 4
    pm.initial_velocity_max = 18
    pm.gravity = Vector3(0, -12, 0)
    pm.scale_min = 0.08
    pm.scale_max = 0.22
    particles.process_material = pm
    var draw := SphereMesh.new()
    draw.radius = 0.12
    draw.height = 0.24
    particles.draw_pass_1 = draw
    get_tree().current_scene.add_child(particles)
    particles.emitting = true
    get_tree().create_timer(0.9).timeout.connect(particles.queue_free)
    get_tree().create_timer(0.25).timeout.connect(flash.queue_free)
    queue_free()
