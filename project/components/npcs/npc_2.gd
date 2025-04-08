extends Node3D

@export var sprite1 : Texture2D
@export var sprite2 : Texture2D

var talked = false
var active = false

@onready var progress = $UI/progress
@onready var chat1 = $UI/chat1
@onready var chat2 = $UI/chat2
@onready var chat_audio = $chatAudio
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
					talked = true
					chat_audio.play()
				else:
					chat_audio.play()
				progress.visible = false
			else:
				chat_audio.play()
				sprite_3d.texture = sprite2
				sprite_3d.scale.y = y_scale*0.7
				player.action_lock = true
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
