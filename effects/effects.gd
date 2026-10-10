extends Node
## თამაშის „შეგრძნების“ ეფექტები, რომლებიც ნებისმიერი სკრიპტიდან გამოიძახება:
##   Effects.hitstop(0.07) — დარტყმისას თამაში წამიერად ჩერდება,
##   Effects.shake(5.0)    — კამერა ირყევა.
##
## ეს სკრიპტი Autoload-ია: Godot მას თამაშის დაწყებისთანავე ტვირთავს.

## შეჩერებისას დრო ამდენჯერ ნელდება (0 = სრულიად ჩერდება, 1 = ჩვეულებრივი).
const HITSTOP_TIME_SCALE := 0.05
## რამდენად სწრაფად წყნარდება კამერის შერყევა.
const SHAKE_FADE := 14.0

var _in_hitstop := false
var _hitstop_end_msec := 0
var _shake_strength := 0.0


func _ready() -> void:
	# პაუზის დროსაც იმუშაოს.
	process_mode = Node.PROCESS_MODE_ALWAYS


## თამაშს `duration` წამით თითქმის აჩერებს — დარტყმა „მძიმედ“ იგრძნობა.
func hitstop(duration: float) -> void:
	_hitstop_end_msec = maxi(_hitstop_end_msec, Time.get_ticks_msec() + int(duration * 1000.0))
	_in_hitstop = true
	Engine.time_scale = HITSTOP_TIME_SCALE


## კამერას არყევს. `strength` — მაქსიმუმ რამდენი პიქსელით გადაიწიოს.
func shake(strength: float) -> void:
	_shake_strength = maxf(_shake_strength, strength)


func _process(delta: float) -> void:
	# შეჩერებისას delta-ც მცირდება, შერყევას კი ნამდვილი დრო სჭირდება.
	var real_delta := delta / maxf(Engine.time_scale, 0.001)

	if _in_hitstop and Time.get_ticks_msec() >= _hitstop_end_msec:
		_in_hitstop = false
		Engine.time_scale = 1.0

	_update_shake(real_delta)


func _update_shake(real_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	if _shake_strength < 0.1:
		_shake_strength = 0.0
		camera.offset = Vector2.ZERO
		return
	camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength
	_shake_strength = lerpf(_shake_strength, 0.0, 1.0 - exp(-SHAKE_FADE * real_delta))
