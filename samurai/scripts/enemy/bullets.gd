extends CharacterBody2D

var pos: Vector2
var rota: float
var dir: float
var speed = 50  # Increased speed for better visibility
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	global_position = pos
	global_rotation = rota
	print("Bullet ready - pos: ", pos, " dir: ", dir, " rota: ", rota)

# FIXED: Changed *physics*process to _physics_process
func _process(delta: float) -> void:
	position +=transform.x * speed * delta
	animated_sprite_2d.play("default")



func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		queue_free()


func _on_timer_timeout() -> void:
	queue_free()

func bullet():
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		body.player()
		queue_free()
