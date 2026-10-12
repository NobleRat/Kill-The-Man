class_name Sword
extends Node2D
## მახვილი: 3-დარტყმიანი კომბო, დაზიანების ზონა (Hitbox) და მოქნევის თეთრი რკალი.
##
## ყოველ დარტყმას სამი ფაზა აქვს:
##   მომზადება (windup)  — მოთამაშე ქარვისფრად იღებება, მახვილი იწევს;
##   ჭრა (active)        — მოქმედებს დაზიანების ზონა, ჩანს თეთრი რკალი;
##   დასვენება (recovery) — მოთამაშე ლურჯად იღებება, მახვილი ბრუნდება.
## დარტყმის შემდეგ მოკლე „ფანჯარაში“ ისევ დააჭერ — კომბოს შემდეგი დარტყმა იწყება.
## მესამე (ფინალური) დარტყმა ნელა იწყება, მაგრამ მეტ ზიანს აყენებს და შორს აგდებს.
## ყოველი დარტყმა მაუსის კურსორისკენ არის მიმართული.
##
## ყველა რიცხვი ქვემოთაა — Inspector-ში: Player → Visual → Sword.

## მოქნევა იწყება და მოთამაშე კურსორის მხარეს უნდა მიტრიალდეს
## (side: 1 = მარჯვნივ, -1 = მარცხნივ).
signal turn_requested(side: float)
## მახვილმა „ჭრა“ დაიწყო (მოთამაშე ამ დროს წინ გადადგამს ნაბიჯს).
signal swing_started
## მახვილი ვიღაცას მოხვდა.
signal hit_landed(target: Node2D)

@export_group("ფაზები")
## მომზადება: რამდენ წამს იწევს მახვილი (1-ლი და მე-2 დარტყმა).
@export var windup_time := 0.06
## ჭრა: რამდენ წამს მოქმედებს დაზიანების ზონა.
@export var active_time := 0.08
## დასვენება: რამდენ წამს ბრუნდება მახვილი მშვიდ მდგომარეობაში.
@export var recovery_time := 0.22
## მომზადებისას მოთამაშის ფერი (Alpha = რამდენად ძლიერად იღებება, 0 = საერთოდ არა).
@export var windup_tint := Color(1.0, 0.7, 0.25, 0.6)
## დასვენებისას მოთამაშის ფერი.
@export var recovery_tint := Color(0.35, 0.55, 1.0, 0.5)
## ჭრის რკალის ფერი.
@export var trail_color := Color(1.0, 1.0, 1.0, 0.85)

@export_group("კომბო")
## ჭრის დასრულებიდან ამდენი წამი გაქვს შემდეგი დარტყმისთვის.
## თუ დააგვიანე, კომბო პირველი დარტყმიდან იწყება.
@export var combo_window := 0.4
## დასვენების დაწყებიდან ამდენი წამის მერე შეიძლება შემდეგი დარტყმა.
@export var combo_delay := 0.08
## დარტყმის ღილაკი ამდენი წამით ადრე დაჭერილიც ჩაითვლება.
@export var input_buffer_time := 0.2

@export_group("დარტყმა 1 და 2")
## ზიანი.
@export var hit_damage := 1
## უკუგდების სიძლიერე (1 = მტრის ჩვეულებრივი უკუგდება).
@export var hit_knockback := 1.0
## მოხვედრისას თამაშის შეჩერება (hitstop), წამი.
@export var hit_hitstop := 0.05
## ეკრანის შერყევა პიქსელებში (0 = არ ირყევა).
@export var hit_shake := 0.0

@export_group("დარტყმა 3 (ფინალური)")
## მომზადება — უფრო ნელი, ვიდრე პირველ ორზე.
@export var finisher_windup_time := 0.18
## ზიანი.
@export var finisher_damage := 2
## უკუგდების სიძლიერე (1 = მტრის ჩვეულებრივი უკუგდება).
@export var finisher_knockback := 2.5
## მოხვედრისას თამაშის შეჩერება (hitstop), წამი.
@export var finisher_hitstop := 0.09
## ეკრანის შერყევა პიქსელებში.
@export var finisher_shake := 6.0

enum Phase { READY, WINDUP, ACTIVE, RECOVERY }

## მახვილის კუთხე მშვიდ მდგომარეობაში (გრადუსი: 0 = წინ, 90 = ქვემოთ, -90 = ზემოთ).
const REST_ANGLE := 130.0
## კომბოს დარტყმები: [საწყისი კუთხე, ბოლო კუთხე] გრადუსებში, კურსორის მიმართულების მიმართ
## (0 = პირდაპირ კურსორისკენ, ყოველი რკალის შუა კურსორზე მოდის).
const SWINGS := [
	[-78.0, 78.0],    # 1: ზემოდან ქვემოთ
	[82.0, -82.0],    # 2: ქვემოდან ზემოთ
	[-110.0, 105.0],  # 3: დიდი, ფართო მოქნევა ზემოდან
]
const TRAIL_INNER_RADIUS := 16.0
const TRAIL_OUTER_RADIUS := 52.0
const TRAIL_STEPS := 12
const TRAIL_FADE_TIME := 0.12

## true — ახალი მოქნევა ვერ დაიწყება (მაგ. დეშის დროს). დაჭერილი დარტყმა რიგში რჩება.
var locked := false

var _phase := Phase.READY
var _phase_time := 0.0
var _phase_start_angle := 0.0
var _buffer_timer := 0.0
## კომბოს „ფანჯრიდან“ დარჩენილი დრო (0 = კომბო თავიდან იწყება).
var _combo_timer := 0.0
var _swing_index := 0
var _next_swing := 0
## მიმდინარე მოქნევის მიმართულება (რადიანი): 0 = წინ, უარყოფითი = ზემოთ, დადებითი = ქვემოთ.
var _aim := 0.0
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


