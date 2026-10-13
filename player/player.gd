extends CharacterBody2D
## მოთამაშე: სირბილი, ხტომა (ორმაგიც), დეში (Shift), მახვილით დარტყმა და სიცოცხლე.
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
## ხტომის სიმაღლე ≈ jump_speed² ÷ (2 × gravity) ≈ 195 პიქსელი.
## მწვერვალამდე დრო ≈ jump_speed ÷ gravity ≈ 0.29 წამი.
@export var jump_speed := 1350.0
## სიმძიმე — რამდენად ძლიერად ექაჩება მიწა.
@export var gravity := 4687.5
## დაცემისას სიმძიმე ამაზე მრავლდება (1-ზე ნაკლები = ნელი, „მცურავი“ დაცემა).
## დაცემის N-ჯერ აჩქარებისთვის ეს რიცხვი N×N-ჯერ იზრდება, max_fall_speed კი N-ჯერ
## (შენელებისთვის — იმდენჯერვე მცირდება).
@export var fall_gravity_multiplier := 0.5859375
## დაცემის მაქსიმალური სიჩქარე.
@export var max_fall_speed := 1031.25
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
@export var air_jump_speed := 1220.0
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
## ჰაერშიც შეიძლება დეში — რამდენჯერაც გინდა, ისევე როგორც მიწაზე.
@export var air_dash := true
## დეშის ღილაკი ამდენი წამით ადრე დაჭერილიც ჩაითვლება.
@export var dash_buffer_time := 0.15
## დეშის დაწყებიდან ამდენ წამს მტრის დარტყმა ვერ გაზიანებს —
## დეშით შეგიძლია დარტყმაში გაძვრე (0 = გამორთულია; თვითონ დეში dash_time წამს გრძელდება).
@export var dash_invincibility_time := 0.2
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

@export_group("სიცოცხლე")
## სიცოცხლის რაოდენობა (ჩანს ეკრანის ზედა მარცხენა კუთხეში).
@export_range(1, 20) var max_health := 5
## მტრის დარტყმის შემდეგ ამდენ წამს ვერაფერი დაგაზიანებს (ამ დროს პერსონაჟი ციმციმებს).
@export var invincibility_time := 0.8
## დარტყმისას წითელი ციმციმის ხანგრძლივობა (წამი).
@export var hurt_flash_time := 0.25
## დარტყმის ციმციმის ფერი.
@export var hurt_flash_color := Color(1.0, 0.15, 0.1)
## მტრის დარტყმისას რა სიჩქარით გადაიწევს უკან.
@export var hurt_knockback_speed := 420.0
## მტრის დარტყმისას რამდენად ახტება ზემოთ.
@export var hurt_knockback_hop := 500.0
## დარტყმის შემდეგ ამდენ წამს სირბილს და დეშს ვერ მართავ.
@export var hurt_stun_time := 0.25
## სიცოცხლე რომ გაგითავდება, ამდენი წამის მერე იწყება დონე თავიდან.
@export var death_restart_delay := 0.8

@export_group("სხვა")
## ამ სიღრმეზე ჩავარდნისას მოთამაშე საწყის ადგილას ბრუნდება.
@export var fall_limit := 1300.0

const AFTERIMAGE := preload("res://effects/afterimage.gd")
const HealthDisplay := preload("res://player/health_display.gd")
const DASH_DUST := preload("res://effects/dash_dust.tscn")
const JUMP_PUFF := preload("res://effects/jump_puff.tscn")
## დეშის შემდეგ სხეული ამდენ წამში სწორდება.
const DASH_POSE_RECOVERY := 0.12
## ჰაერში ხტომის შემდეგ სხეული ამდენ წამში სწორდება.
const AIR_JUMP_POSE_RECOVERY := 0.2
## W და Space ამ დროის შიგნით თუ დააჭირე, ეს „ერთად დაჭერაა“ — ერთი ხტომა, არა ორმაგი.
const SIMULTANEOUS_PRESS_TIME := 0.1
## დარტყმის შემდგომი დაუზიანებლობისას ციმციმი: რამდენ წამში ერთხელ ქრება და რამდენად.
const BLINK_INTERVAL := 0.07
const BLINK_OPACITY := 0.3

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
## ჰაერში კიდევ რამდენი ხტომა დარჩა (მიწაზე დაშვებისას ივსება).
var _air_jumps_left := 0
## ბოლო ხტომიდან გასული დრო.
var _time_since_jump := 0.0
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
var _ghost_timer := 0.0
## 1 = სხეული სრულად დახრილი/გაჭიმულია, 0 = ჩვეულებრივი.
var _dash_pose := 0.0
## მტრის დარტყმის შემდეგ მართვის დაბრუნებამდე დარჩენილი დრო.
var _hurt_timer := 0.0
var _health := 0
## დარტყმის შემდგომი დაუზიანებლობიდან დარჩენილი დრო.
var _hurt_invincible_timer := 0.0
## დეშის დაუზიანებლობიდან დარჩენილი დრო.
var _dash_invincible_timer := 0.0
## true — სიცოცხლე გაუთავდა, დონე მალე თავიდან დაიწყება.
var _dead := false
var _flash_tween: Tween

@onready var _visual: Node2D = $Visual
@onready var _sword: Sword = $Visual/Sword
@onready var _material: ShaderMaterial = $Visual.material
@onready var _health_display: HealthDisplay = $HUD/HealthDisplay


func _ready() -> void:
	# მტრები მოთამაშეს ამ ჯგუფით პოულობენ.
	add_to_group("player")
	_spawn_position = global_position
	_health = max_health
	_health_display.show_health(_health, max_health)
	_material.set_shader_parameter("flash_color", hurt_flash_color)
	_sword.swing_started.connect(_on_sword_swing_started)
	_sword.turn_requested.connect(_on_sword_turn_requested)


