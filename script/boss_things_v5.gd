extends CharacterBody2D

# ===== VARIABLES EXPORT (Paramétrables dans l'éditeur) =====
@export_group("Boss Stats")
@export var max_health: int = 3
@export var current_health: int = 3

@export_group("Movement")
@export var base_speed: float = 100.0
@export var phase2_speed_multiplier: float = 1.3
@export var phase3_speed_multiplier: float = 1.5
@export var gravity: float = 980.0  # Nouvelle variable pour la gravité
@export var jump_velocity: float = -400.0  # Si vous voulez que le boss puisse sauter

@export_group("Attack Distances")
@export var melee_range: float = 80.0
@export var ranged_attack_distance: float = 200.0
@export var retreat_distance: float = 150.0
@export var detection_range: float = 250.0  # New: for PlayerDetectionArea size

@export_group("Attack Timers")
@export var melee_cooldown: float = 1.5
@export var ranged_cooldown: float = 2.0
@export var area_attack_cooldown: float = 3.0
@export var pattern_change_delay: float = 2.0

@export_group("Area Attack")
@export var area_attack_radius: float = 120.0
@export var area_attack_damage: int = 2

@export_group("Projectiles")
@export var bullet_path: PackedScene
@export var bullet_speed: float = 300.0

# ===== VARIABLES INTERNES =====
enum BossPhase { DEBUT, MILIEU, DECHAINEMENT }
enum AttackPattern { MELEE_THEN_RANGED, RANGED_THEN_MELEE }
enum AttackType { MELEE, RANGED, AREA }
enum BossState { MOVING_TO_MELEE, ATTACKING_MELEE, RETREATING, ATTACKING_RANGED, ATTACKING_AREA, WAITING }

var current_phase: BossPhase = BossPhase.DEBUT
var current_pattern: AttackPattern
var current_state: BossState = BossState.WAITING
var current_speed: float

var target_player: Node2D
var player_detected: bool = false
var max_engagement_distance: float = 500.0  # Boss will engage if player is within this range

# Timers
var attack_timer: float = 0.0
var pattern_timer: float = 0.0
var state_timer: float = 0.0

# Flags
var can_attack: bool = true
var pattern_step: int = 0  # 0 = première attaque du pattern, 1 = deuxième attaque
var facing_right: bool = true

# Nodes (à assigner dans l'éditeur ou _ready)
@onready var detection_area = $PlayerDetectionArea  # Area2D pour détecter le joueur
@onready var melee_area = $MeleeAttackArea  # Area2D pour attaque mêlée
@onready var area_attack_area = $AreaAttackArea  # Area2D pour attaque de zone
@onready var sprite = $AnimatedSprite2D  # AnimatedSprite2D du boss
@onready var fire_point = $Node2D  # Node2D pour la position de tir
@onready var hit_box = $Hitbox  # Area2D pour recevoir les dégâts du joueur

func _ready() -> void:
	current_health = max_health
	current_speed = base_speed
	_choose_random_pattern()
	_setup_collision_areas()
	_setup_hit_box()  # Configuration de la hitbox
	_find_player()  # Find player at start
	##print("Boss initialized - Phase: ", BossPhase.keys()[current_phase])

func _setup_hit_box() -> void:
	if hit_box:
		# Connecter le signal pour détecter quand quelque chose entre dans la hitbox
		hit_box.body_entered.connect(_on_hit_box_body_entered)
		hit_box.area_entered.connect(_on_hit_box_area_entered)
		
		print("Boss HitBox configured successfully")
	else:
		print("WARNING: Boss HitBox not found! Add an Area2D named 'HitBox' to the boss scene.")

# Détecte quand un CharacterBody2D (comme le joueur) entre dans la hitbox
func _on_hit_box_body_entered(body: Node2D) -> void:
	print("Body entered boss hitbox: ", body.name)
	
	# Vérifier si c'est le joueur
	if body.has_method("player") or body.is_in_group("player"):
		print("Player body entered boss hitbox!")
		# Ici vous pouvez gérer si le joueur cause des dégâts au boss lors du contact direct

# Détecte quand un Area2D (comme DamageTestBox) entre dans la hitbox
func _on_hit_box_area_entered(area: Area2D) -> void:
	print("Area entered boss hitbox: ", area.name)
	
	# Vérifier si c'est la DamageTestBox du joueur
	if area.name == "DamgeTestBox":
		print("Player's DamageTestBox hit the boss!")
		_on_player_attack_hit()
		# Le joueur attaque le boss
		var damage = 1  # Ou récupérer la valeur depuis le joueur
		take_damage(damage)
		
		# Optionnel : ajouter un effet de knockback, son, etc.
		_on_player_attack_hit()

