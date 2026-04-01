extends CanvasLayer

signal fade_out_complete
signal fade_in_complete

@onready var color_rect = $ColorRect
@onready var anim = $AnimationPlayer

func fade_out():
	anim.play("fade_out")
	await anim.animation_finished
	fade_out_complete.emit()

func fade_in():
	anim.play("fade_in")
	await anim.animation_finished
	fade_in_complete.emit()
