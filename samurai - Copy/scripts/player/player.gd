extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -500

@onready var animations: AnimatedSprite2D = $animations
@onready var hit_box: Area2D = $HitBox
@onready var hit_shape: CollisionShape2D = $HitBox/CollisionShape2D

var attacking = false

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not attacking:
		velocity.y = JUMP_VELOCITY

	# Attack
	if Input.is_action_just_pressed("attack") and not attacking:
		attacking = true
		hit_shape.disabled = false   # ✅ Enable hitbox only during attack
		animations.play("attack")
		animations.animation_finished.connect(attack_finished, CONNECT_ONE_SHOT)

		# Check immediately if enemies are inside hitbox
		var enemies = hit_box.get_overlapping_bodies()
		for enemy in enemies:
			if enemy.has_method("death"):
				enemy.death()

	# Movement
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if not attacking:
		if direction == 0:
			animations.play("default")
		else:
			animations.play("walking")

	# Flip sprite + hitbox
	if direction > 0:
		animations.flip_h = false
		hit_box.position.x = abs(hit_box.position.x)
	elif direction < 0:
		animations.flip_h = true
		hit_box.position.x = -abs(hit_box.position.x)

	move_and_slide()


func attack_finished() -> void:
	attacking = false
	hit_shape.disabled = true  # ❌ Disable hitbox after attack ends


func _on_hit_box_body_entered(body: Node2D) -> void:
	if attacking and body.has_method("death"):
		body.death()

func player() -> void :
	queue_free()