# Fonction appelée quand le joueur frappe le boss
func _on_player_attack_hit() -> void:
	print("Boss was hit by player attack!")
	
	# Ici vous pouvez ajouter :
	# - Effet sonore
	# - Effet visuel
	# - Knockback
	# - Animation de dégâts
	
	# Exemple d'effet visuel simple
	if sprite:
		var original_modulate = sprite.modulate
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if sprite:  # Vérifier que le sprite existe encore
			sprite.modulate = original_modulate

func _find_player() -> void:
	# Method 1: Find player in the scene tree by group
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]
		#print("Boss found player: ", target_player.name)
		return
	
	# Method 2: Search by node name (adjust the name to match your player)
	target_player = get_node_or_null("../Niggaman")
	if target_player:
		#print("Boss found player by name: ", target_player.name)
		return
		
	# Method 3: Search the entire scene tree for player
	target_player = _find_node_by_method(get_tree().root, "player")
	if target_player:
		#print("Boss found player by searching: ", target_player.name)
		return
	
	#print("Boss: No player found!")

func _find_node_by_method(node: Node, method_name: String) -> Node:
	if node.has_method(method_name):
		return node
	
	for child in node.get_children():
		var result = _find_node_by_method(child, method_name)
		if result:
			return result
	
	return null

func _setup_collision_areas() -> void:
	# Auto-configure collision area sizes based on exported variables
	if detection_area and detection_area.get_child(0) is CollisionShape2D:
		var collision_shape = detection_area.get_child(0) as CollisionShape2D
		if collision_shape.shape is CircleShape2D:
			(collision_shape.shape as CircleShape2D).radius = detection_range
	
	if melee_area and melee_area.get_child(0) is CollisionShape2D:
		var collision_shape = melee_area.get_child(0) as CollisionShape2D
		if collision_shape.shape is CircleShape2D:
			(collision_shape.shape as CircleShape2D).radius = melee_range
	
	if area_attack_area and area_attack_area.get_child(0) is CollisionShape2D:
		var collision_shape = area_attack_area.get_child(0) as CollisionShape2D
		if collision_shape.shape is CircleShape2D:
			(collision_shape.shape as CircleShape2D).radius = area_attack_radius

func _physics_process(delta: float) -> void:
	# Appliquer la gravité AVANT tout le reste
	if not is_on_floor():
		velocity.y += gravity * delta
	
	_update_timers(delta)
	_update_phase()
	_handle_movement_and_attacks(delta)
	_update_sprite_direction()
	
	# Appliquer le mouvement final
	move_and_slide()

func _update_timers(delta: float) -> void:
	if attack_timer > 0:
		attack_timer -= delta
	if pattern_timer > 0:
		pattern_timer -= delta
	if state_timer > 0:
		state_timer -= delta

func _update_phase() -> void:
	match current_health:
		3:
			if current_phase != BossPhase.DEBUT:
				_enter_phase(BossPhase.DEBUT)
		2:
			if current_phase != BossPhase.MILIEU:
				_enter_phase(BossPhase.MILIEU)
		1:
			if current_phase != BossPhase.DECHAINEMENT:
				_enter_phase(BossPhase.DECHAINEMENT)
				
	# Appeler _die() si la santé est à 0 ou en dessous
	if current_health <= 0:
		_die()

func _enter_phase(new_phase: BossPhase) -> void:
	current_phase = new_phase
	##print("Boss entering phase: ", BossPhase.keys()[current_phase])
	
	match current_phase:
		BossPhase.DEBUT:
			current_speed = base_speed
		BossPhase.MILIEU:
			current_speed = base_speed * phase2_speed_multiplier
		BossPhase.DECHAINEMENT:
			current_speed = base_speed * phase3_speed_multiplier
	
	_choose_random_pattern()
	pattern_step = 0

func _choose_random_pattern() -> void:
	if current_phase == BossPhase.DECHAINEMENT:
		# En phase 3, pas de pattern fixe, tout est aléatoire
		return
	
	current_pattern = AttackPattern.values()[randi() % AttackPattern.size()]
	##print("Boss chose pattern: ", AttackPattern.keys()[current_pattern])

func _handle_movement_and_attacks(delta: float) -> void:
	if not target_player:
		_find_player()  # Try to find player if we don't have one
		if sprite:
			sprite.play("idle")
		return
	
	var distance_to_player = global_position.distance_to(target_player.global_position)
	
	# Check if player is within engagement range
	if distance_to_player > max_engagement_distance:
		player_detected = false
		if sprite:
			sprite.play("idle")
		return
	else:
		player_detected = true
	
	match current_phase:
		BossPhase.DEBUT, BossPhase.MILIEU:
			_handle_pattern_based_combat(distance_to_player, delta)
		BossPhase.DECHAINEMENT:
			_handle_chaotic_combat(distance_to_player, delta)

