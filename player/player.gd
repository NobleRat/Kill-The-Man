extends CharacterBody2D
## მოთამაშე: სირბილი, ხტომა (ორმაგიც), დეში (Shift) და მახვილით დარტყმა.
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
## ხტომის ღილაკზე ხელი თუ გიჭირავს, მიწაზე დაშვებისთანავე ისევ ხტება.
@export var auto_jump := true
## ჰაერში დამატებითი ხტომების რაოდენობა (1 = ორმაგი ხტომა, 0 = გამორთულია).
@export_range(0, 5) var air_jumps := 1
## ჰაერში ხტომის საწყისი სიჩქარე ზემოთ.
@export var air_jump_speed := 650.0
## ჰაერში ხტომისას სხეული ამდენჯერ იჭიმება სიმაღლეში (1 = არ იჭიმება).
@export_range(1.0, 2.0) var air_jump_stretch := 1.2

@export_group("ბრძოლა")
## მოქნევისას წინ „გადადგმული ნაბიჯის“ სიჩქარე.
@export var lunge_speed := 260.0
## მოქნევის დროს მიწაზე რამდენად სწრაფად ჩერდება.
@export var attack_friction := 1400.0

@export_group("დეში")
## დეშის სიჩქარე (პიქსელი წამში). მანძილი ≈ სიჩქარე × ხანგრძლივობა.
@export var dash_speed := 900.0
## რამდენ ხანს გრძელდება ერთი დეში (წამი).
@export var dash_time := 0.16
## დეშის დასრულებიდან ამდენი წამი უნდა გავიდეს შემდეგ დეშამდე.
@export var dash_cooldown := 0.3
## ჰაერშიც შეიძლება დეში (ერთხელ, მიწაზე დაშვებამდე).
@export var air_dash := true
## დეშის ღილაკი ამდენი წამით ადრე დაჭერილიც ჩაითვლება.
@export var dash_buffer_time := 0.15
## დეშისას სხეული ამდენჯერ იჭიმება სიგრძეში (1 = არ იჭიმება).
@export_range(1.0, 2.0) var dash_stretch := 1.25
## დეშისას სხეული წინ ამდენი გრადუსით იხრება.
@export_range(0.0, 45.0) var dash_lean := 12.0
## უკან დატოვებული „ანარეკლების“ სიხშირე: ერთი ამდენ წამში.
@export var ghost_interval := 0.03
## ანარეკლის სიმკვრივე (0 = უხილავი, 1 = სრულიად შავი).
@export_range(0.0, 1.0) var ghost_opacity := 0.5
## რამდენ წამში ქრება ანარეკლი.
@export var ghost_fade_time := 0.25

@export_group("სხვა")
## ამ სიღრმეზე ჩავარდნისას მოთამაშე საწყის ადგილას ბრუნდება.
@export var fall_limit := 1300.0

const AFTERIMAGE := preload("res://effects/afterimage.gd")
const DASH_DUST := preload("res://effects/dash_dust.tscn")
const JUMP_PUFF := preload("res://effects/jump_puff.tscn")
## დეშის შემდეგ სხეული ამდენ წამში სწორდება.
const DASH_POSE_RECOVERY := 0.12
## ჰაერში ხტომის შემდეგ სხეული ამდენ წამში სწორდება.
const AIR_JUMP_POSE_RECOVERY := 0.2

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
## ჰაერში კიდევ რამდენი ხტომა დარჩა (მიწაზე დაშვებისას ივსება).
var _air_jumps_left := 0
## 1 = ჰაერში ხტომისგან სხეული სრულად გაჭიმულია, 0 = ჩვეულებრივი.
var _air_jump_pose := 0.0
var _spawn_position := Vector2.ZERO
## 1 = მარჯვნივ იყურება, -1 = მარცხნივ.
var _facing := 1.0

## დეშის დასრულებამდე დარჩენილი დრო (0 = ახლა დეში არ ხდება).
var _dash_timer := 0.0
var _dash_direction := 1.0
var _dash_buffer_timer := 0.0
var _dash_cooldown_timer := 0.0
var _air_dash_ready := true
var _ghost_timer := 0.0
## 1 = სხეული სრულად დახრილი/გაჭიმულია, 0 = ჩვეულებრივი.
var _dash_pose := 0.0

@onready var _visual: Node2D = $Visual
@onready var _sword: Sword = $Visual/Sword


func _ready() -> void:
	_spawn_position = global_position
	_sword.swing_started.connect(_on_sword_swing_started)


# ეს ფუნქცია წამში 60-ჯერ ეშვება და ყოველ ჯერზე მოძრაობას ითვლის.
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		_sword.request_attack()

	_handle_dash(delta)
	# დეშის დროს სიმძიმე არ მოქმედებს — პირდაპირ ხაზზე მივფრინავთ.
	if not _is_dashing():
		_apply_gravity(delta)
	_handle_jump(delta)
	_handle_run(delta)
	move_and_slide()

	# კედელს შევასკდით — დეში აქვე მთავრდება.
	if _is_dashing() and is_on_wall():
		_end_dash()
	_update_pose(delta)

	if global_position.y > fall_limit:
		_respawn()


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var current_gravity := gravity
	if velocity.y > 0.0:
		current_gravity *= fall_gravity_multiplier
	velocity.y = minf(velocity.y + current_gravity * delta, max_fall_speed)


# ხტომის ყოველი ახალი დაჭერა. W და Space ცალ-ცალკე ითვლება:
# W-ზე ხელი თუ გიჭირავს და Space-ს დააჭერ, ესეც ახალი დაჭერაა (ორმაგი ხტომისთვის).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time


