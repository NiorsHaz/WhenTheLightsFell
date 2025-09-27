extends CharacterBody2D

var speed = 25
var dead = false
var player_in_area = false
var player
@onready var attack_box: Area2D = $attackBox
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

var random_walk_timer = 0.0
var random_walk_direction = 0
var is_moving_randomly = false
var random_walk_duration = 0.0
var pause_timer = 0.0

var is_facing_right = true
var detection_margin = 20

var spawn_position: Vector2
var patrol_range = 200.0 
var returning_to_spawn = false
var return_speed = 25.0  

func _ready() -> void:
	dead = false
	spawn_position = position 

func _physics_process(delta: float) -> void:
	
	if is_facing_right:
		attack_box.scale.x = 1
	else:
		attack_box.scale.x = -1
	if not is_on_floor():
		velocity += get_gravity() * delta
	if !dead:
		$PlayerDetectionArea/CollisionShape2D.disabled = false
		#print("A droite ? :" , is_facing_right)
		
		if player_in_area:
			# Suivre le joueur si détecté
			var direction_to_player = sign(player.position.x - position.x)
			position.x += direction_to_player * speed * get_physics_process_delta_time()
			
			is_facing_right = direction_to_player > 0
			$AnimatedSprite.flip_h = !is_facing_right # direction_to_player < 0
			animated_sprite.play("Rampage")
			await animated_sprite.animation_finished
			var players=attack_box.get_overlapping_bodies()
			for player in players :
				if player.has_method("player"):
					player.player()

			is_moving_randomly = false
			returning_to_spawn = false
		else:
			if position.distance_to(spawn_position) > patrol_range && !returning_to_spawn:
				returning_to_spawn = true
				is_moving_randomly = false
			
			if returning_to_spawn:
				handle_return_to_spawn(delta)
			else:
				handle_random_walk(delta)
			
		if dead:
			$PlayerDetectionArea/CollisionShape2D.disabled = true
	move_and_slide()	

func handle_return_to_spawn(delta: float) -> void:
	var direction = (spawn_position - position).normalized()
	position += direction * return_speed * delta
	$AnimatedSprite.play("Move")
	is_facing_right = direction.x > 0
	$AnimatedSprite.flip_h = !is_facing_right  # flip hitbox based on facing direction
# direction.x < 0
	
	if position.distance_to(spawn_position) < 10.0:
		returning_to_spawn = false
		pause_timer = 0.0  # Reset le timer pour une pause avant de repartir

func handle_random_walk(delta: float) -> void:
	if !is_moving_randomly:
		pause_timer += delta
		$AnimatedSprite.play("Idle")
		
		if pause_timer >= 2.0:
			is_moving_randomly = true
			random_walk_direction = randi() % 3 - 1
			random_walk_duration = randf_range(0.5, 2.0)
			random_walk_timer = 0.0
			pause_timer = 0.0
	else:
		random_walk_timer += delta
		
		if random_walk_timer < random_walk_duration:
			if random_walk_direction != 0:
				var new_position = position + Vector2(random_walk_direction * speed * delta, 0)
				

				if abs(new_position.x - spawn_position.x) <= patrol_range:
					position = new_position
					is_facing_right = random_walk_direction > 0
					$AnimatedSprite.play("Move")
					$AnimatedSprite.flip_h = !is_facing_right # random_walk_direction < 0
				else:

					random_walk_direction *= -1
					$AnimatedSprite.flip_h = !is_facing_right # random_walk_direction < 0
			else:
				$AnimatedSprite.play("Idle")
		else:
			is_moving_randomly = false
			$AnimatedSprite.play("Idle")

func _on_player_detection_area_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		speed = 50
		if is_facing_right and body.position.x > position.x:
			player_in_area = true
			player = body
		elif !is_facing_right and body.position.x < position.x:
			player_in_area = true
			player = body
			

func _on_player_detection_area_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		player_in_area = false
		speed = 25

		if position.distance_to(spawn_position) > patrol_range:
			returning_to_spawn = true

func _on_hitbox_area_entered(area: Area2D) -> void:
	if dead:
		return
	print("something entered ", area.name)
	if area.has_method("bullet"):
		take_damage()
	if area.name == "DamgeTestBox":
		take_damage()

func take_damage():
	death()
		
func death():
	dead = true
	$AnimatedSprite.play("Death")
	await get_tree().create_timer(1).timeout
	queue_free()
	

#func _on_hitbox_area_exited(area: Area2D) -> void:
#	speed = 50

#	if !player_in_area && position.distance_to(spawn_position) > patrol_range:
#		returning_to_spawn = true
