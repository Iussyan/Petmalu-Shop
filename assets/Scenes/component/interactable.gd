class_name Interactable
extends Area2D

signal Interactable_Activated(body: Node2D)
signal Interactable_Deactivated(body: Node2D)

func _on_body_entered(body: Node2D) -> void:
	Interactable_Activated.emit(body)
	
func _on_body_exited(body: Node2D) -> void:
	Interactable_Deactivated.emit(body)
