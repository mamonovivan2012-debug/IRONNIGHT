extends CanvasLayer

var game
var player
var health_bar: ProgressBar
var health_label: Label
var ammo_label: Label
var wave_label: Label
var kills_label: Label
var message: Label
var mobile := false
var look_touch := -1
var move_touch := -1
var joystick_origin := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var joystick_base: ColorRect
var joystick_knob: ColorRect

func bind_game(game_ref, player_ref) -> void:
    game = game_ref
    player = player_ref
    mobile = DisplayServer.is_touchscreen_available()
    _build_hud()

func _build_hud() -> void:
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(root)

    var title := _label(root, "IRON NIGHT", Vector2(28, 20), 25, Color(1, 0.22, 0.12))
    title.add_theme_font_size_override("font_size", 25)
    _label(root, "THE LAST SANCTUM  /  SURVIVE", Vector2(30, 51), 11, Color(0.55, 0.62, 0.72))

    health_bar = ProgressBar.new()
    health_bar.position = Vector2(30, 78)
    health_bar.size = Vector2(250, 18)
    health_bar.max_value = 100
    health_bar.value = 100
    health_bar.show_percentage = false
    root.add_child(health_bar)
    health_label = _label(root, "VITALS  100", Vector2(30, 101), 13, Color(0.95, 0.75, 0.68))
    wave_label = _label(root, "WAVE 01", Vector2(30, 135), 19, Color(1, 0.82, 0.66))
    kills_label = _label(root, "KILLS  0", Vector2(30, 162), 13, Color(0.7, 0.76, 0.85))

    ammo_label = _label(root, "12 / 72     GRENADES  3", Vector2(-310, -65), 18, Color(1, 0.85, 0.72))
    ammo_label.anchor_left = 1
    ammo_label.anchor_top = 1
    ammo_label.anchor_right = 1
    ammo_label.anchor_bottom = 1
    ammo_label.size = Vector2(280, 35)
    ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

    var cross := _label(root, "+", Vector2.ZERO, 30, Color(1, 0.88, 0.78))
    cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    cross.position = Vector2(-8, -21)
    cross.size = Vector2(20, 40)
    cross.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    message = _label(root, "WASD MOVE   •   MOUSE AIM   •   LMB FIRE\nQ / RMB SWORD   •   G GRENADE   •   R RELOAD   •   1 / 2 WEAPON", Vector2(0, -38), 12, Color(0.75, 0.78, 0.86))
    message.anchor_left = 0.5
    message.anchor_right = 0.5
    message.anchor_top = 1
    message.anchor_bottom = 1
    message.position.x = -300
    message.size = Vector2(600, 30)
    message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    if mobile:
        _build_mobile_controls(root)

func _label(parent: Control, value: String, pos: Vector2, size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = value
    label.position = pos
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", color)
    label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
    label.add_theme_constant_override("shadow_offset_x", 2)
    label.add_theme_constant_override("shadow_offset_y", 2)
    parent.add_child(label)
    return label

func _build_mobile_controls(root: Control) -> void:
    joystick_base = ColorRect.new()
    joystick_base.color = Color(0.35, 0.42, 0.52, 0.28)
    joystick_base.size = Vector2(132, 132)
    joystick_base.position = Vector2(42, -178)
    joystick_base.anchor_top = 1
    joystick_base.anchor_bottom = 1
    root.add_child(joystick_base)
    joystick_knob = ColorRect.new()
    joystick_knob.color = Color(0.8, 0.86, 0.95, 0.6)
    joystick_knob.size = Vector2(54, 54)
    joystick_knob.position = joystick_base.position + Vector2(39, 39)
    joystick_knob.anchor_top = 1
    joystick_knob.anchor_bottom = 1
    root.add_child(joystick_knob)
    _mobile_button(root, "FIRE", Vector2(-142, -150), "fire")
    _mobile_button(root, "SWORD", Vector2(-250, -75), "sword")
    _mobile_button(root, "BOOM", Vector2(-142, -55), "grenade")
    _mobile_button(root, "JUMP", Vector2(-250, -170), "jump")

func _mobile_button(root: Control, text_value: String, pos: Vector2, action: String) -> void:
    var b := Button.new()
    b.text = text_value
    b.position = pos
    b.size = Vector2(92, 66)
    b.anchor_left = 1
    b.anchor_right = 1
    b.anchor_top = 1
    b.anchor_bottom = 1
    b.modulate = Color(1, 1, 1, 0.72)
    root.add_child(b)
    if action == "fire":
        b.button_down.connect(func(): player.mobile_action("fire"))
        b.button_up.connect(func(): player.mobile_action("fire_release"))
    else:
        b.pressed.connect(func(): player.mobile_action(action))

func _input(event: InputEvent) -> void:
    if not mobile or not is_instance_valid(player):
        return
    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x < get_viewport().get_visible_rect().size.x * 0.45 and move_touch == -1:
                move_touch = event.index
                joystick_origin = joystick_base.position + Vector2(66, 66) + Vector2(42, get_viewport().get_visible_rect().size.y - 178)
            elif event.position.x >= get_viewport().get_visible_rect().size.x * 0.45:
                look_touch = event.index
        else:
            if event.index == move_touch:
                move_touch = -1
                joystick_vector = Vector2.ZERO
                player.set_mobile_move(Vector2.ZERO)
                joystick_knob.position = joystick_base.position + Vector2(39, 39)
            if event.index == look_touch:
                look_touch = -1
    elif event is InputEventScreenDrag:
        if event.index == move_touch:
            var center := Vector2(108, get_viewport().get_visible_rect().size.y - 112)
            var v: Vector2 = (event.position - center) / 55.0
            joystick_vector = v.limit_length(1.0)
            player.set_mobile_move(joystick_vector)
            joystick_knob.position = Vector2(42, get_viewport().get_visible_rect().size.y - 178) + Vector2(39, 39) + joystick_vector * 38
        elif event.index == look_touch:
            player.add_touch_look(event.relative)

func set_wave(value: int) -> void:
    wave_label.text = "WAVE %02d" % value

func set_kills(value: int) -> void:
    kills_label.text = "KILLS  %d" % value

func set_health(value: float, maximum: float) -> void:
    health_bar.max_value = maximum
    health_bar.value = value
    health_label.text = "VITALS  %03d" % int(value)

func _process(_delta: float) -> void:
    if is_instance_valid(player) and is_instance_valid(ammo_label):
        ammo_label.text = "%02d / %02d     GRENADES  %d" % [player.pistol_ammo, player.reserve_ammo, player.grenades]

func show_game_over(kills: int, wave: int) -> void:
    var panel := ColorRect.new()
    panel.color = Color(0.015, 0.01, 0.025, 0.88)
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(panel)
    var title := _label(panel, "YOU HAVE FALLEN", Vector2.ZERO, 42, Color(1, 0.18, 0.1))
    title.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    title.position = Vector2(-240, -90)
    title.size = Vector2(480, 60)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var stats := _label(panel, "WAVE REACHED: %d     MONSTERS SLAIN: %d\nPress F5 to rise again" % [wave, kills], Vector2.ZERO, 20, Color(0.85, 0.83, 0.9))
    stats.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    stats.position = Vector2(-260, 0)
    stats.size = Vector2(520, 80)
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
