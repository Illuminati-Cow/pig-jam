class_name Interactable
extends Node3D

signal interacted

func interact():
	interacted.emit()