# ეს ფუნქცია წამში 60-ჯერ ეშვება და ყოველ ჯერზე მოძრაობას ითვლის.
func _physics_process(delta: float) -> void:
	if _dead:
		# სიცოცხლე გაუთავდა: მართვა აღარ მუშაობს, მხოლოდ ეცემა და ჩერდება.
		_apply_gravity(delta)
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		move_and_slide()
		return

	if Input.is_action_just_pressed("attack"):
		_sword.request_attack()

	_hurt_timer -= delta
	_hurt_invincible_timer -= delta
	_dash_invincible_timer -= delta
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
	_update_blink()

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
	_time_since_jump += delta

	# ღილაკზე ხელი გიჭირავს — მიწაზე დაშვებისთანავე ისევ ხტება.
	# (დეშს მხოლოდ ახალი დაჭერა წყვეტს, ხელის დაჭერა — არა.)
	var holding := auto_jump and Input.is_action_pressed("jump") and not _is_dashing()
	if _coyote_timer > 0.0 and (_jump_buffer_timer > 0.0 or holding):
		_jump(jump_speed)
	elif _jump_buffer_timer > 0.0 and _time_since_jump < SIMULTANEOUS_PRESS_TIME:
		# მეორე ღილაკი პირველთან თითქმის ერთად დააჭირე — ეს იგივე ხტომაა.
		_jump_buffer_timer = 0.0
	elif _jump_buffer_timer > 0.0 and _air_jumps_left > 0:
		# ჰაერში ახლად დაჭერილი ხტომა — ორმაგი ხტომა.
		_air_jumps_left -= 1
		_jump(air_jump_speed)
		# ორმაგი ხტომა დეშს აღადგენს: შემდეგი დეში ლოდინის გარეშე შეიძლება.
		_dash_cooldown_timer = 0.0
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
	_time_since_jump = 0.0


func _handle_run(delta: float) -> void:
	# დეშის დროს სიჩქარეს თვითონ დეში მართავს.
	if _is_dashing():
		return
	# მოქნევის დროს მიწაზე სირბილი არ შეიძლება — დარტყმას „წონა“ აქვს.
	# ჰაერში კი მოთამაშე ძველი სიჩქარით აგრძელებს ფრენას.
	# მტრის დარტყმის შემდეგაც ასეა — უკან გადაგდება შენს სირბილს არ წაეშლება.
	if _sword.is_busy() or _hurt_timer > 0.0:
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
	if _dash_cooldown_timer > 0.0 or _sword.is_busy() or _hurt_timer > 0.0:
		return false
	return is_on_floor() or air_dash


func _start_dash() -> void:
	_dash_buffer_timer = 0.0
	# დეში დაჭერილი მიმართულებით, თუ არაფერია დაჭერილი — იქით, საითაც იყურება.
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		_facing = signf(direction)
	_dash_direction = _facing
	_dash_timer = dash_time
	_dash_invincible_timer = dash_invincibility_time
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


# დარტყმისას მოთამაშე კურსორის მხარეს ტრიალდება.
func _on_sword_turn_requested(side: float) -> void:
	_facing = side
	_visual.scale.x = side * absf(_visual.scale.x)


func _on_sword_swing_started() -> void:
	if is_on_floor():
		velocity.x = _facing * lunge_speed


## მტერი იძახებს, როცა მოთამაშეს მოხვდება. `damage` — რამდენ სიცოცხლეს აკლებს,
## `direction` — დარტყმის მიმართულება. აბრუნებს true-ს, თუ დარტყმამ გაჭრა,
## false-ს — თუ მოთამაშე ამ დროს დაუზიანებელი იყო (დარტყმის შემდეგ ან დეშის დროს).
func take_hit(damage: int, direction: Vector2, knockback := 1.0) -> bool:
	if _dead or is_invincible():
		return false
	_health = maxi(_health - damage, 0)
	_health_display.show_health(_health, max_health)
	_flash()

	if _is_dashing():
		_end_dash()
	velocity = Vector2(direction.x * hurt_knockback_speed, -hurt_knockback_hop) * knockback
	_hurt_timer = hurt_stun_time
	_hurt_invincible_timer = invincibility_time

	if _health <= 0:
		_die()
	return true


## true — ახლა ვერაფერი დააზიანებს.
func is_invincible() -> bool:
	return _hurt_invincible_timer > 0.0 or _dash_invincible_timer > 0.0


func _die() -> void:
	_dead = true
	_hurt_invincible_timer = 0.0
	_update_blink()
	# მთლიანად წითლდება და ასე რჩება.
	if _flash_tween:
		_flash_tween.kill()
	_material.set_shader_parameter("flash_amount", 1.0)
	# შეჩერებაც (hitstop) არ აჩქარებს/ანელებს ამ ლოდინს — ნამდვილი წამებია.
	await get_tree().create_timer(death_restart_delay, true, false, true).timeout
	get_tree().reload_current_scene()


# დარტყმისას წამიერად წითლდება.
func _flash() -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(_material, "shader_parameter/flash_amount", 0.0, hurt_flash_time).from(1.0)


# დარტყმის შემდეგ, სანამ დაუზიანებელია, პერსონაჟი ციმციმებს.
func _update_blink() -> void:
	var faded := _hurt_invincible_timer > 0.0 and fmod(_hurt_invincible_timer, BLINK_INTERVAL * 2.0) < BLINK_INTERVAL
	_visual.modulate.a = BLINK_OPACITY if faded else 1.0


func _respawn() -> void:
	if _is_dashing():
		_end_dash()
	global_position = _spawn_position
	velocity = Vector2.ZERO
	reset_physics_interpolation()
