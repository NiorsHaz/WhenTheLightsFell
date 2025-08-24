extends CharacterBody2D

var pos: Vector2
var rota: float
var dir: float
var speed = 200
var ignore_bodies: Array[String] = ["flying_enemy", "BossNegga"]  # Bodies to ignore
var lifetime: float = 20.0  # Bullet lifetime in seconds
var time_alive: float = 0.0

func _ready() -> void:
	global_position = pos
	global_rotation = rota
	_setup_collision_exceptions()
	#print("Bullet ready - pos: ", pos, " dir: ", dir, " rota: ", rota)

func _setup_collision_exceptions() -> void:
	# Find and add collision exceptions for ignored bodies
	for body_name in ignore_bodies:
		var body = get_node_or_null("../" + body_name)
		if body and body is CollisionObject2D:
			# Add collision exception so bullet passes through
			add_collision_exception_with(body)
			print("Added collision exception for: ", body_name)

func _physics_process(delta: float) -> void:
	# Update lifetime
	time_alive += delta
	if time_alive >= lifetime:
		print("Bullet expired after ", lifetime, " seconds")
		print("bullet speed",speed)
		queue_free()
		return
	
	velocity = Vector2(speed, 0).rotated(dir)
	move_and_slide()
	
	# Check for collisions (now only with non-ignored bodies)
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		print("Bullet collided with: ", collider.name, " (type: ", collider.get_class(), ")")
		
		# Check if it's environment (StaticBody2D, TileMap, etc.)
		if collider is StaticBody2D or collider is TileMap:
			print("Bullet hit environment: ", collider.name)
			queue_free()
			return
		
		# Check if it's a CharacterBody2D (player, other enemies)
		if collider is CharacterBody2D:
			# Damage the target if it can take damage
			const damage_amount = 0
			if collider.has_method("take_damage"):
				collider.take_damage(damage_amount)
				print("Bullet dealt damage to: ", collider.name)
			
			# Destroy bullet after hitting a character
			queue_free()
			return

func bullet():
	pass
