extends VehicleBody

var vel= 0
var latVel= 0
var posX= 0
var posZ= 0
var raycasts= [0.0, 0.0, 0.0, 0.0, 0.0] #(normalized 0 to 1)
var forces= [0.0, 0.0] # vel, latVel (normalized 0 to 1)
var position= [0.0, 0.0] # x & z coordinates normalized
var links= [] # 66 sinapsis
var capa1= [0.0, 0.0, 0.0, 0.0, 0.0]
var capa2= [0.0, 0.0, 0.0]
var output= [0.0, 0.0]
var enabled= true
var running= true
var manual= false
var sensorsStep= 0.01
var timeAcumulator= 0
var maxValue= 1.000001
var distRecorrida= 0 # 2150 m por vuelta
var timeRunning= 0
var score= 0
var disableSpeed= 1000

func _ready():
	for i in 66:
		links.push_back(0.0)
	pass



func _process(delta):
	
	timeAcumulator+= delta
	if timeAcumulator > sensorsStep:
		vel= transform.basis.xform_inv(linear_velocity).x
		latVel= transform.basis.xform_inv(linear_velocity).z
		posX= translation.x
		posZ= translation.z
		
		if !manual:
			if enabled:
				_run()
			
		timeAcumulator= 0

func _run():
	_fill_forces()
	_fill_raycasts()
	if running:
		disableSpeed+= vel
		disableSpeed*= 0.7
		if disableSpeed < 0.1: #esto es para eliminar a los parados
			_disable(true)
		else:
			#procesa output
			var output= _output_process()
			_result(output[0], output[1])

func _physics_process(delta):
	if enabled:
		distRecorrida+= (vel * 0.006)
		timeRunning+= delta
	

func _output_process():
	var linkCount= 0
	capa1= [0.0, 0.0, 0.0, 0.0, 0.0]
	for i in 5:
		for i2 in 5:
			capa1[i]+= raycasts[i2] * links[linkCount]
			linkCount+= 1
		for i2 in 2:
			capa1[i]+= forces[i2] * links[linkCount]
			linkCount+= 1
			capa1[i]+= position[i2] * links[linkCount]
			linkCount+= 1
		#capa1[i]*= 0.8 # > 1 / 9
		
	capa2= [0.0, 0.0, 0.0]
	for i in 3:
		for i2 in 5:
			capa2[i]+= capa1[i2] * links[linkCount]
			linkCount+= 1
		#capa2[i]*= 0.8 # > 1 / 5
	
	output= [0.0, 0.0]
	for i in 2:
		for i2 in 3:
			output[i]+= capa2[i2] * links[linkCount]
			linkCount+= 1
		output[i]*= 0.8 # > 1 / 3
		output[i]= max(output[i], -1)
		output[i]= min(output[i], 1)
		
	
	return output

#--------------------------------
# funcion normalizar las fuerzas
# rellena el array global llamado forces[]
func _fill_forces():
	if vel < -10:
		vel= -10
	elif vel > 90:
		vel= 90
	forces[0]= ((vel + 10) * 0.01) #min= -10, max= 90
	
	if latVel > 20:
		latVel= 20
	elif latVel < -20:
		latVel= -20
	forces[1]= ((latVel + 20) * 0.025) #range 20 max min
	
	if posX > 1300:
		posX= 1300
	elif posX < -660:
		posX= -660
	position[0]= ((posX + 660) * 0.00051) #min= -660, max= 1300
	
	if posZ > 100:
		posZ= 100
	elif posZ < -1300:
		posZ= -1300
	position[1]= ((posZ + 1300) * 0.00071) #min= -1300, max= 100
	
	

#--------------------------------
# funcion para captar los sensores raycast
# rellena el array global llamado raycasts[]
func _fill_raycasts():
	if $RayCast0.is_colliding():
		raycasts[0]= $RayCast0.global_transform.origin.distance_to($RayCast0.get_collision_point())
		raycasts[0]*= 0.0121951 # 1 dividido por la dist max que es 82
	else:
		raycasts[0]= maxValue
		
	if $RayCast4.is_colliding():
		raycasts[4]= $RayCast4.global_transform.origin.distance_to($RayCast4.get_collision_point())
		raycasts[4]*= 0.0121951 # 1 dividido por la dist max que es 82
	else:
		raycasts[4]= maxValue
	
	if $RayCast1.is_colliding():
		raycasts[1]= $RayCast1.global_transform.origin.distance_to($RayCast1.get_collision_point())
		raycasts[1]*= 0.0065231 # 1 dividido por la dist max que es 153.3
	else:
		raycasts[1]= maxValue
		
	if $RayCast3.is_colliding():
		raycasts[3]= $RayCast3.global_transform.origin.distance_to($RayCast3.get_collision_point())
		raycasts[3]*= 0.0065231 # 1 dividido por la dist max que es 153.3
	else:
		raycasts[3]= maxValue
	
	if $RayCast2.is_colliding():
		raycasts[2]= $RayCast2.global_transform.origin.distance_to($RayCast2.get_collision_point())
		raycasts[2]*= 0.0049019 # 1 dividido por la dist max que es 204
	else:
		raycasts[2]= maxValue
	
#--------------------------------
# funcion para enviarle la orden de acelerar / frenar / girar
# las variables calculan diferentes intensidades de -1 a 1
# throttle de 0 a 1 acelera, de -1 a 0 frena
# steer de 0 a 1 izquierda, de -1 a 0 derecha
func _result(_throttle, _steer):
	brake= 0
	engine_force= 0
	if _throttle >= 0:
		engine_force = _throttle * 80
	else:
		if vel > 10:
			brake = 2
		elif vel > -10:
			engine_force= _throttle * 30
			
	steering= _steer * 0.4

#--------------------------------
# funcion para activar/desactivar funciones de este coche
# 
func _disable(boolean):
	var bo= true
	if boolean == true:
		bo= false
		running= false
	else:
		if name == "VehicleBody":
			manual= true
		else:
			manual= false
		distRecorrida= 0
		timeRunning= 0
		score= 0
		disableSpeed= 1000
	$RayCast0.enabled= bo
	$RayCast1.enabled= bo
	$RayCast2.enabled= bo
	$RayCast3.enabled= bo
	$RayCast4.enabled= bo
	
	$CSGBox0.visible= bo
	$CSGBox1.visible= bo
	$CSGBox2.visible= bo
	$CSGBox3.visible= bo
	$CSGBox4.visible= bo
	enabled= bo
	
func _calculate_score():
	var timePenaliz= 0.15
	score= distRecorrida - (timeRunning * timePenaliz)
	if distRecorrida < 2100:
		score-= (timeRunning * timePenaliz)
	elif distRecorrida > 2180:
		score= 2180 - (timeRunning * timePenaliz)
	
	
func _on_medio_body_entered(body):
	if enabled:
		_calculate_score()
		_disable(true)

func _on_medio_area_entered(area):
	if enabled:
		_calculate_score()
		_disable(true)
	if name == "VehicleBody":
		get_node("/root/Spatial")._spamNewCar()
	elif distRecorrida > 2100:
		get_node("/root/GenAlg").lapDone= true


