extends "res://enemies/enemy.gd"
## მძიმე მტერი: დიდი, ნელი, ჩაქუჩით და ბევრი სიცოცხლით.
##
## ჩვეულებრივი დარტყმა ადგილიდან ვერ ძრავს და თავდასხმას ვერ აწყვეტინებს —
## მხოლოდ კომბოს მესამე (ფინალური) დარტყმა უბიძგებს ოდნავ.
## ზიანი, თამაშის შეჩერება (hitstop) და თეთრი ციმციმი ისეთივეა, როგორც სხვა მტრებზე.
##
## თავდასხმა: გრძელი მომზადება — ნარინჯისფრად ანათებს, ჩაქუჩს თავს ზემოთ სწევს,
## ბოლოს კანკალებს, მიწაზე კი ზოლი ავსებს დარტყმის ზონას. ზოლი რომ შეივსება, ჩაქუჩს
## მიწას დაჰკრავს და მთელ ზონაში ძლიერ ზიანს აყენებს. გადარჩენა: დეშით გაიქეცი ან
## ზურგსუკან გადაძვერი — ზონა მხოლოდ წინ ვრცელდება, მომზადებისას კი აღარ ტრიალდება.
## ზონის ზომა = Hitbox-ის ზომა (Visual → Hitbox → CollisionShape2D).
##
## ყველა რიცხვი Inspector-შია: აირჩიეთ HeavyEnemy კვანძი.

const DASH_DUST := preload("res://effects/dash_dust.tscn")

@export_group("დევნა")
## ამ მანძილზე (პიქსელი, გვერდულად) ამჩნევს მოთამაშეს.
@export var sight_range := 320.0
## მოთამაშე ამაზე მეტად მაღლა ან დაბლა თუ არის, ვერ ამჩნევს.
@export var sight_height := 130.0
## მოთამაშე ამაზე შორს თუ წავიდა, ისევ აქეთ-იქით დადის.
@export var lose_range := 520.0
## დევნის სიჩქარე (ნელია: შენ 330-ით დარბიხარ).
@export var chase_speed := 60.0
## ამ მანძილზე მისვლისას ჩერდება და თავდასხმას იწყებს.
@export var attack_range := 140.0

@export_group("თავდასხმა")
## მომზადება: რამდენ წამს ანათებს და იწევს ჩაქუჩს.
@export var windup_time := 1.1
## მომზადების ფერი (დარტყმის ზონაც ამ ფერისაა).
@export var windup_color := Color(1.0, 0.45, 0.1)
## ჩაქუჩის ძირს დაშვების დრო.
@export var attack_time := 0.1
## დარტყმის მერე ამდენ წამს დგას (ჩაქუჩი მიწაშია) — შენი შანსი, რომ დაარტყა.
@export var recovery_time := 0.9
## ზიანი: რამდენ HP-ს აკლებს მოთამაშეს (მოთამაშეს სულ 100 აქვს).
@export var attack_damage := 40
## მოთამაშის უკუგდების სიძლიერე (1 = ჩვეულებრივი).
@export var attack_knockback := 1.8
## მოთამაშეს რომ მოხვდება — თამაშის შეჩერება (წამი).
@export var attack_hitstop := 0.14
## მოთამაშეს რომ მოხვდება — ეკრანის შერყევა (პიქსელი).
@export var attack_shake := 12.0
## ჩაქუჩის მიწაზე დარტყმა ეკრანს ყოველთვის არყევს, აცდენის დროსაც (პიქსელი).
@export var slam_shake := 5.0

@export_group("სიმძიმე")
## კომბოს მესამე დარტყმა რამდენად უბიძგებს (1 = როგორც ჩვეულებრივ მტერს, 0 = საერთოდ არ იძვრის).
## ჩვეულებრივი დარტყმა ყოველთვის ვერ ძრავს.
@export_range(0.0, 1.0) var finisher_push := 0.7

enum State { PATROL, CHASE, WINDUP, ATTACK, RECOVERY }

