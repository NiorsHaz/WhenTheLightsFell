extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -500
@onready var animations: AnimatedSprite2D = $animations
var attacking = false
@onready var hit_box: Area2D = $HitBox


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not attacking:
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("attack") and not attacking:
		attacking = true 
		animations.play("attack")
		animations.animation_finished.connect(attack_finished,CONNECT_ONE_SHOT)
		var enemies=hit_box.get_overlapping_bodies()
		for enemy in enemies:
			if enemy.has_method("death"):
				enemy.death()
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if not attacking:
		if direction == 0:
			animations.play("default")
		elif direction != 0 :
			animations.play("walking")

	if direction > 0:
		animations.flip_h =false
		hit_box.scale.x = 1
	elif direction < 0 :
		animations.flip_h = true
		hit_box.scale.x = -1
	
	move_and_slide()

func attack_finished() -> void :
	attacking=false

func player() -> void :
	print("aye")


func _on_hit_box_body_entered(body: Node2D) -> void:
	pass # Rseplace with function body.
