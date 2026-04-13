extends Control

@onready var continue_button = %ContinueButton
@onready var new_game_button = %NewGameButton
@onready var quit_button = %QuitButton

func _ready():
	# Audio setup
	if has_node("/root/AudioManager"):
		AudioManager.play_bgm("res://assets/Audio/BGM/menu_music.mp3") # Placeholder path
	
	# Initial appearance
	modulate.a = 0
	var fader = create_tween()
	fader.tween_property(self, "modulate:a", 1.0, 0.5)
	
	# Check if save exists to enable continue
	if has_node("/root/SaveManager"):
		if not SaveManager.has_save():
			continue_button.disabled = true
			continue_button.modulate.a = 0.5
	else:
		continue_button.disabled = true

func _on_new_game_pressed():
	# Play click sound
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("res://assets/Audio/SFX/ui_click.wav")
	
	# Reset state
	if has_node("/root/GameManager"):
		GameManager.reset_game_state()
	
	# Clear save file if existing (optional, but clean for New Game)
	# if has_node("/root/SaveManager"):
	#	SaveManager.delete_save()
	
	# Transition
	_start_game()

func _on_continue_pressed():
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("res://assets/Audio/SFX/ui_click.wav")
		
	# Loading is already handled by GameManager/_ready via SaveManager.load_game()
	# But we ensure it's fresh here if needed
	if has_node("/root/SaveManager"):
		SaveManager.load_game()
		
	_start_game()

func _start_game():
	if has_node("/root/GameManager"):
		GameManager.change_scene("res://src/Worlds/Main.tscn")

func _on_quit_pressed():
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("res://assets/Audio/SFX/ui_click.wav")
	
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

# Animation for buttons
func _on_button_mouse_entered(button_path):
	var button = get_node(button_path) if button_path is NodePath else button_path
	if not button: return
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)

func _on_button_mouse_exited(button_path):
	var button = get_node(button_path) if button_path is NodePath else button_path
	if not button: return
	
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
