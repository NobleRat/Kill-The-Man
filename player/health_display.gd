extends Control
## მოთამაშის სიცოცხლე ეკრანის ზედა მარცხენა კუთხეში:
## ერთი მართკუთხედი = ერთი სიცოცხლე, დაკარგული სიცოცხლე — ცარიელი ჩარჩო.

## ერთი უჯრის ზომა (პიქსელი).
@export var cell_size := Vector2(22.0, 14.0)
## უჯრებს შორის მანძილი.
@export var cell_gap := 6.0
## სავსე უჯრის ფერი.
@export var full_color := Color(0.95, 0.88, 0.75)
## დაკარგული სიცოცხლის უჯრის ფერი.
@export var empty_color := Color(0.0, 0.0, 0.0, 0.5)

var _health := 0
var _max_health := 0


## მოთამაშე იძახებს, როცა სიცოცხლე იცვლება.
func show_health(health: int, max_health: int) -> void:
	_health = health
	_max_health = max_health
	queue_redraw()


func _draw() -> void:
	for i in _max_health:
		var rect := Rect2(Vector2(i * (cell_size.x + cell_gap), 0.0), cell_size)
		draw_rect(rect, full_color if i < _health else empty_color)
		# ჩარჩო, რომ ცარიელი უჯრაც ჩანდეს.
		draw_rect(rect, Color(full_color, 0.6), false, 2.0)
