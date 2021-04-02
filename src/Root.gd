extends Spatial

const VALETUDO_HOST = "http://localhost:1234"

onready var playerNode = get_node("Player")
onready var head = playerNode.get_child(0)

var wallMaterial = preload("res://wall.tres")

var targetAngle = 0
var targetLocation = Vector3(0,0,0)

var cubesGenerated = false

func on_connected():
	print("We're connected")
	$HTTPSSEClient.connect("new_sse_event", self, "on_new_sse_event")

func on_new_sse_event(headers, event, data):
	var img = Image.new()

	var pixelSize = data["pixelSize"]
	var playerPosition = Vector3(0,0,0)

	for layer in data["layers"]:
		if layer["type"] == "wall":
			var pixels = layer["pixels"]

			var sizex = data["size"]["x"] / data["pixelSize"]
			var sizey = data["size"]["y"] / data["pixelSize"]

			img.create(sizex, sizey, false, Image.FORMAT_RGB8)
			img.lock()

			for i in pixels.size()/2:
				img.set_pixel(pixels[2*i], pixels[2*i+1], Color(1,1,1,1))

			break

	for entity in data["entities"]:
		if entity["type"] == "robot_position":
			print(entity)
			var angle = ( int(entity["metaData"]["angle"])) % 360

			targetAngle = angle * -1
			targetLocation = Vector3(entity["points"][0]/pixelSize, 1, entity["points"][1]/pixelSize)



	print(playerNode.global_transform.origin)


	if(cubesGenerated):
		return

	print("Generate Cubes")
	img.unlock()
	#img.resize(result["size"]["x"]/8, result["size"]["y"]/8)

	img.lock()

	var mm = MultiMesh.new()
	mm.mesh = CubeMesh.new()

	mm.mesh.surface_set_material(0, wallMaterial)

	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.color_format = MultiMesh.COLOR_NONE
	mm.custom_data_format = MultiMesh.CUSTOM_DATA_NONE
	mm.instance_count = img.get_width() * img.get_height()

	var ic = 0
	for x in img.get_width():
		for y in img.get_height():
			if img.get_pixel(x,y).r > 0.5:
				var transform = Transform(Basis(), Vector3(x,0, y))
				mm.set_instance_transform(ic, transform)
				ic += 1

	mm.visible_instance_count = ic


	img.unlock()

	var mmi = MultiMeshInstance.new()
	mmi.multimesh = mm
	mmi.scale.x = 1
	mmi.scale.y = 5
	mmi.scale.z = 1



	for child in self.get_children():
		if(child is MultiMeshInstance):
			self.remove_child(child)


	add_child(mmi)
	cubesGenerated = true

func _process(delta):
	var currentLocation = playerNode.global_transform.origin
	var currentAngle = head.get_rotation_degrees().y

	var angleDelta
	if(currentAngle > targetAngle):
		angleDelta = currentAngle - targetAngle
		angleDelta = angleDelta * -1
	else:
		angleDelta = targetAngle - currentAngle


	var angleStep = stepify(angleDelta / 120, 0.1)

	if angleDelta < 1 && angleDelta > 0:
		angleStep = angleDelta


	currentAngle = currentAngle + angleStep


	head.set_rotation_degrees(Vector3(0, currentAngle, 0))

	var locationDelta
	if(currentLocation > targetLocation):
		locationDelta = currentLocation - targetLocation
		locationDelta = locationDelta * -1
	else:
		locationDelta = targetLocation - currentLocation

	var locationStep = locationDelta / 120

	currentLocation = currentLocation + locationStep

	playerNode.global_transform.origin = currentLocation



func _ready():
	$HTTPSSEClient.connect("connected", self, "on_connected")
	$HTTPSSEClient.connect_to_host(VALETUDO_HOST, "/api/v2/robot/state/map/sse", 80, false, false)