## მოთამაშის ფერი მიმდინარე ფაზაში (Alpha = სიძლიერე, 0 = არ იღებება).
func get_phase_tint() -> Color:
	match _phase:
		Phase.WINDUP:
			return windup_tint
		Phase.RECOVERY:
			return recovery_tint
	return Color(0.0, 0.0, 0.0, 0.0)


func _physics_process(delta: float) -> void:
	_buffer_timer -= delta
	_combo_timer -= delta
	_phase_time += delta

	match _phase:
		Phase.READY:
			if _buffer_timer > 0.0 and not locked:
				_start_swing()

		Phase.WINDUP:
			# მახვილი მოქნევის საწყის კუთხეზე ადის.
			var windup := _current_windup_time()
			var t := minf(_phase_time / windup, 1.0)
			_blade.rotation = lerp_angle(_phase_start_angle, deg_to_rad(SWINGS[_swing_index][0]) + _aim, t)
			if _phase_time >= windup:
				_enter_phase(Phase.ACTIVE)
				swing_started.emit()

		Phase.ACTIVE:
			# თვითონ მოქნევა: დასაწყისში სწრაფი, ბოლოში რბილი.
			var swing: Array = SWINGS[_swing_index]
			var t := minf(_phase_time / active_time, 1.0)
			t = 1.0 - (1.0 - t) * (1.0 - t)
			_blade.rotation = lerpf(deg_to_rad(swing[0]) + _aim, deg_to_rad(swing[1]) + _aim, t)
			_trail_from = deg_to_rad(swing[0]) + _aim
			_trail_to = _blade.rotation
			_trail_alpha = 1.0
			_check_hits()
			if _phase_time >= active_time:
				_enter_phase(Phase.RECOVERY)
				# ჭრა დასრულდა — იწყება კომბოს „ფანჯარა“.
				_combo_timer = combo_window

		Phase.RECOVERY:
			# მახვილი ნელ-ნელა მშვიდ მდგომარეობას უბრუნდება.
			var t := minf(_phase_time / recovery_time, 1.0)
			_blade.rotation = lerp_angle(_phase_start_angle, deg_to_rad(REST_ANGLE), smoothstep(0.0, 1.0, t))
			if _buffer_timer > 0.0 and _phase_time >= combo_delay and not locked:
				_start_swing()
			elif _phase_time >= recovery_time:
				_enter_phase(Phase.READY)

	if _phase != Phase.ACTIVE:
		_trail_alpha = maxf(_trail_alpha - delta / TRAIL_FADE_TIME, 0.0)
	queue_redraw()


func _start_swing() -> void:
	_buffer_timer = 0.0
	# ფანჯარა გავიდა — კომბო თავიდან.
	if _combo_timer <= 0.0:
		_next_swing = 0
	_swing_index = _next_swing
	_next_swing = (_next_swing + 1) % SWINGS.size()
	_hit_this_swing.clear()
	_aim_at_cursor()
	_enter_phase(Phase.WINDUP)


## true — მიმდინარე დარტყმა კომბოს ბოლო (მესამე) დარტყმაა.
func _is_finisher() -> bool:
	return _swing_index == SWINGS.size() - 1


func _current_windup_time() -> float:
	return finisher_windup_time if _is_finisher() else windup_time


# მოთამაშე კურსორის მხარეს ტრიალდება, მოქნევა და დაზიანების ზონა კი კურსორისკენ ბრუნდება.
func _aim_at_cursor() -> void:
	var to_cursor := get_global_mouse_position() - global_position
	var side := signf(to_cursor.x)
	if side == 0.0:
		side = signf(global_transform.x.x)
	turn_requested.emit(side)
	# მოთამაშე უკვე კურსორისკენ იყურება, ამიტომ კუთხეს „წინ“-ის მიმართ ვითვლით:
	# -90° (ზემოთ) ... 0° (წინ) ... 90° (ქვემოთ).
	_aim = Vector2(absf(to_cursor.x), to_cursor.y).angle()
	_hitbox.rotation = _aim


func _enter_phase(phase: Phase) -> void:
	_phase = phase
	_phase_time = 0.0
	_phase_start_angle = _blade.rotation


func _check_hits() -> void:
	# მარჯვნივ იყურება თუ მარცხნივ (Visual-ის გადაბრუნების გამო).
	var facing := signf(global_transform.x.x)
	var finisher := _is_finisher()
	var landed := false
	for body in _hitbox.get_overlapping_bodies():
		# ერთ მოქნევაში ერთ მტერს მხოლოდ ერთხელ ვურტყამთ.
		if body in _hit_this_swing or not body.has_method("take_hit"):
			continue
		_hit_this_swing.append(body)
		var damage := finisher_damage if finisher else hit_damage
		var knockback := finisher_knockback if finisher else hit_knockback
		body.take_hit(damage, Vector2(facing, 0.0), knockback)
		hit_landed.emit(body)
		landed = true

	# დარტყმის შეგრძნება: წამიერი შეჩერება, ფინალურზე — შერყევაც.
	if landed:
		Effects.hitstop(finisher_hitstop if finisher else hit_hitstop)
		var shake := finisher_shake if finisher else hit_shake
		if shake > 0.0:
			Effects.shake(shake)


# მოქნევის კვალი: თეთრი ნამგალი, რომელიც უკანა ბოლოსკენ ქრება.
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
