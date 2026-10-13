extends "res://enemies/enemy.gd"
## ხმლიანი მტერი. დადის აქეთ-იქით; მოთამაშეს რომ შეამჩნევს — მისკენ მიდის,
## ახლოს ჩერდება, წითლდება და ხმალს იწევს (მომზადება), მერე კი წინ ჩაქნევს.
##
## დარტყმის მიღება (ზიანი, უკუგდება, შეჩერება, თეთრი ციმციმი) და სიკვდილი
## ზუსტად ისეთივეა, როგორც მანეკენის — ის ნაწილი enemy.gd-შია.
## დარტყმა მომზადებას აწყვეტინებს: გაბრუების მერე ისევ მოთამაშისკენ წამოვა.
##
## ყველა რიცხვი Inspector-შია: აირჩიეთ MeleeEnemy კვანძი
## (დევნა, თავდასხმა; სიცოცხლე და სიარული — enemy.gd-ის ჯგუფებში).

@export_group("დევნა")
## ამ მანძილზე (პიქსელი, გვერდულად) ამჩნევს მოთამაშეს — წინაც და ზურგსუკანაც.
@export var sight_range := 280.0
## მოთამაშე ამაზე მეტად მაღლა ან დაბლა თუ არის (მაგ. ბაქანზე), ვერ ამჩნევს და არ ესხმის.
@export var sight_height := 90.0
## მოთამაშე ამაზე შორს თუ წავიდა, დევნას წყვეტს და ისევ აქეთ-იქით დადის.
@export var lose_range := 420.0
## დევნის სიჩქარე (შედარებისთვის: მოთამაშე 330-ით დარბის).
@export var chase_speed := 130.0
## ამ მანძილზე მისვლისას ჩერდება და თავდასხმას იწყებს.
@export var attack_range := 70.0

@export_group("თავდასხმა")
## მომზადება: რამდენ წამს წითლდება და იწევს ხმალს (ამ დროს შეიძლება გაქცევა).
@export var windup_time := 0.5
## მომზადების ფერი.
@export var windup_color := Color(1.0, 0.12, 0.08)
## ჭრა: რამდენ წამს მოქმედებს დაზიანების ზონა.
@export var attack_time := 0.12
## ჭრისას წინ გადადგმული ნაბიჯის სიჩქარე.
@export var attack_lunge := 220.0
## დასვენება: დარტყმის მერე ამდენ წამს დგას — შენი შანსი, რომ დაარტყა.
@export var recovery_time := 0.5
## რამდენ სიცოცხლეს აკლებს მოთამაშეს.
@export var attack_damage := 1
## მოთამაშის უკუგდების სიძლიერე (1 = ჩვეულებრივი, ზომები — Player-ის ჯგუფში „სიცოცხლე“).
@export var attack_knockback := 1.0
## მოთამაშეს რომ მოხვდება — თამაშის შეჩერება (წამი).
@export var attack_hitstop := 0.08
## მოთამაშეს რომ მოხვდება — ეკრანის შერყევა (პიქსელი).
@export var attack_shake := 5.0
## ჭრის რკალის ფერი.
@export var slash_color := Color(1.0, 0.8, 0.75, 0.95)

enum State { PATROL, CHASE, WINDUP, ATTACK, RECOVERY }

## ხმლის კუთხეები (გრადუსი: 0 = წინ, 90 = ქვემოთ, -90 = ზემოთ).
const WEAPON_REST := 50.0
const WEAPON_RAISED := -135.0
const WEAPON_SWUNG := 65.0
const SLASH_INNER_RADIUS := 18.0
const SLASH_OUTER_RADIUS := 66.0
const SLASH_STEPS := 16
const SLASH_FADE_TIME := 0.15

var _state := State.PATROL
var _state_time := 0.0
## ამ ჭრამ მოთამაშეს უკვე მოარტყა (ერთ ჭრაში — მხოლოდ ერთხელ).
var _hit_player := false
var _player: Node2D
var _slash_alpha := 0.0
var _slash_to := 0.0

@onready var _weapon: Node2D = $Visual/Weapon
@onready var _hitbox: Area2D = $Visual/Hitbox
@onready var _slash: Node2D = $Visual/Slash
@onready var _material: ShaderMaterial = $Visual.material


func _ready() -> void:
	super()
	_weapon.rotation = deg_to_rad(WEAPON_REST)
	_material.set_shader_parameter("tint_color", windup_color)
	_slash.draw.connect(_draw_slash)


