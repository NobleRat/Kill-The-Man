extends CPUParticles2D
## ერთჯერადი ნაწილაკები: ჩნდება, ერთხელ „იფეთქებს“ და თავისით ქრება.


func _ready() -> void:
	finished.connect(queue_free)
	emitting = true
