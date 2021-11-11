extends Spatial

var cameraAcumul= 0
var freecam= false
var dragcam= false
var waitsaveloadmenu= false
var maxVel= 0
var minVel= 0

func _ready():
	$VehicleBody.queue_free()
	freecam= true
	
func _process(delta):
	
	if !freecam:
		var yVel= $VehicleBody.transform.basis.xform_inv($VehicleBody.linear_velocity).y
		cameraAcumul= (cameraAcumul * 0.8) + (yVel * 0.2)
		$VehicleBody/Camera.translation.y= (cameraAcumul * -0.1) + 5
		$VehicleBody/Camera.translation.z= $VehicleBody.latVel * -0.1
		
		if $VehicleBody.enabled:
			var n= $VehicleBody/Camera/UI/scores.get_path()
			$VehicleBody._calculate_score()
			$VehicleBody.score= int($VehicleBody.score)
			if $VehicleBody.score > $"/root/GenAlg".manualScore:
				$"/root/GenAlg".manualScore= $VehicleBody.score
			get_node(str(n)+"/best").text= str($"/root/GenAlg".manualScore)
			get_node(str(n)+"/current").text= str($VehicleBody.score)
	elif get_node_or_null("bestAI") != null:
		if $bestAI.enabled:
			$bestAI/Camera/UI/inputs/i0.text= str($bestAI.raycasts[0])
			$bestAI/Camera/UI/inputs/i1.text= str($bestAI.raycasts[1])
			$bestAI/Camera/UI/inputs/i2.text= str($bestAI.raycasts[2])
			$bestAI/Camera/UI/inputs/i3.text= str($bestAI.raycasts[3])
			$bestAI/Camera/UI/inputs/i4.text= str($bestAI.raycasts[4])
			$bestAI/Camera/UI/inputs/i5.text= str($bestAI.forces[0])
			$bestAI/Camera/UI/inputs/i6.text= str($bestAI.position[0])
			$bestAI/Camera/UI/inputs/i7.text= str($bestAI.forces[1])
			$bestAI/Camera/UI/inputs/i8.text= str($bestAI.position[1])
			
			$bestAI/Camera/UI/net/c10.text= str($bestAI.capa1[0])
			$bestAI/Camera/UI/net/c11.text= str($bestAI.capa1[1])
			$bestAI/Camera/UI/net/c12.text= str($bestAI.capa1[2])
			$bestAI/Camera/UI/net/c13.text= str($bestAI.capa1[3])
			$bestAI/Camera/UI/net/c14.text= str($bestAI.capa1[4])
			
			$bestAI/Camera/UI/net/c20.text= str($bestAI.capa2[0])
			$bestAI/Camera/UI/net/c21.text= str($bestAI.capa2[1])
			$bestAI/Camera/UI/net/c22.text= str($bestAI.capa2[2])
			
			$bestAI/Camera/UI/net/o0.text= str($bestAI.output[0])
			$bestAI/Camera/UI/net/o1.text= str($bestAI.output[1])

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	
	if Input.is_action_just_pressed("ui_space"):
		if !waitsaveloadmenu:
			var non= get_node_or_null("bestAI")
			if non == null:
				if freecam:
					_spamNewCar()
				else:
					_createFreeCam()
			
			  
	if freecam and !waitsaveloadmenu:
		var non= get_node_or_null("Camera")
		if non == null:
			return
		if event is InputEventMouseButton:
			if event.pressed:
				var mouseX= get_viewport().get_mouse_position().x
				var mouseY= get_viewport().get_mouse_position().y
				if mouseX > 50 and mouseX < 974:
					if mouseY > 50 and mouseY < 550:
						dragcam= true
						Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			else:
				dragcam= false
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		if dragcam:
			if event is InputEventMouseMotion:
				$Camera.rotation_degrees.y-= event.relative.x * 0.2
				$Camera/innerGimbal.rotation_degrees.x-= event.relative.y * 0.2
			
		if event is InputEventKey:
			if event.scancode == KEY_W:
				$Camera.global_translate(-$Camera.global_transform.basis.z)
				$Camera.global_translate(-$Camera/innerGimbal.global_transform.basis.z)
			elif event.scancode == KEY_S:
				$Camera.global_translate($Camera.global_transform.basis.z)
				$Camera.global_translate($Camera/innerGimbal.global_transform.basis.z)
			if event.scancode == KEY_A:
				$Camera.global_translate(-$Camera.global_transform.basis.x)
				$Camera.global_translate(-$Camera/innerGimbal.global_transform.basis.x)
			elif event.scancode == KEY_D:
				$Camera.global_translate($Camera.global_transform.basis.x)
				$Camera.global_translate($Camera/innerGimbal.global_transform.basis.x)
			if event.scancode == KEY_E:
				$Camera.global_translate(-$Camera.global_transform.basis.y)
				$Camera.global_translate(-$Camera/innerGimbal.global_transform.basis.y)
			elif event.scancode == KEY_Q:
				$Camera.global_translate($Camera.global_transform.basis.y)
				$Camera.global_translate($Camera/innerGimbal.global_transform.basis.y)
	else:
		var non= get_node_or_null("VehicleBody")
		if non == null:
			return
			
		var throttle= 0
		if Input.is_action_pressed("ui_up"):
			throttle= 1
		elif Input.is_action_pressed("ui_down"):
			throttle= -1
		
		var steer= Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")
		
		$VehicleBody._result(throttle, steer)