## ჩაქუჩის კუთხეები (გრადუსი: 0 = წინ, 90 = ქვემოთ, -90 = ზემოთ).
const HAMMER_REST := 75.0
const HAMMER_RAISED := -110.0
const HAMMER_SLAM := 80.0
## მომზადების რა ნაწილიდან იწყებს კანკალს (0.7 = ბოლო 30%) და რამდენ პიქსელზე.
const TREMBLE_FROM := 0.7
const TREMBLE_STRENGTH := 2.0
## ბიძგის შემდეგ ამდენ წამს არ მოძრაობს (რომ ბიძგი შესამჩნევი იყოს).
const PUSH_TIME := 0.25
## დარტყმის ზონის „აფეთქება“ რამდენ წამში ქრება.
const IMPACT_FADE_TIME := 0.3

var _state := State.PATROL
var _state_time := 0.0
## მომზადება: 0 = არ ემზადება, 1 = დარტყმისთვის მზადაა.
var _charge := 0.0
var _impact_alpha := 0.0
var _push_timer := 0.0
## დარტყმის ზონა Visual-ის კოორდინატებში (Hitbox-ის ზომიდან).
var _zone_rect := Rect2()

@onready var _hammer: Node2D = $Visual/Hammer
@onready var _hitbox: Area2D = $Visual/Hitbox
@onready var _zone: Node2D = $Visual/DangerZone


func _ready() -> void:
	super()
	_hammer.rotation = deg_to_rad(HAMMER_REST)
	(_visual.material as ShaderMaterial).set_shader_parameter("tint_color", windup_color)
	var shape := $Visual/Hitbox/CollisionShape2D as CollisionShape2D
	var size := (shape.shape as RectangleShape2D).size
	_zone_rect = Rect2(shape.position - size / 2.0, size)
	_zone.draw.connect(_draw_zone)


func _act(delta: float) -> void:
	_state_time += delta
	_push_timer -= delta
	match _state:
		State.PATROL:
			if _push_timer > 0.0:
				_brake(delta)
			else:
				_patrol()
			if _player_within(sight_range, sight_height):
				_set_state(State.CHASE)

		State.CHASE:
			_chase(delta)

		State.WINDUP:
			_brake(delta)
			_charge = minf(_state_time / windup_time, 1.0)
			# ჩაქუჩი პირველ 70%-ში ადის, მერე ზემოთ ჩერდება.
			var raise := smoothstep(0.0, 1.0, minf(_charge / TREMBLE_FROM, 1.0))
			_hammer.rotation = lerpf(deg_to_rad(HAMMER_REST), deg_to_rad(HAMMER_RAISED), raise)
			_set_tint(_charge)
			# ბოლოს კანკალებს — დარტყმა ახლოა.
			if _charge > TREMBLE_FROM:
				_visual.position.x = randf_range(-1.0, 1.0) * TREMBLE_STRENGTH
			if _state_time >= windup_time:
				_visual.position.x = 0.0
				_set_tint(0.0)
				_set_state(State.ATTACK)

		State.ATTACK:
			# ჩაქუჩი ძირს ეშვება და ჩქარდება.
			_brake(delta)
			var t := minf(_state_time / attack_time, 1.0)
			_hammer.rotation = lerpf(deg_to_rad(HAMMER_RAISED), deg_to_rad(HAMMER_SLAM), t * t)
			if _state_time >= attack_time:
				_impact()
				_set_state(State.RECOVERY)

		State.RECOVERY:
			# ჩაქუჩი ჯერ მიწაში რჩება, ბოლოს ნელა ადის.
			_brake(delta)
			var t := clampf((_state_time / recovery_time - 0.6) / 0.4, 0.0, 1.0)
			_hammer.rotation = lerpf(deg_to_rad(HAMMER_SLAM), deg_to_rad(HAMMER_REST), smoothstep(0.0, 1.0, t))
			if _state_time >= recovery_time:
				_set_state(State.CHASE)


