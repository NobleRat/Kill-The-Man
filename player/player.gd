extends CharacterBody2D
## მოთამაშე: სირბილი, ხტომა და მახვილით დარტყმა.
##
## ქვემოთ მოცემული რიცხვები შეგიძლიათ Inspector-ში შეცვალოთ
## (აირჩიეთ Player კვანძი) — კოდში შესვლა არ არის საჭირო.

@export_group("სირბილი")
## მაქსიმალური სიჩქარე (პიქსელი წამში).
@export var run_speed := 330.0
## რამდენად სწრაფად აჩქარდება.
@export var acceleration := 2600.0
## რამდენად სწრაფად ჩერდება, როცა ღილაკს უშვებ.
@export var friction := 3000.0
## ჰაერში მართვის სიმკვეთრე (1 = ისევე, როგორც მიწაზე).
@export_range(0.0, 1.0) var air_control := 0.65

@export_group("ხტომა")
## ხტომის საწყისი სიჩქარე ზემოთ.
@export var jump_speed := 720.0
## სიმძიმე — რამდენად ძლიერად ექაჩება მიწა.
@export var gravity := 2000.0
## დაცემისას სიმძიმე ამდენჯერ მეტია — ხტომა „წონიანი“ გამოდის.
@export var fall_gravity_multiplier := 1.5
## დაცემის მაქსიმალური სიჩქარე.
@export var max_fall_speed := 1100.0
## ხტომის ღილაკს ადრე თუ გაუშვებ, ზემოთ სიჩქარე ამაზე მრავლდება (დაბალი ხტომა).
@export_range(0.0, 1.0) var jump_cut := 0.45
## კიდიდან ჩამოსვლის შემდეგ ამდენი წამი კიდევ შეიძლება ხტომა.
@export var coyote_time := 0.1
## დაცემამდე ამდენი წამით ადრე დაჭერილი ხტომაც ჩაითვლება.
@export var jump_buffer_time := 0.12

@export_group("ბრძოლა")
## მოქნევისას წინ „გადადგმული ნაბიჯის“ სიჩქარე.
@export var lunge_speed := 260.0
## მოქნევის დროს მიწაზე რამდენად სწრაფად ჩერდება.
@export var attack_friction := 1400.0

@export_group("სხვა")
## ამ სიღრმეზე ჩავარდნისას მოთამაშე საწყის ადგილას ბრუნდება.
@export var fall_limit := 1300.0

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _spawn_position := Vector2.ZERO
## 1 = მარჯვნივ იყურება, -1 = მარცხნივ.
var _facing := 1.0

@onready var _visual: Node2D = $Visual
@onready var _sword: Sword = $Visual/Sword


func _ready() -> void:
	_spawn_position = global_position
	_sword.swing_started.connect(_on_sword_swing_started)


# ეს ფუნქცია წამში 60-ჯერ ეშვება და ყოველ ჯერზე მოძრაობას ითვლის.
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		_sword.request_attack()

	_apply_gravity(delta)
	_handle_jump(delta)
	_handle_run(delta)
	move_and_slide()

	if global_position.y > fall_limit:
		_respawn()


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var current_gravity := gravity
	if velocity.y > 0.0:
		current_gravity *= fall_gravity_multiplier
	velocity.y = minf(velocity.y + current_gravity * delta, max_fall_speed)


func _handle_jump(delta: float) -> void:
	# ორი „მეხსიერება“: ცოტა ხნის წინ მიწაზე ვიდექი? ცოტა ხნის წინ დავაჭირე ხტომას?
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer -= delta

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = -jump_speed
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0

	# ღილაკი ადრე გაუშვი — ხტომა დაბალი გამოდის.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut


func _handle_run(delta: float) -> void:
	# მოქნევის დროს მიწაზე სირბილი არ შეიძლება — დარტყმას „წონა“ აქვს.
	# ჰაერში კი მოთამაშე ძველი სიჩქარით აგრძელებს ფრენას.
	if _sword.is_busy():
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0.0, attack_friction * delta)
		return

	var direction := Input.get_axis("move_left", "move_right")
	var control := 1.0 if is_on_floor() else air_control

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * run_speed, acceleration * control * delta)
		# პერსონაჟი მოძრაობის მხარეს „იყურება“.
		_facing = signf(direction)
		_visual.scale.x = _facing
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * control * delta)


func _on_sword_swing_started() -> void:
	if is_on_floor():
		velocity.x = _facing * lunge_speed


func _respawn() -> void:
	global_position = _spawn_position
	velocity = Vector2.ZERO
	reset_physics_interpolation()
