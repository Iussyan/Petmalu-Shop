class_name Interactable
extends Area2D

signal Interactable_Activated(body: Node2D)
signal Interactable_Deactivated(body: Node2D)

func _ready() -> void:
	# Automatically connect internal physics signals to our custom signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	Interactable_Activated.emit(body)
	
func _on_body_exited(body: Node2D) -> void:
	Interactable_Deactivated.emit(body)
