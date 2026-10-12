extends Node2D
## დეშის „ანარეკლი“: პერსონაჟის გაყინული სილუეტი, რომელიც ნელ-ნელა ქრება.

## რამდენ წამში ქრება ბოლომდე.
var fade_time := 0.25

var _shapes: Array[PackedVector2Array] = []
var _colors := PackedColorArray()


func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(queue_free)


## სილუეტს „იღებს“ source-ის მართკუთხედებიდან (Polygon2D შვილებიდან),
## იმავე ადგილას, იმავე პოზაში. opacity — რამდენად გამჭვირვალეა (0..1).
func copy_from(source: Node2D, opacity: float) -> void:
	global_transform = source.global_transform
	for child in source.get_children():
		var shape := child as Polygon2D
		if shape == null or not shape.visible:
			continue
		_shapes.append(shape.transform * shape.polygon)
		var color := shape.color
		color.a *= opacity
		_colors.append(color)
	reset_physics_interpolation()
	queue_redraw()


func _draw() -> void:
	for i in _shapes.size():
		draw_colored_polygon(_shapes[i], _colors[i])