func _handle_jump(delta: float) -> void:
	# ორი „მეხსიერება“: ცოტა ხნის წინ მიწაზე ვიდექი? ცოტა ხნის წინ დავაჭირე ხტომას?
	if is_on_floor():
		_coyote_timer = coyote_time
		_air_jumps_left = air_jumps
	else:
		_coyote_timer -= delta
	_jump_buffer_timer -= delta

	# ღილაკზე ხელი გიჭირავს — მიწაზე დაშვებისთანავე ისევ ხტება.
	# (დეშს მხოლოდ ახალი დაჭერა წყვეტს, ხელის დაჭერა — არა.)
	var holding := auto_jump and Input.is_action_pressed("jump") and not _is_dashing()
	if _coyote_timer > 0.0 and (_jump_buffer_timer > 0.0 or holding):
		_jump(jump_speed)
	elif _jump_buffer_timer > 0.0 and _air_jumps_left > 0:
		# ჰაერში ახლად დაჭერილი ხტომა — ორმაგი ხტომა.
		_air_jumps_left -= 1
		_jump(air_jump_speed)
		_air_jump_pose = 1.0
		_spawn_effect(JUMP_PUFF, Vector2(0.0, 1.0))

	# ღილაკი ადრე გაუშვი — ხტომა დაბალი გამოდის.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut


func _jump(speed: float) -> void:
	# დეშის დროს ხტომა დეშს წყვეტს.
	if _is_dashing():
		_end_dash()
	velocity.y = -speed
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0


func _handle_run(delta: float) -> void:
	# დეშის დროს სიჩქარეს თვითონ დეში მართავს.
	if _is_dashing():
		return
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
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * control * delta)


func _handle_dash(delta: float) -> void:
	if Input.is_action_just_pressed("dash"):
		_dash_buffer_timer = dash_buffer_time
	else:
		_dash_buffer_timer -= delta
	if is_on_floor():
		_air_dash_ready = true

	if _is_dashing():
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_end_dash()
			return
		velocity = Vector2(_dash_direction * dash_speed, 0.0)
		_ghost_timer -= delta
		if _ghost_timer <= 0.0:
			_spawn_afterimage()
			_ghost_timer += ghost_interval
		return

	_dash_cooldown_timer -= delta
	if _dash_buffer_timer > 0.0 and _can_dash():
		_start_dash()


func _can_dash() -> bool:
	# მოქნევის შუაში დეში არ შეიძლება (დაჭერილი დეში მოქნევის მერე შესრულდება),
	# მოქნევის შემდგომ დასვენებას კი დეში წყვეტს.
	if _dash_cooldown_timer > 0.0 or _sword.is_busy():
		return false
	return is_on_floor() or (air_dash and _air_dash_ready)


func _start_dash() -> void:
	_dash_buffer_timer = 0.0
	if not is_on_floor():
		_air_dash_ready = false
	# დეში დაჭერილი მიმართულებით, თუ არაფერია დაჭერილი — იქით, საითაც იყურება.
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		_facing = signf(direction)
	_dash_direction = _facing
	_dash_timer = dash_time
	_dash_pose = 1.0
	_sword.locked = true
	velocity = Vector2(_dash_direction * dash_speed, 0.0)

	_spawn_afterimage()
	_ghost_timer = ghost_interval
	if is_on_floor():
		# მტვერი დეშის საწინააღმდეგო მხარეს იფანტება.
		_spawn_effect(DASH_DUST, Vector2(-_dash_direction, -0.3))


func _end_dash() -> void:
	_dash_timer = 0.0
	_dash_cooldown_timer = dash_cooldown
	_sword.locked = false
	# დეშის მერე ჩვეულებრივი სირბილის სიჩქარით ვაგრძელებთ (კედელთან — 0).
	velocity.x = _dash_direction * minf(absf(velocity.x), run_speed)


func _is_dashing() -> bool:
	return _dash_timer > 0.0


# სხეულის პოზა: დეშისას წინ იხრება და სიგრძეში იჭიმება,
# ჰაერში ხტომისას — სიმაღლეში. მერე სწრაფად სწორდება.
func _update_pose(delta: float) -> void:
	if not _is_dashing():
		_dash_pose = move_toward(_dash_pose, 0.0, delta / DASH_POSE_RECOVERY)
	_air_jump_pose = move_toward(_air_jump_pose, 0.0, delta / AIR_JUMP_POSE_RECOVERY)
	var stretch := lerpf(1.0, dash_stretch, _dash_pose) / lerpf(1.0, air_jump_stretch, _air_jump_pose)
	_visual.scale = Vector2(_facing * stretch, 1.0 / stretch)
	_visual.skew = _facing * deg_to_rad(dash_lean) * _dash_pose


func _spawn_afterimage() -> void:
	var ghost := AFTERIMAGE.new()
	ghost.fade_time = ghost_fade_time
	var level := get_parent()
	level.add_child(ghost)
	# ანარეკლი მოთამაშის უკან უნდა ჩანდეს, არა წინ.
	level.move_child(ghost, get_index())
	ghost.copy_from(_visual, ghost_opacity)


# მტვრის ეფექტი ფეხებთან; direction — საითკენ იფანტება.
func _spawn_effect(scene: PackedScene, direction: Vector2) -> void:
	var effect: CPUParticles2D = scene.instantiate()
	effect.position = global_position
	effect.direction = direction
	get_parent().add_child(effect)


func _on_sword_swing_started() -> void:
	if is_on_floor():
		velocity.x = _facing * lunge_speed


func _respawn() -> void:
	if _is_dashing():
		_end_dash()
	global_position = _spawn_position
	velocity = Vector2.ZERO
	reset_physics_interpolation()
