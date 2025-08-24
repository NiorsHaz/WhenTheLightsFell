extends CharacterBody2D

var bullet_path=preload("res://scenes/enemy/bullets.tscn")

var flight_speed = 25
var is_dead = false
var player_detected = false
var target_player
@onready var player: CharacterBody2D = $"../player"

var patrol_timer = 0.0
var patrol_direction = Vector2.ZERO
var is_patrolling = false
var patrol_duration = 0.0
var rest_timer = 0.0

var facing_right = true
var detection_margin = 20

var nest_position: Vector2  # Position de départ (nid)
var patrol_radius = 100.0 
var returning_to_nest = false
var return_flight_speed = 25.0

# Variables spécifiques à l'ennemi volant
var attack_altitude = 5.0  # Distance pour descendre au-dessus du joueur (paramétrable)
var is_attacking = false
var target_attack_position: Vector2
var shooting_timer = 0.0
var shot_interval = 0.2  # Délai entre les tirs en secondes
var attack_flight_speed = 30.0  # Vitesse pour se positionner au-dessus du joueur

# Scene du projectile à instancier (à assigner dans l'éditeur)
@export var projectile_scene: PackedScene
@onready var marker_2d: Marker2D = $Marker2D

func _ready() -> void:
	is_dead = false
	nest_position = position 

func _physics_process(delta: float) -> void:
	var direction = global_position.direction_to(player.global_position)
	marker_2d.look_at(player.global_position)
	if !is_dead:
		$PlayerDetectionArea/CollisionShape2D.disabled = false
		#print("Face à droite ? :" , facing_right)
		
		if player_detected:
			handle_aerial_attack(delta)
			print("Enemy check the player")
		else:
			if position.distance_to(nest_position) > patrol_radius && !returning_to_nest:
				returning_to_nest = true
				is_patrolling = false
			
			if returning_to_nest:
				handle_return_to_nest(delta)
			else:
				handle_aerial_patrol(delta)
			
		if is_dead:
			$PlayerDetectionArea/CollisionShape2D.disabled = true

func handle_aerial_attack(delta: float) -> void:
	# Calculer la position cible au-dessus du joueur
	target_attack_position = Vector2(target_player.position.x, target_player.position.y - attack_altitude)
	
	# Voler vers la position au-dessus du joueur
	var direction_to_target = (target_attack_position - position).normalized()
	position += direction_to_target * attack_flight_speed * delta
	
	# Orientation basée sur la direction horizontale
	facing_right = direction_to_target.x > 0
	$AnimatedSprite2D.flip_h = !facing_right
	
	# Animation d'attaque aérienne
	$AnimatedSprite2D.play("Attack")
	
	# Tirer des projectiles
	shooting_timer += delta
	print("Shooting timer value",delta)
	if shooting_timer >= shot_interval:
		print("gotta shoot")
		fire()
		shooting_timer = 0.0
	
	is_patrolling = false
	returning_to_nest = false
	is_attacking = true


func handle_return_to_nest(delta: float) -> void:
	var flight_direction = (nest_position - position).normalized()
	position += flight_direction * return_flight_speed * delta
	$AnimatedSprite2D.play("idle")
	facing_right = flight_direction.x > 0
	$AnimatedSprite2D.flip_h = !facing_right
	
	if position.distance_to(nest_position) < 10.0:
		returning_to_nest = false
		rest_timer = 0.0
		is_attacking = false

func handle_aerial_patrol(delta: float) -> void:
	if !is_patrolling:
		rest_timer += delta
		$AnimatedSprite2D.play("idle")
		
		if rest_timer >= 2.0:
			is_patrolling = true
			# Direction de vol aléatoire en 2D
			var random_angle = randf() * 2 * PI
			patrol_direction = Vector2(cos(random_angle), sin(random_angle))
			patrol_duration = randf_range(0.5, 2.0)
			patrol_timer = 0.0
			rest_timer = 0.0
	else:
		patrol_timer += delta
		
		if patrol_timer < patrol_duration:
			var new_flight_position = position + patrol_direction * flight_speed * delta
			
			# Vérifier que la nouvelle position reste dans le rayon de patrouille
			if new_flight_position.distance_to(nest_position) <= patrol_radius:
				position = new_flight_position
				facing_right = patrol_direction.x > 0
				$AnimatedSprite2D.play("idle")
				$AnimatedSprite2D.flip_h = !facing_right
			else:
				# Inverser la direction de vol si on sort de la zone
				patrol_direction = -patrol_direction
				$AnimatedSprite2D.flip_h = !facing_right
		else:
			is_patrolling = false
			$AnimatedSprite2D.play("idle")

func _on_player_detection_area_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		flight_speed = 50
		print("hello bitch")
		attack_flight_speed = 40  # Augmenter la vitesse d'attaque
		if facing_right and body.position.x > position.x:
			player_detected = true
			target_player = body
			print("it look at you")
		elif !facing_right and body.position.x < position.x:
			player_detected = true
			target_player = body
			print("it look at you")

func _on_player_detection_area_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		player_detected = false
		flight_speed = 25
		attack_flight_speed = 30
		is_attacking = false
		shooting_timer = 0.0  # Reset le timer de tir

		if position.distance_to(nest_position) > patrol_radius:
			returning_to_nest = true

func _on_hitbox_area_entered(area: Area2D) -> void:
	if is_dead:
		return
	print("something entered ", area.name)
	if area.has_method("bullet"):
		take_damage()
	if area.name == "DamgeTestBox":
		take_damage()

func take_damage():
	death()
		
func death():
	is_dead = true
	$AnimatedSprite2D.play("Death")
	await get_tree().create_timer(1).timeout
	queue_free()

# Fonctions utilitaires pour ajuster les paramètres depuis l'éditeur
func set_attack_altitude(new_altitude: float) -> void:
	attack_altitude = new_altitude

func set_shot_interval(new_interval: float) -> void:
	shot_interval = new_interval

func set_patrol_radius(new_radius: float) -> void:
	patrol_radius = new_radius


func _on_hitbox_area_exited(area: Area2D) -> void:
	pass # Replace with function body.

func fire():
	var bullet_instance=bullet_path.instantiate()
	add_child(bullet_instance)
	bullet_instance.global_position=marker_2d.global_position
	bullet_instance.rotation=marker_2d.rotation
