extends Node3D

@onready var walk_target = $walk_target

@export var next_scene : int

func _on_area_3d_body_entered(body):
	if body.is_in_group("player"):
		var player = body
		player.action_lock = true
		player.door_enter = true
		player.walk_target = walk_target.global_position
		player.fade_out.visible = true
		player.batteries = []
		player.level_switch.start(2.0)
		player.next_level = next_scene