func _act(delta: float) -> void:
	_state_time += delta
	match _state:
		State.PATROL:
			_patrol()
			if _player_within(sight_range, sight_height):
				_set_state(State.CHASE)

		State.CHASE:
			_chase()

		State.WINDUP:
			# დგას, წითლდება და ხმალს თავს ზემოთ სწევს. მხარეს აღარ იცვლის —
			# ზურგსუკან თუ გადახვედი, ცარიელ ადგილს დაარტყამს.
			_brake(delta)
			var t := minf(_state_time / windup_time, 1.0)
			_weapon.rotation = lerpf(deg_to_rad(WEAPON_REST), deg_to_rad(WEAPON_RAISED), ease(t, 0.3))
			_set_tint(lerpf(0.6, 1.0, t))
			if _state_time >= windup_time:
				_set_tint(0.0)
				_set_state(State.ATTACK)
				velocity.x = _direction * attack_lunge

		State.ATTACK:
			# ჭრა: დასაწყისში სწრაფი, ბოლოში რბილი.
			var t := minf(_state_time / attack_time, 1.0)
			t = 1.0 - (1.0 - t) * (1.0 - t)
			_weapon.rotation = lerpf(deg_to_rad(WEAPON_RAISED), deg_to_rad(WEAPON_SWUNG), t)
			_slash_to = _weapon.rotation
			_slash_alpha = 1.0
			_check_hit()
			if _state_time >= attack_time:
				_set_state(State.RECOVERY)

		State.RECOVERY:
			_brake(delta)
			var t := minf(_state_time / recovery_time, 1.0)
			_weapon.rotation = lerpf(deg_to_rad(WEAPON_SWUNG), deg_to_rad(WEAPON_REST), smoothstep(0.0, 1.0, t))
			if _state_time >= recovery_time:
				_set_state(State.CHASE)


func _chase() -> void:
	if not _player_within(lose_range, INF):
		_set_state(State.PATROL)
		return

	var offset := _player.global_position - global_position
	if offset.x != 0.0:
		_direction = signf(offset.x)
	_visual.scale.x = _direction

	if absf(offset.x) <= attack_range:
		# ახლოსაა. თუ მოთამაშე თავზე დგას ან ხტება — ელოდება, სანამ ჩამოვა.
		velocity.x = 0.0
		if absf(offset.y) <= sight_height:
			_set_state(State.WINDUP)
	elif is_on_floor() and not _has_floor_ahead(_direction):
		# კიდეზე ჩერდება — მოთამაშის გამო ორმოში არ გადავარდება.
		velocity.x = 0.0
	else:
		velocity.x = _direction * chase_speed


## მოთამაშე ახლოსაა? (გვერდულად `range_x`-ზე, სიმაღლით `range_y`-ზე ახლოს.)
func _player_within(range_x: float, range_y: float) -> bool:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		if _player == null:
			return false
	var offset := _player.global_position - global_position
	return absf(offset.x) <= range_x and absf(offset.y) <= range_y


func _check_hit() -> void:
	if _hit_player:
		return
	for body in _hitbox.get_overlapping_bodies():
		# take_hit აბრუნებს false-ს, თუ მოთამაშე ამ დროს დაუზიანებელია (მაგ. დეშის დროს) —
		# მაშინ ჭრა გრძელდება და დეშის დასრულების მერეც შეიძლება მოხვდეს.
		if body.has_method("take_hit") and body.take_hit(attack_damage, Vector2(_direction, 0.0), attack_knockback):
			_hit_player = true
			Effects.hitstop(attack_hitstop)
			Effects.shake(attack_shake)
			return


## დარტყმის მიღება — enemy.gd-შია. აქ მხოლოდ თავდასხმა წყდება.
func take_hit(damage: int, direction: Vector2, knockback := 1.0) -> void:
	super(damage, direction, knockback)
	_set_tint(0.0)
	_weapon.rotation = deg_to_rad(WEAPON_REST)
	_set_state(State.CHASE)


func _set_state(state: State) -> void:
	_state = state
	_state_time = 0.0
	if state == State.ATTACK:
		_hit_player = false


func _brake(delta: float) -> void:
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


func _set_tint(amount: float) -> void:
	_material.set_shader_parameter("tint_amount", amount)


func _process(delta: float) -> void:
	if _state != State.ATTACK:
		_slash_alpha = maxf(_slash_alpha - delta / SLASH_FADE_TIME, 0.0)
	_slash.queue_redraw()


# ჭრის კვალი: ნამგალი ხმლის აწეული მდგომარეობიდან მის ახლანდელ მდგომარეობამდე,
# რომელიც უკანა ბოლოსკენ ქრება.
func _draw_slash() -> void:
	var from := deg_to_rad(WEAPON_RAISED)
	if _slash_alpha <= 0.0 or absf(_slash_to - from) < 0.05:
		return
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	for i in SLASH_STEPS + 1:
		var weight := float(i) / SLASH_STEPS
		points.append(Vector2.from_angle(lerpf(from, _slash_to, weight)) * SLASH_OUTER_RADIUS)
		colors.append(_slash_color_at(weight))
	for i in range(SLASH_STEPS, -1, -1):
		var weight := float(i) / SLASH_STEPS
		points.append(Vector2.from_angle(lerpf(from, _slash_to, weight)) * SLASH_INNER_RADIUS)
		colors.append(_slash_color_at(weight))
	_slash.draw_polygon(points, colors)


func _slash_color_at(weight: float) -> Color:
	var color := slash_color
	color.a *= _slash_alpha * weight
	return color
