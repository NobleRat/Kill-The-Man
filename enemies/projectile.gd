extends Area2D
## ჭურვი: მანათობელი ბურთი, რომელიც ნელა მიფრინავს ერთი მიმართულებით.
## მოთამაშეს თუ მოხვდა — ზიანს აყენებს და ქრება; კედელს ან მიწას თუ მოხვდა — ქრება.
## მოთამაშის მახვილს შეუძლია გაანადგუროს. დეშის დროს მოთამაშეში გაფრინდება.
##
## სიჩქარეს, ზიანს და ფერს მას მსროლელი მტერი (ranged_enemy.gd) ანიჭებს.

const HIT_SPARK := preload("res://effects/hit_spark.tscn")

## რამდენ წამში ქრება თავისით, თუ ვერაფერს მოხვდა.
@export var lifetime := 4.0
## ბურთის რადიუსი სახატავად (შეხების ზომა — CollisionShape2D-შია).
@export var radius := 7.0
## მოთამაშეს რომ მოხვდება — თამაშის შეჩერება (წამი).
@export var hit_hitstop := 0.06
## მოთამაშეს რომ მოხვდება — ეკრანის შერყევა (პიქსელი).
@export var hit_shake := 4.0

## სიჩქარე და მიმართულება (პიქსელი წამში).
var velocity := Vector2.ZERO
## რამდენ HP-ს აკლებს მოთამაშეს.
var damage := 20
var color := Color(0.45, 0.95, 1.0)

var _age := 0.0
var _gone := false


func _ready() -> void:
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	position += velocity * delta

	for body in get_overlapping_bodies():
		if not body.has_method("take_hit"):
			# კედელი ან მიწა.
			_burst()
			return
		# მოთამაშე. თუ ამ დროს დაუზიანებელია (მაგ. დეშის დროს), ჭურვი გაფრინდება.
		if body.take_hit(damage, Vector2(signf(velocity.x), 0.0), 1.0):
			Effects.hitstop(hit_hitstop)
			Effects.shake(hit_shake)
			_burst()
			return


func _process(_delta: float) -> void:
	queue_redraw()


## მოთამაშის მახვილი იძახებს — ჭურვი ნადგურდება.
func take_hit(_damage: int, _direction: Vector2, _knockback := 1.0) -> void:
	_burst()


# ნაპერწკლებად იშლება.
func _burst() -> void:
	if _gone:
		return
	_gone = true
	set_physics_process(false)
	var spark := HIT_SPARK.instantiate() as CPUParticles2D
	spark.position = position
	spark.direction = -velocity.normalized()
	spark.spread = 180.0
	spark.color = color
	get_parent().add_child(spark)
	queue_free()


func _draw() -> void:
	var pulse := 1.0 + 0.15 * sin(_age * 20.0)
	draw_circle(Vector2.ZERO, radius * 2.2 * pulse, Color(color, 0.25))
	draw_circle(Vector2.ZERO, radius * pulse, color)
	draw_circle(Vector2.ZERO, radius * 0.45, Color(1.0, 1.0, 1.0, 0.9))