func _createFreeCam():
	var gimbal= Spatial.new()
	gimbal.name= "Camera"
	var cam= Camera.new()
	cam.name= "innerGimbal"
	cam.far= 1500
	gimbal.add_child(cam)
	var ui= load("res://escenas/UI.tscn")
	ui= ui.instance()
	cam.add_child(ui)
	$".".add_child(gimbal)
	$Camera.global_translate(Vector3(0,10,35))
	if $"/root/GenAlg".working:
		$"/root/Spatial/Camera/innerGimbal/UI/autolearnbutton".text= "Pause"
	elif $"/root/GenAlg".bestScore > 1:
		$"/root/Spatial/Camera/innerGimbal/UI/autolearnbutton".text= "Continue"
		
	var camNode= get_node_or_null("VehicleBody/Camera")
	if camNode != null:
		$VehicleBody.visible= false
		camNode.queue_free()
	camNode= get_node_or_null("bestAI/Camera")
	if camNode != null:
		$bestAI.visible= false
		camNode.queue_free()
	freecam= true
	
func _spamNewCar():
	var car= get_node_or_null("VehicleBody")
	if car != null:
		car.linear_velocity= Vector3(0,0,0)
		car.angular_velocity= Vector3(0,0,0)
		car._disable(true)
	else:
		car= load("res://escenas/VehicleBody.tscn")
		car= car.instance()
		$".".add_child(car)
	
	car.translation= Vector3(0,-0.938,-7)
	car.rotation_degrees= Vector3(0,0,0)
	car.name= "VehicleBody"
	
	var camN= get_node_or_null("VehicleBody/Camera")
	if camN == null:
		var cam= Camera.new()
		var ui= load("res://escenas/UI.tscn")
		ui= ui.instance()
		cam.add_child(ui)
		cam.far= 1100
		cam.name= "Camera"
		cam.translation.x= -18
		cam.translation.y= 6
		cam.rotation_degrees.y= -90
		car.add_child(cam)
		get_node("VehicleBody/Camera/UI/scores").visible= true
	
	
	var non= get_node_or_null("bestAI")
	if non != null:
		get_node("VehicleBody/Camera/UI/GenAlgStats").visible= false
		$"VehicleBody/Camera/UI/autolearnbutton".visible= false
		$"VehicleBody/Camera/UI/Label".visible= false
		$"VehicleBody/Camera/UI/viewbestbutton".visible= false
	else:
		if $"/root/GenAlg".working:
			$"VehicleBody/Camera/UI/autolearnbutton".text= "Pause"
		elif $"/root/GenAlg".bestScore > 1:
			$"VehicleBody/Camera/UI/autolearnbutton".text= "Continue"
			
	$"VehicleBody/Camera/UI/viewbestbutton".visible= false
	$"VehicleBody/Camera/UI/loadbutton".visible= false
	$"VehicleBody/Camera/UI/savebutton".visible= false
	$"VehicleBody/Camera/UI/competebutton".visible= false
	$"VehicleBody/Camera".make_current()
	$"VehicleBody/Camera".translation= Vector3(-18,5,0)
	$"VehicleBody/Camera".rotation_degrees= Vector3(-1.136,-90,0)
	$VehicleBody.visible= true
	$"VehicleBody"._disable(false)
	$VehicleBody/CSGBox0.visible= false
	$VehicleBody/CSGBox1.visible= false
	$VehicleBody/CSGBox2.visible= false
	$VehicleBody/CSGBox3.visible= false
	$VehicleBody/CSGBox4.visible= false
	
	freecam= false
	
	var camNode= get_node_or_null("Camera")
	if camNode != null:
		camNode.queue_free()

func _physics_process(delta):
	pass

