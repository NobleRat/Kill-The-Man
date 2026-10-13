extends Control
## მოთამაშის სიცოცხლის ზოლი ეკრანის ზედა მარცხენა კუთხეში.
## წითელი ზოლი — დარჩენილი სიცოცხლე, შიგნით კი რიცხვით: „დარჩენილი / მაქსიმალური“.
## დარტყმისას წითელი ზოლი სწრაფად მოკლდება, დაკარგული ნაწილი კი წამით ღია ფერით რჩება.
##
## ფერები და ზომა — შვილ კვანძებში: Fill (წითელი ზოლი), Trail (დაკარგული ნაწილი),
## Back (ცარიელი ფონი), Frame (ჩარჩო), Text (რიცხვი).

## რამდენ წამში მოკლდება წითელი ზოლი ახალ მნიშვნელობამდე.
@export var shrink_time := 0.15
## დაკარგული ნაწილი (ღია ზოლი) ამდენ წამს ჩერდება...
@export var trail_delay := 0.35
## ...და მერე ამდენ წამში ქრება.
@export var trail_time := 0.3

var _tween: Tween

@onready var _fill: Control = $Fill
@onready var _trail: Control = $Trail
@onready var _text: Label = $Text


## მოთამაშე იძახებს, როცა სიცოცხლე იცვლება.
func show_health(health: int, max_health: int) -> void:
	_text.text = "%d / %d" % [health, max_health]
	var ratio := clampf(float(health) / max_health, 0.0, 1.0)
	if _tween:
		_tween.kill()
	if ratio >= _fill.scale.x:
		# სიცოცხლე არ შემცირებულა (მაგ. თამაშის დასაწყისი) — ზოლი მაშინვე ივსება.
		_fill.scale.x = ratio
		_trail.scale.x = ratio
		return
	_tween = create_tween()
	# თამაშის წამიერი შეჩერება (hitstop) ზოლს არ აჩერებს.
	_tween.set_ignore_time_scale()
	_tween.tween_property(_fill, "scale:x", ratio, shrink_time)
	_tween.tween_interval(trail_delay)
	_tween.tween_property(_trail, "scale:x", ratio, trail_time)
