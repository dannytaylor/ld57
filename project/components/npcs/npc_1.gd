extends Node3D

@export var sprite1 : Texture2D
@export var sprite2 : Texture2D

@onready var exitblock = $exitblock
var talked = false
var active = false

@onready var progress = $UI/progress
@onready var chat1 = $UI/chat1
@onready var chat2 = $UI/chat2
@onready var pickup_audio = $pickupAudio
@onready var chat_audio = $chatAudio
@onready var camera_mesh = $camera2
@onready var sprite_3d = $Sprite3D

var y_scale : float

var player

func _ready():
	sprite_3d.texture = sprite1
	y_scale = sprite_3d.scale.y

func _process(_delta):
	sprite_3d.scale.y
	if sprite_3d.scale.y < y_scale:
		sprite_3d.scale.y = lerp(sprite_3d.scale.y,y_scale,0.07)
		
func _unhandled_input(event):
	if active and !player.fps_mode:
		if event.is_action_pressed("e"):
			if chat1.visible or chat2.visible:
				player.action_lock = false
				chat1.visible = false
				chat2.visible = false
				sprite_3d.texture = sprite1
				
				if !talked:
					exitblock.set_collision_layer_value(1,false)
					talked = true
					player.has_camera = true
					player.camera_tps_mesh.visible = true
					camera_mesh.visible = false
					pickup_audio.play()
				else:
					chat_audio.play()
				progress.visible = false
			else:
				player.action_lock = true
				sprite_3d.texture = sprite2
				sprite_3d.scale.y = y_scale*0.7
				
				chat_audio.play()
				progress.visible = true
				if talked:
					chat2.visible = true
				else: 
					chat1.visible = true
					
			

func _on_talk_area_body_entered(body):
	if body.is_in_group("player"):
		player = body
		active = true
		progress.visible = true

func _on_talk_area_body_exited(body):
	if body.is_in_group("player"):
		var player = body
		active = false
		progress.visible = false
