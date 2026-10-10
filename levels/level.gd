extends Node2D
## დონის საერთო ლოგიკა. ჯერ მხოლოდ ერთი რამ: R ღილაკი დონეს თავიდან იწყებს.


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
