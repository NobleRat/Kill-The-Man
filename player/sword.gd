class_name Sword
extends Node2D
## მახვილი: მოქნევა, დაზიანების ზონა (Hitbox) და მოქნევის ნათელი კვალი.
##
## ორი მოქნევა მონაცვლეობით: ზემოდან ქვემოთ და ქვემოდან ზემოთ.
## თუ მოქნევის დროს ისევ დააჭერ დარტყმას, შემდეგი მოქნევა რიგში დგება (კომბო).

## მახვილმა „ჭრა“ დაიწყო (მოთამაშე ამ დროს წინ გადადგამს ნაბიჯს).
signal swing_started
## მახვილი ვიღაცას მოხვდა.
signal hit_landed(target: Node2D)

enum Phase { READY, WINDUP, ACTIVE, RECOVERY }

## მახვილის კუთხე მშვიდ მდგომარეობაში (გრადუსი: 0 = წინ, 90 = ქვემოთ, -90 = ზემოთ).
const REST_ANGLE := 130.0
## მოქნევები: [საწყისი კუთხე, ბოლო კუთხე] გრადუსებში.
const SWINGS := [
	[-115.0, 40.0],  # ზემოდან ქვემოთ
	[65.0, -100.0],  # ქვემოდან ზემოთ
]
const TRAIL_INNER_RADIUS := 16.0
const TRAIL_OUTER_RADIUS := 52.0
const TRAIL_STEPS := 12
const TRAIL_FADE_TIME := 0.12

## ერთი დარტყმის ზიანი.
@export var damage := 1
## მოქნევის მომზადება (წამი).
@export var windup_time := 0.06
## რამდენ ხანს „ჭრის“ მახვილი.
@export var active_time := 0.08
## მოქნევის შემდეგ დასვენება.
@export var recovery_time := 0.22
## დასვენების დაწყებიდან ამდენი წამის მერე შეიძლება შემდეგი მოქნევა.
@export var combo_delay := 0.08
## დარტყმის ღილაკი ამდენი წამით ადრე დაჭერილიც ჩაითვლება.
@export var input_buffer_time := 0.2
## მოქნევის კვალის ფერი.
@export var trail_color := Color(1.0, 0.9, 0.75, 0.8)

var _phase := Phase.READY
var _phase_time := 0.0
var _phase_start_angle := 0.0
var _buffer_timer := 0.0
var _swing_index := 0
var _next_swing := 0
var _hit_this_swing: Array[Node] = []
var _trail_alpha := 0.0
var _trail_from := 0.0
var _trail_to := 0.0

@onready var _blade: Node2D = $Blade
@onready var _hitbox: Area2D = $Hitbox


func _ready() -> void:
	_blade.rotation = deg_to_rad(REST_ANGLE)


## მოთამაშე იძახებს, როცა დარტყმის ღილაკს აჭერს.
func request_attack() -> void:
	_buffer_timer = input_buffer_time


## true — სანამ მახვილი იქნევა (ამ დროს მოთამაშე ვერ დარბის).
func is_busy() -> bool:
	return _phase == Phase.WINDUP or _phase == Phase.ACTIVE


func _physics_process(delta: float) -> void:
	_buffer_timer -= delta
	_phase_time += delta

	match _phase:
		Phase.READY:
			if _buffer_timer > 0.0:
				_start_swing()

		Phase.WINDUP:
			# მახვილი მოქნევის საწყის კუთხეზე ადის.
			var t := minf(_phase_time / windup_time, 1.0)
			_blade.rotation = lerp_angle(_phase_start_angle, deg_to_rad(SWINGS[_swing_index][0]), t)
			if _phase_time >= windup_time:
				_enter_phase(Phase.ACTIVE)
				swing_started.emit()

		Phase.ACTIVE:
			# თვითონ მოქნევა: დასაწყისში სწრაფი, ბოლოში რბილი.
			var swing: Array = SWINGS[_swing_index]
			var t := minf(_phase_time / active_time, 1.0)
			t = 1.0 - (1.0 - t) * (1.0 - t)
			_blade.rotation = lerpf(deg_to_rad(swing[0]), deg_to_rad(swing[1]), t)
			_trail_from = deg_to_rad(swing[0])
			_trail_to = _blade.rotation
			_trail_alpha = 1.0
			_check_hits()
			if _phase_time >= active_time:
				_enter_phase(Phase.RECOVERY)

		Phase.RECOVERY:
			# მახვილი ნელ-ნელა მშვიდ მდგომარეობას უბრუნდება.
			var t := minf(_phase_time / recovery_time, 1.0)
			_blade.rotation = lerp_angle(_phase_start_angle, deg_to_rad(REST_ANGLE), smoothstep(0.0, 1.0, t))
			if _buffer_timer > 0.0 and _phase_time >= combo_delay:
				_start_swing()
			elif _phase_time >= recovery_time:
				_enter_phase(Phase.READY)
				_next_swing = 0

	if _phase != Phase.ACTIVE:
		_trail_alpha = maxf(_trail_alpha - delta / TRAIL_FADE_TIME, 0.0)
	queue_redraw()


func _start_swing() -> void:
	_buffer_timer = 0.0
	_swing_index = _next_swing
	_next_swing = (_next_swing + 1) % SWINGS.size()
	_hit_this_swing.clear()
	_enter_phase(Phase.WINDUP)


func _enter_phase(phase: Phase) -> void:
	_phase = phase
	_phase_time = 0.0
	_phase_start_angle = _blade.rotation


func _check_hits() -> void:
	# მარჯვნივ იყურება თუ მარცხნივ (Visual-ის გადაბრუნების გამო).
	var facing := signf(global_transform.x.x)
	for body in _hitbox.get_overlapping_bodies():
		# ერთ მოქნევაში ერთ მტერს მხოლოდ ერთხელ ვურტყამთ.
		if body in _hit_this_swing or not body.has_method("take_hit"):
			continue
		_hit_this_swing.append(body)
		body.take_hit(damage, Vector2(facing, 0.0))
		hit_landed.emit(body)


# მოქნევის კვალი: ნათელი ნამგალი, რომელიც უკანა ბოლოსკენ ქრება.
func _draw() -> void:
	if _trail_alpha <= 0.0 or absf(_trail_to - _trail_from) < 0.05:
		return
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	for i in TRAIL_STEPS + 1:
		var weight := float(i) / TRAIL_STEPS
		points.append(Vector2.from_angle(lerpf(_trail_from, _trail_to, weight)) * TRAIL_OUTER_RADIUS)
		colors.append(_trail_color_at(weight))
	for i in range(TRAIL_STEPS, -1, -1):
		var weight := float(i) / TRAIL_STEPS
		points.append(Vector2.from_angle(lerpf(_trail_from, _trail_to, weight)) * TRAIL_INNER_RADIUS)
		colors.append(_trail_color_at(weight))
	draw_polygon(points, colors)


func _trail_color_at(weight: float) -> Color:
	var color := trail_color
	color.a *= _trail_alpha * weight
	return color
