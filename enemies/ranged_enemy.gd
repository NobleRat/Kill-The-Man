extends "res://enemies/enemy.gd"
## შორიდან მსროლელი მტერი (ჯადოქარი კვერთხით). დადის აქეთ-იქით; მოთამაშეს რომ
## შეამჩნევს — მანძილს იჭერს: ახლოს თუ მიხვედი, უკან იხევს, შორს თუ ხარ — ცოტას მოგიახლოვდება.
## რამდენიმე წამში ერთხელ ჩერდება, ნახევარი წამით ანათებს (კვერთხზე ბურთი იზრდება)
## და შენკენ ნელ ჭურვს ისვრის. ჭურვის განადგურება მახვილითაც შეიძლება.
##
## დარტყმის მიღება (ზიანი, უკუგდება, შეჩერება, თეთრი ციმციმი) და სიკვდილი
## ისეთივეა, როგორც სხვა მტრების — ის ნაწილი enemy.gd-შია.
## დარტყმა მომზადებას აწყვეტინებს.
##
## ყველა რიცხვი Inspector-შია: აირჩიეთ RangedEnemy კვანძი.

const PROJECTILE := preload("res://enemies/projectile.tscn")

@export_group("მანძილი")
## ამ მანძილზე (პიქსელი, გვერდულად) ამჩნევს მოთამაშეს — წინაც და ზურგსუკანაც.
@export var sight_range := 450.0
## მოთამაშე ამაზე მეტად მაღლა ან დაბლა თუ არის, ვერ ამჩნევს.
@export var sight_height := 160.0
## მოთამაშე ამაზე შორს თუ წავიდა, ისევ აქეთ-იქით დადის.
@export var lose_range := 650.0
## მოთამაშე ამაზე ახლოს თუ მოვიდა — უკან იხევს.
@export var too_close_distance := 220.0
## მოთამაშე ამაზე შორს თუ არის — ცოტას მიუახლოვდება. შუაში დგას და ისვრის.
@export var far_distance := 380.0
## უკან დახევის სიჩქარე (შენ 330-ით დარბიხარ — დაეწევი).
@export var retreat_speed := 110.0
## მიახლოების სიჩქარე.
@export var approach_speed := 80.0

@export_group("სროლა")
## სროლებს შორის შესვენება (წამი).
@export var shoot_interval := 2.5
## მოთამაშის შემჩნევიდან (ან დარტყმის მიღებიდან) პირველ სროლამდე დრო.
@export var first_shot_delay := 1.0
## მომზადება: რამდენ წამს ანათებს სროლამდე.
@export var windup_time := 0.5
## ნათების ფერი (ჭურვიც ამ ფერისაა).
@export var glow_color := Color(0.45, 0.95, 1.0)
## სროლის შემდეგ ამდენ წამს დგას.
@export var recovery_time := 0.35
## ჭურვის სიჩქარე (ნელია — შეგიძლია აარიდო, გადაახტე ან მახვილით გაანადგურო).
@export var projectile_speed := 240.0
## ჭურვის ზიანი: რამდენ HP-ს აკლებს მოთამაშეს.
@export var projectile_damage := 20

enum State { PATROL, ENGAGE, WINDUP, RECOVERY }

## ბურთის რადიუსი მომზადების დასაწყისში და ბოლოს.
const ORB_MIN_RADIUS := 2.0
const ORB_MAX_RADIUS := 8.0

var _state := State.PATROL
var _state_time := 0.0
## შემდეგ სროლამდე დარჩენილი დრო.
var _shoot_timer := 0.0
## მომზადება: 0 = არ ემზადება, 1 = სროლისთვის მზადაა.
var _charge := 0.0

@onready var _orb: Node2D = $Visual/Orb


func _ready() -> void:
	super()
	(_visual.material as ShaderMaterial).set_shader_parameter("tint_color", glow_color)
	_orb.draw.connect(_draw_orb)


func _act(delta: float) -> void:
	_state_time += delta
	match _state:
		State.PATROL:
			_patrol()
			if _player_within(sight_range, sight_height):
				_shoot_timer = first_shot_delay
				_set_state(State.ENGAGE)

		State.ENGAGE:
			if not _player_within(lose_range, INF):
				_set_state(State.PATROL)
				return
			_keep_distance(delta)
			_shoot_timer -= delta
			if _shoot_timer <= 0.0 and is_on_floor() and _player_within(sight_range, sight_height):
				_set_state(State.WINDUP)

		State.WINDUP:
			# დგას, მოთამაშეს უყურებს და ანათებს — რაც უფრო ახლოსაა სროლა, მით უფრო კაშკაშა.
			_brake(delta)
			_face_player()
			_charge = minf(_state_time / windup_time, 1.0)
			_set_tint(lerpf(0.35, 1.0, _charge))
			if _state_time >= windup_time:
				_shoot()
				_charge = 0.0
				_set_tint(0.0)
				_set_state(State.RECOVERY)

		State.RECOVERY:
			_brake(delta)
			if _state_time >= recovery_time:
				_shoot_timer = shoot_interval
				_set_state(State.ENGAGE)


# მანძილის დაჭერა: ახლოს — უკან იხევს, შორს — მიდის, შუაში — დგას. ყოველთვის მოთამაშეს უყურებს.
func _keep_distance(delta: float) -> void:
	_face_player()
	var distance := absf(_player.global_position.x - global_position.x)
	var move := 0.0
	if distance < too_close_distance:
		move = -_direction * retreat_speed
	elif distance > far_distance:
		move = _direction * approach_speed
	# კიდიდან არ ჩავარდება — მიყუჟული დგას და ისვრის.
	if move != 0.0 and is_on_floor() and not _has_floor_ahead(signf(move)):
		move = 0.0
	if move == 0.0:
		_brake(delta)
	else:
		velocity.x = move


func _shoot() -> void:
	var projectile := PROJECTILE.instantiate()
	var from := _orb.global_position
	# მოთამაშის სხეულის შუაში უმიზნებს (ფეხებიდან 32 პიქსელით ზემოთ).
	var target := _player.global_position + Vector2(0.0, -32.0)
	projectile.velocity = from.direction_to(target) * projectile_speed
	projectile.damage = projectile_damage
	projectile.color = glow_color
	projectile.position = (get_parent() as Node2D).to_local(from)
	get_parent().add_child(projectile)


## დარტყმის მიღება — enemy.gd-შია. აქ მხოლოდ სროლის მომზადება წყდება.
func take_hit(damage: int, direction: Vector2, knockback := 1.0) -> void:
	super(damage, direction, knockback)
	_charge = 0.0
	_set_tint(0.0)
	_shoot_timer = first_shot_delay
	_set_state(State.ENGAGE)


func _set_state(state: State) -> void:
	_state = state
	_state_time = 0.0


func _process(_delta: float) -> void:
	_orb.queue_redraw()


# კვერთხის ბურთი: მომზადებისას ჩნდება და იზრდება.
func _draw_orb() -> void:
	if _charge <= 0.0:
		return
	var radius := lerpf(ORB_MIN_RADIUS, ORB_MAX_RADIUS, _charge)
	_orb.draw_circle(Vector2.ZERO, radius * 2.2, Color(glow_color, 0.3))
	_orb.draw_circle(Vector2.ZERO, radius, glow_color)
	_orb.draw_circle(Vector2.ZERO, radius * 0.45, Color(1.0, 1.0, 1.0, 0.9))
