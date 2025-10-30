extends CharacterBody2D

var speed = 25
var dead = false
var player_in_area = false
var player
@onready var attack_box: Area2D = $attackBox
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var deathSound : AudioStreamPlayer = $"11l-small8-bitExplosio-1756058560614"

var is_moving_randomly = false

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
		# Gravity
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
		
	move_and_slide()	



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
	deathSound.play()
	await get_tree().create_timer(1).timeout
	queue_free()
	

#func _on_hitbox_area_exited(area: Area2D) -> void:
#	speed = 50

#	if !player_in_area && position.distance_to(spawn_position) > patrol_range:
#		returning_to_spawn = true


func _on_timer_timeout() -> void:
	var randomWalk=RandomNumberGenerator.new()
	var direction = randomWalk.randf_range(-1 , 1)
	
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	
	if direction == 0:
		animated_sprite.play("Idle")
	elif direction != 0:
		animated_sprite.play("Move") 
		
	if direction > 0 :
		animated_sprite.flip_h=false
	elif direction < 0 :
		animated_sprite.flip_h=true