func _chase(delta: float) -> void:
	if not _player_within(lose_range, INF):
		_set_state(State.PATROL)
		return
	if _push_timer > 0.0:
		_brake(delta)
		return

	_face_player()
	var offset := _player.global_position - global_position
	if absf(offset.x) <= attack_range:
		# ახლოსაა. თუ მოთამაშე ძალიან მაღლაა — ელოდება, სანამ ჩამოვა.
		_brake(delta)
		if absf(offset.y) <= sight_height:
			_set_state(State.WINDUP)
	elif is_on_floor() and not _has_floor_ahead(_direction):
		_brake(delta)
	else:
		velocity.x = _direction * chase_speed


# ჩაქუჩი მიწას ხვდება: ზონაში მყოფ მოთამაშეს ზიანი, ეკრანის შერყევა და მტვერი.
func _impact() -> void:
	_charge = 0.0
	_impact_alpha = 1.0
	Effects.shake(slam_shake)
	var dust_at := global_position + Vector2(_direction * _zone_rect.get_center().x, 0.0)
	_spawn_effect(DASH_DUST, dust_at, Vector2(1.0, -0.4))
	_spawn_effect(DASH_DUST, dust_at, Vector2(-1.0, -0.4))
	for body in _hitbox.get_overlapping_bodies():
		# take_hit აბრუნებს false-ს, თუ მოთამაშე ამ დროს დაუზიანებელია (მაგ. დეშის დროს).
		if body.has_method("take_hit") and body.take_hit(attack_damage, Vector2(_direction, 0.0), attack_knockback):
			Effects.hitstop(attack_hitstop)
			Effects.shake(attack_shake)


## ჩვეულებრივი დარტყმა (knockback 1) ვერ ძრავს; მხოლოდ კომბოს მესამე (ძლიერი) დარტყმა უბიძგებს ოდნავ.
## არც გაბრუვდება და არც მობრუნდება — დაწყებული თავდასხმა არ წყდება.
func _react_to_hit(direction: Vector2, knockback: float) -> void:
	if knockback <= 1.0 or finisher_push <= 0.0:
		return
	velocity.x = direction.x * knockback_speed * knockback * finisher_push
	_push_timer = PUSH_TIME


func _set_state(state: State) -> void:
	_state = state
	_state_time = 0.0


func _process(delta: float) -> void:
	_impact_alpha = maxf(_impact_alpha - delta / IMPACT_FADE_TIME, 0.0)
	_zone.queue_redraw()


# დარტყმის ზონა: მომზადებისას — ფერადი სვეტი და მიწაზე ზოლი, რომელიც ივსება;
# დარტყმისას — ღია „აფეთქება“, რომელიც ქრება.
func _draw_zone() -> void:
	# ზოლი მიწის ზედაპირზე (უმეტესად შავ მიწაზე, რომ კარგად ჩანდეს).
	var ground := Rect2(_zone_rect.position.x, -2.0, _zone_rect.size.x, 10.0)
	if _state == State.WINDUP and _health > 0:
		_zone.draw_rect(_zone_rect, Color(windup_color, 0.15 * _charge))
		# ზონის კიდეები — სადამდე აღწევს დარტყმა.
		var edge := Color(windup_color, 0.6 * _charge)
		_zone.draw_line(_zone_rect.position, Vector2(_zone_rect.position.x, 0.0), edge, 2.0)
		_zone.draw_line(Vector2(_zone_rect.end.x, _zone_rect.position.y), Vector2(_zone_rect.end.x, 0.0), edge, 2.0)
		_zone.draw_rect(ground, Color(windup_color, 0.35))
		_zone.draw_rect(Rect2(ground.position, Vector2(ground.size.x * _charge, ground.size.y)), windup_color)
	if _impact_alpha > 0.0:
		_zone.draw_rect(_zone_rect, Color(1.0, 0.85, 0.6, 0.45 * _impact_alpha))
		_zone.draw_rect(ground, Color(1.0, 0.95, 0.85, _impact_alpha))
