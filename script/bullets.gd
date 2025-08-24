extends CharacterBody2D

var pos: Vector2
var rota: float
var dir: float
var speed = 150  # Increased speed for better visibility

func _ready() -> void:
	global_position = pos
	global_rotation = rota
	owner = get_parent()
	print(owner.name ," Bullet ready - pos: ", pos, " dir: ", dir, " rota: ", rota)

# FIXED: Changed *physics*process to _physics_process
func _process(delta: float) -> void:
	position +=transform.x * speed * delta


func _on_body_entered(body: Node2D) -> void:
	print(body.name)


func _on_timer_timeout() -> void:
	queue_free()

func bullet():
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name != "BossNegga":
		print(body.name, " Took 1 damage")
		body.take_damage(1)
