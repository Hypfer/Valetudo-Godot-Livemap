extends KinematicBody

#var request_rate : float = 10
#onready var update_delta : float = 1 / request_rate
#var current_time : float = 0

onready var head = get_node("Head")

export var move_multiplyer = 20.0
export var head_multiplyer = 0.01
export var damp = 0.98

var relative_mouse = Vector2.ZERO

var move_force: Vector3

func _ready():
	pass
	
func _input(event):
	if event is InputEventMouseMotion:
		relative_mouse += event.relative

#func _process(delta):	
	#current_time += delta
	
	#if Input.is_action_pressed("left"):
	#	print("LEFT")
	#elif Input.is_action_pressed("right"):
		
	#if Input.is_action_pressed("up"):
		
	#elif Input.is_action_pressed("down"):