func _handle_pattern_based_combat(distance_to_player: float, delta: float) -> void:
	match current_state:
		BossState.WAITING:
			if pattern_timer <= 0:
				_start_pattern()
		
		BossState.MOVING_TO_MELEE:
			if distance_to_player > melee_range:
				_move_towards_player(delta)
			else:
				_start_melee_attack()
		
		BossState.ATTACKING_MELEE:
			if attack_timer <= 0:
				_execute_melee_attack()
		
		BossState.RETREATING:
			if distance_to_player < retreat_distance:
				_move_away_from_player(delta)
			else:
				_start_ranged_attack()
		
		BossState.ATTACKING_RANGED:
			if attack_timer <= 0:
				_execute_ranged_attack()

func _handle_chaotic_combat(distance_to_player: float, delta: float) -> void:
	match current_state:
		BossState.WAITING:
			if attack_timer <= 0:
				_choose_random_attack()
		
		BossState.MOVING_TO_MELEE:
			if distance_to_player > melee_range:
				_move_towards_player(delta)
			else:
				_execute_melee_attack()
		
		BossState.RETREATING:
			if distance_to_player < ranged_attack_distance:
				_move_away_from_player(delta)
			else:
				_execute_ranged_attack()
		
		BossState.ATTACKING_AREA:
			if attack_timer <= 0:
				_execute_area_attack()

func _start_pattern() -> void:
	var first_attack = _get_pattern_attack(0)
	_start_attack_type(first_attack)

func _get_pattern_attack(step: int) -> AttackType:
	match current_pattern:
		AttackPattern.MELEE_THEN_RANGED:
			return AttackType.MELEE if step == 0 else AttackType.RANGED
		AttackPattern.RANGED_THEN_MELEE:
			return AttackType.RANGED if step == 0 else AttackType.MELEE
		_:
			# Valeur par défaut si current_pattern n'est pas reconnu
			return AttackType.MELEE

func _choose_random_attack() -> void:
	var random_attack = randi() % 3
	match random_attack:
		0: _start_attack_type(AttackType.MELEE)
		1: _start_attack_type(AttackType.RANGED)
		2: _start_attack_type(AttackType.AREA)

func _start_attack_type(attack_type: AttackType) -> void:
	match attack_type:
		AttackType.MELEE:
			current_state = BossState.MOVING_TO_MELEE
		AttackType.RANGED:
			current_state = BossState.RETREATING
		AttackType.AREA:
			current_state = BossState.ATTACKING_AREA
			attack_timer = 1.0  # Temps de préparation

func _start_melee_attack() -> void:
	current_state = BossState.ATTACKING_MELEE
	attack_timer = melee_cooldown
	
	# Animation de préparation d'attaque mêlée
	if sprite:
		sprite.play("Attack")
	
	##print("Boss preparing melee attack...")

func _start_ranged_attack() -> void:
	current_state = BossState.ATTACKING_RANGED
	attack_timer = ranged_cooldown
	
	# Animation de préparation d'attaque à distance
	if sprite:
		sprite.play("Attack")
	
	##print("Boss preparing ranged attack...")

func _execute_melee_attack() -> void:
	##print("Boss executes MELEE attack!")
	
	# Activer la zone d'attaque mêlée
	if melee_area:
		_damage_players_in_area(melee_area, 1)
	
	_finish_attack()

func _execute_ranged_attack() -> void:
	##print("Boss executes RANGED attack!")
	
	# Utiliser la fonction fire() comme l'ennemi classique
	fire()
	
	_finish_attack()

func fire():
	if bullet_path == null:
		##print("ERROR: bullet_path is null!")
		return
	
	var bullet = bullet_path.instantiate()
	if bullet == null:
		##print("ERROR: Failed to instantiate bullet!")
		return
	
	# Get boss position at instant T (using Node2D like classic enemy)
	var boss_position = fire_point.global_position if fire_point else global_position
	
	if target_player != null:
		# Get player position at instant T
		var player_position = target_player.global_position
		
		# Calculate direction from boss to player
		var direction_to_player = (player_position - boss_position).normalized()
		var bullet_angle = direction_to_player.angle()
		
		# Set bullet properties BEFORE adding to scene
		bullet.pos = boss_position
		bullet.dir = bullet_angle
		bullet.rota = bullet_angle
		bullet.speed = bullet_speed  # Utiliser la vitesse du boss
		
		# Add bullet to scene AFTER setting properties
		get_parent().add_child(bullet)
		
		##print("Boss fired bullet toward player!")
		##print("Boss position (instant T): ", boss_position)
		##print("Player position (instant T): ", player_position)
		##print("Bullet direction: ", direction_to_player)
		##print("Bullet angle: ", bullet_angle)
	else:
		##print("Boss: No target player for ranged attack!")
		bullet.queue_free()

