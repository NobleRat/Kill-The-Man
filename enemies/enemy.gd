extends CharacterBody2D
## მტერი-„მანეკენი“: დადის აქეთ-იქით. დარტყმისას უკან ეგდება და ციმციმებს,
## სიცოცხლე რომ გაუთავდება — ნამსხვრევებად იშლება.
##
## თავს არ ესხმის. თავდამსხმელი მტერი — melee_enemy.gd — ამ სკრიპტზეა აგებული:
## დარტყმის მიღება და სიკვდილი ორივესთვის აქ არის დაწერილი.

const HIT_SPARK := preload("res://effects/hit_spark.tscn")
const DEATH_BURST := preload("res://effects/death_burst.tscn")

@export_group("სიცოცხლე")
## რამდენ დარტყმას უძლებს.
@export var max_health := 5

@export_group("სიარული")
## სიარულის სიჩქარე.
@export var walk_speed := 70.0
## საწყისი ადგილიდან რამდენ პიქსელზე დადის მარცხნივ და მარჯვნივ.
@export var patrol_distance := 120.0
## სიმძიმე.
@export var gravity := 2000.0
## რამდენად სწრაფად ჩერდება მიწაზე.
@export var friction := 1600.0

@export_group("დარტყმის რეაქცია")
## დარტყმისას რა სიჩქარით გადაიწევს უკან (მახვილის knockback ამაზე მრავლდება).
@export var knockback_speed := 160.0
## დარტყმისას რამდენად ახტება ზემოთ.
@export var knockback_hop := 120.0
## დარტყმის შემდეგ ამდენ წამს ვერ მოძრაობს.
@export var stun_time := 0.3

@export_group("დარტყმის შეგრძნება")
## თეთრი ციმციმის ხანგრძლივობა დარტყმისას (წამი).
@export var flash_time := 0.15
## სიკვდილისას თამაშის შეჩერება (წამი).
## (ჩვეულებრივი დარტყმის შეჩერება/შერყევა მახვილის სკრიპტშია: sword.gd.)
@export var death_hitstop := 0.14
## სიკვდილისას ეკრანის შერყევა (პიქსელი).
@export var death_shake := 12.0

var _health := 0
## 1 = მარჯვნივ მიდის, -1 = მარცხნივ.
var _direction := 1.0
var _stun_timer := 0.0
var _start_x := 0.0
var _flash_tween: Tween

@onready var _visual: Node2D = $Visual
@onready var _health_bar: Node2D = $HealthBar
@onready var _health_fill: Control = $HealthBar/Fill


func _ready() -> void:
	_health = max_health
	_start_x = global_position.x
	_health_bar.visible = false


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if _stun_timer > 0.0:
		_stun_timer -= delta
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	else:
		_act(delta)

	move_and_slide()


## რას აკეთებს, როცა გაბრუებული არ არის. მანეკენი მხოლოდ დადის;
## სხვა მტრები (მაგ. melee_enemy.gd) ამ ფუნქციას თავისით ცვლიან.
func _act(_delta: float) -> void:
	_patrol()


func _patrol() -> void:
	# საზღვარს, კედელს ან კიდეს მიადგა — მობრუნდეს.
	var offset := global_position.x - _start_x
	var past_right := offset > patrol_distance and _direction > 0.0
	var past_left := offset < -patrol_distance and _direction < 0.0
	var wall_ahead := is_on_wall() and signf(get_wall_normal().x) == -_direction
	var ledge_ahead := is_on_floor() and not _has_floor_ahead(_direction)
	if past_right or past_left or wall_ahead or ledge_ahead:
		_direction = -_direction

	velocity.x = _direction * walk_speed
	_visual.scale.x = _direction


## true — წინ (`direction` მხარეს) ფეხქვეშ მიწაა; false — კიდეა, შეიძლება ჩავარდეს.
func _has_floor_ahead(direction: float) -> bool:
	var from := global_position + Vector2(direction * 22.0, -4.0)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0.0, 30.0), collision_mask, [get_rid()])
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


## მახვილი იძახებს, როცა მტერს მოხვდება. `direction` — დარტყმის მიმართულება,
## `knockback` — რამდენჯერ ძლიერად გადააგდოს (1 = ჩვეულებრივად).
func take_hit(damage: int, direction: Vector2, knockback := 1.0) -> void:
	if _health <= 0:
		return
	_health -= damage
	_update_health_bar()
	_flash()
	_spawn_effect(HIT_SPARK, global_position + Vector2(-direction.x * 10.0, -40.0), direction)

	# უკან გადაგდება და დამრტყმელისკენ მობრუნება.
	velocity = Vector2(direction.x * knockback_speed, -knockback_hop) * knockback
	_stun_timer = stun_time
	if direction.x != 0.0:
		_direction = -signf(direction.x)
		_visual.scale.x = _direction

	if _health <= 0:
		_die()


func _die() -> void:
	Effects.hitstop(death_hitstop)
	Effects.shake(death_shake)
	_health_bar.visible = false
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)

	# შეჩერების დროს მტერი თეთრად ანათებს, მერე კი ნამსხვრევებად იშლება.
	await get_tree().create_timer(death_hitstop, true, false, true).timeout
	_spawn_effect(DEATH_BURST, global_position + Vector2(0.0, -36.0), Vector2.UP)
	queue_free()


func _flash() -> void:
	var flash_material := _visual.material as ShaderMaterial
	if _flash_tween:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(flash_material, "shader_parameter/flash_amount", 0.0, flash_time).from(1.0)


func _update_health_bar() -> void:
	_health_bar.visible = true
	_health_fill.scale.x = clampf(float(_health) / max_health, 0.0, 1.0)


func _spawn_effect(scene: PackedScene, at: Vector2, direction: Vector2) -> void:
	var effect := scene.instantiate() as CPUParticles2D
	var parent := get_parent() as Node2D
	effect.direction = direction
	effect.position = parent.to_local(at)
	parent.add_child(effect)
