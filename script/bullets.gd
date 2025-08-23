extends CharacterBody2D

var pos: Vector2
var rota: float
var dir: float
var speed = 50  # Increased speed for better visibility

func _ready() -> void:
	global_position = pos
	global_rotation = rota
	print("Bullet ready - pos: ", pos, " dir: ", dir, " rota: ", rota)

# FIXED: Changed *physics*process to _physics_process
func _physics_process(delta: float) -> void:
	velocity = Vector2(speed, 0).rotated(dir)
	move_and_slide()
	print("Bullet velocity: ", velocity)
		# Dessiner une ligne pour voir le trajet
	print("Frame: Bullet at ", global_position)
	
	# Check if bullet collided with something
	if is_on_wall() or is_on_floor() or is_on_ceiling():
		print("Bullet hit something, destroying...")
		await get_tree().create_timer(1).timeout
		queue_free()
	
	# Alternative method - check for any collision
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		print("Bullet collided with: ", collision.get_collider().name)
		if collision.get_collider().name == "flying_enemy":
			continue
		else:
			queue_free()
			break

func bullet():
	pass