func _execute_area_attack() -> void:
	##print("Boss executes AREA attack!")
	
	# Animation d'attaque de zone
	if sprite:
		sprite.play("Attack")
	
	# Attaque de zone autour du boss
	if area_attack_area:
		_damage_players_in_area(area_attack_area, area_attack_damage)
	
	# Effet visuel (à ajouter selon tes besoins)
	_create_area_attack_effect()
	
	_finish_attack()

func _finish_attack() -> void:
	if current_phase == BossPhase.DECHAINEMENT:
		# Phase 3: Délai court entre attaques aléatoires
		current_state = BossState.WAITING
		attack_timer = 1.0
	else:
		# Phases 1-2: Suivre le pattern
		pattern_step += 1
		if pattern_step >= 2:
			# Pattern terminé, recommencer
			pattern_step = 0
			current_state = BossState.WAITING
			pattern_timer = pattern_change_delay
			_choose_random_pattern()
		else:
			# Passer à la deuxième attaque du pattern
			var next_attack = _get_pattern_attack(pattern_step)
			_start_attack_type(next_attack)

func _move_towards_player(delta: float) -> void:
	var direction = (target_player.global_position - global_position).normalized()
	# Ne modifier que la composante X de la vitesse pour rester au sol
	velocity.x = direction.x * current_speed
	# Garder la composante Y intacte (pour la gravité)
	
	# Animation de mouvement
	if sprite:
		sprite.play("idle")  # ou "walk" si tu as une animation de marche

func _move_away_from_player(delta: float) -> void:
	var direction = (global_position - target_player.global_position).normalized()
	# Ne modifier que la composante X de la vitesse pour rester au sol
	velocity.x = direction.x * current_speed
	# Garder la composante Y intacte (pour la gravité)
	
	# Animation de mouvement
	if sprite:
		sprite.play("idle")  # ou "walk" si tu as une animation de marche

func _damage_players_in_area(area: Area2D, damage: int) -> void:
	if not area:
		#print("ERROR: Area is null!")
		return
	
	var bodies = area.get_overlapping_bodies()
	#print("Bodies found in area: ", bodies.size())
	
	for body in bodies:
		#print("Checking body: ", body.name, " | Has take_damage method: ", body.has_method("take_damage"))
		
		if body.has_method("take_damage"):
			if body.name == "BossNegga" or body == self:
				#print("Skipping boss self-damage")
				continue  # Skip the boss itself, but continue checking other bodies
			else:
				#print("Dealing ", damage, " damage to ", body.name)
				body.take_damage(damage)
				#print("Boss dealt ", damage, " damage to ", body.name)
		else:
			pass
			#print("Body ", body.name, " doesn't have take_damage method")

func _create_area_attack_effect() -> void:
	pass
	# Ici tu peux ajouter des effets visuels/sonores
	
	#print("AREA ATTACK EFFECT!")

func _update_sprite_direction() -> void:
	if target_player and sprite:
		facing_right = target_player.global_position.x > global_position.x
		sprite.flip_h = not facing_right

func take_damage(damage: int) -> void:
	current_health -= damage
	print("Boss took damage! Health: ", current_health, "/", max_health)
	
	# Effet de knockback ou d'invincibilité si nécessaire
	_on_damaged()

func _on_damaged() -> void:
	# Animation de dégâts
	if sprite:
		sprite.play("Hit")  # ou "hit" si tu as une animation de dégâts
		# Revenir à idle après un court délai
		await get_tree().create_timer(0.3).timeout
		if current_health > 0 and sprite:
			sprite.play("idle")

func _die() -> void:
	##print("Boss defeated!")
	
	# Animation de mort
	if sprite:
		sprite.play("Death")
		# Attendre la fin de l'animation avant de détruire
		await get_tree().create_timer(2.0).timeout
		#print("boss suppossed to be dead")
	
	# Drop d'items, effets, etc.
	queue_free()

# Signaux de détection du joueur (now optional - can be removed or kept for other purposes)
func _on_player_detection_area_body_entered(body: Node2D) -> void:
	# This is now optional since we use direct player tracking
	if body.has_method("player"):
		pass
		#print("Player entered detection area: ", body.name)

func _on_player_detection_area_body_exited(body: Node2D) -> void:
	# This is now optional since we use direct player tracking  
	if body.has_method("player"):
		pass
		#print("Player exited detection area: ", body.name)
