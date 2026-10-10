@tool
extends StaticBody2D
## მყარი მართკუთხედი: იატაკი, კედელი ან პლატფორმა.
##
## ზომა და ფერი Inspector-ში შეცვალეთ — დაჯახების ფორმა თავისით მოერგება.

## სიგანე და სიმაღლე პიქსელებში.
@export var size := Vector2(256, 64):
	set(value):
		size = value
		_apply_size()

## ფერი. სილუეტური სტილისთვის — შავი.
@export var color := Color.BLACK:
	set(value):
		color = value
		queue_redraw()

@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_apply_size()


func _draw() -> void:
	draw_rect(Rect2(-size / 2.0, size), color)


func _apply_size() -> void:
	# სანამ ბლოკი სცენაში არ ჩაჯდება, შვილი-კვანძები ჯერ არ არსებობს.
	if not is_node_ready():
		return
	(_collision.shape as RectangleShape2D).size = size
	queue_redraw()
