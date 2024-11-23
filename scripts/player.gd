extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const MAX_HEALTH = 100
var health = 100
var is_dead = false  # Flag to check if the player is dead

func _ready():
	# Connect the Timer to the damage function
	$Timer.connect("timeout", Callable(self, "_take_damage_over_time"))
	$Timer.start()

	# Connect the animation_finished signal
	$AnimatedSprite2D.connect("animation_finished", Callable(self, "_on_animation_finished"))

	# Set initial health value on ProgressBar
	$CanvasLayer/ProgressBar.value = health

func _physics_process(delta: float) -> void:
	if is_dead:
		return  # Stop processing movement and animations if dead

	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump
	if Input.is_action_just_pressed("arrow_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		$AnimatedSprite2D.animation = "jump"

	# Get the input direction and handle the movement/deceleration
	var direction := Input.get_axis("ui_left", "ui_right")
	if is_on_floor():
		if direction != 0:
			$AnimatedSprite2D.flip_h = direction < 0
			$AnimatedSprite2D.animation = "run"
		else:
			$AnimatedSprite2D.animation = "idle"
	else:
		# Maintain jump animation in the air
		$AnimatedSprite2D.flip_h = direction < 0
		$AnimatedSprite2D.animation = "jump"

	velocity.x = direction * SPEED if direction else move_toward(velocity.x, 0, SPEED)
	move_and_slide()

func _take_damage_over_time():
	if is_dead:
		return  # Stop taking damage if already dead

	health -= 25
	health = max(health, 0)  # Prevent health from going below 0

	# Update ProgressBar
	$CanvasLayer/ProgressBar.value = health

	if health <= 0:
		_game_over()

func _game_over() -> void:
	is_dead = true  # Set the dead state
	$AnimatedSprite2D.animation = "death"  # Play the death animation
	$Timer.stop()  # Stop the damage timer
	$DeathTimer.start()
	velocity = Vector2.ZERO  # Stop all movement

func _restart_game() -> void:
	get_tree().reload_current_scene()  # Reload the current scene

func _on_animation_finished() -> void:
	# Check if the death animation finished before restarting
	if $AnimatedSprite2D.animation == "death":
		_restart_game()


func _on_death_timer_timeout() -> void:
	_restart_game()
	pass # Replace with function body.


func _on_donut_body_entered(body: Node2D) -> void:
	if body.name == "Donut":  # Check if the object is a Donut
		health += 25  # Add health
		health = min(health, MAX_HEALTH)  # Cap health at the maximum
		$CanvasLayer/ProgressBar.value = health  # Update ProgressBar
		body.queue_free()  # Remove the Donut
