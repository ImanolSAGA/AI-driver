extends Node

var car= true
var carsCount= 60
var carsToCheck
var carsChecked= 0
var working= false
var listCount= 18
var scoreList= [0]
var genList= []
var timeCount= 0
var timeTotal= 0
var emptyLink= []
var manualScore= 0
var graph= PoolVector2Array()
var lapDone= false
var bestScore= 0
var bestCar= false
var scoreMult= 1
var sims= 0

func _ready():
	randomize()
	carsToCheck= int(carsCount * 0.05) + 1
	if listCount > carsCount:
		listCount= carsCount
	for i in 66:
		emptyLink.append(0.0)
		
	car= []
	for i in carsCount:
		var carInst= load("res://escenas/VehicleBody.tscn")
		carInst= carInst.instance()
		carInst.name= "dummy"+str(i)
		carInst.translation= Vector3(0,-0.938,10)
		get_node("/root/Spatial").add_child(carInst)
		car.push_back(carInst)
		carInst._disable(true)
		carInst.visible= false
		
		if i < listCount:
			scoreList.push_back(0.0)
			var newArray= emptyLink.duplicate(true)
			genList.push_back(newArray)

func _process(delta):
	if working:
		timeCount+= delta
		timeTotal+= delta
		#cada segundo chekea todos los coches por si ya estan desactivados
		if timeCount > 0.5:
			_check_cars()
			
			timeCount= 0
	pass

func _check_cars():
	var currScore= 0
	for n in carsToCheck:
		var i= (carsChecked + 1)
		if i >= carsCount:
			i= 0
		carsChecked= i
		if car[i].enabled == false:
			sims+= 1
			#añade este score a la lista
			car[i].score= int(car[i].score)
			for i2 in listCount:
				if car[i].score > int(scoreList[i2]) + 1:
					if i2 > 0:
						if !lapDone:
							if car[i].score > int(scoreList[i2 - 1]) - 1:
								break
					for i3 in range(listCount - 1, i2, -1):
						scoreList[i3]= scoreList[i3 - 1]
						genList[i3]= genList[i3 - 1]
					
					scoreList[i2]= car[i].score
					genList[i2]= car[i].links
					break
			
			
			currScore= max(car[i].score, currScore)
			# generar nuevo gen
			var linksNew
			var rand_float= randf()
			if rand_float < 0.1 and !lapDone: # crea un gen desde 0
				linksNew= emptyLink.duplicate(true)
				var cuant= (randi() % 10) + 56
				var pos= randi() % 66
				for c in cuant:
					linksNew[(c + pos) % 66]= (randf() * 3) - 1.5 # entre -1.5 y 1.5
			elif rand_float < 0.6: # cruza 2 genes que existian
				var mod1= randi() % int(listCount * 0.3)
				var mod2= randi() % listCount
				if mod1 == mod2:
					mod2= (mod2 + 1) % listCount
				linksNew= genList[mod1].duplicate(true)
				var point= randi() % 66
				for c in 33:
					linksNew[c % 66]= genList[mod2][c % 66]
			else: # muta un gen que ya existia
				var mod= randi() % listCount
				linksNew= genList[mod].duplicate(true)
				var changes= (randi() % 50) + 1
				for c in changes:
					if randf() > 0.4:
						var valueNew= (randf() * 3) - 1.5 # entre -1.5 y 1.5
						linksNew[randi() % 66]= valueNew
					else: 
						var r= randi() % 66
						linksNew[r]*= 0.9

			
					
			#poner a circular el coche
			car[i].linear_velocity= Vector3(0,0,0)
			car[i].angular_velocity= Vector3(0,0,0)
			car[i].translation= Vector3(0,-0.938,10)
			car[i].rotation_degrees= Vector3(0,0,0)
			car[i].score= 0.0
			car[i].links= linksNew.duplicate(true)
			car[i]._disable(false)
			car[i].running= true
			car[i].visible= true
			
		if currScore != 0:
			_graph_newPoint(currScore)
			break

func _graph_newPoint(value):
	
	var point= graph.size()
	if point > 385:
		for i in range(382,-1,-3):
			var na= [graph[i], graph[i + 1], graph[i + 2]]
			var rem= [true, true, true]
			rem[na.find(na.max())]= false
			rem[na.find(na.min())]= false
			for i2 in 3:
				if rem[2 - i2]:
					graph.remove(i + (2 - i2))
		point= graph.size()
		for i in point:
			graph[i].x= i

	value= float(value)
	if value > bestScore:
		if value > 300:
			var m= max(float(bestScore), 300.00)
			scoreMult= m / value
			for i in graph.size():
				var v= graph[i].y
				v*= scoreMult
				graph[i]= Vector2(i, v)
			scoreMult= 300.00 / value
		bestScore= value
	
	graph.push_back(Vector2(point, -value * scoreMult))

func _start():
	for i in carsCount:
		car[i].linear_velocity= Vector3(0,0,0)
		car[i].angular_velocity= Vector3(0,0,0)
		car[i].translation= Vector3(0,-0.938,10)
		car[i].rotation_degrees= Vector3(0,0,0)
		car[i].score= 0.0
		car[i]._disable(true)
		
		if i < listCount:
			scoreList[i]= 0.0
			genList[i]= emptyLink.duplicate(true)
			
	timeCount= 0
	timeTotal= 0
	bestScore= 0
	scoreMult= 1
	sims= 0
	lapDone= false
	working= true

func _spam_view_best():
	_pause_and_hide_cars(true)
	
	var c= get_node_or_null("bestAI")
	if c == null:
		var carInst= load("res://escenas/VehicleBody.tscn")
		carInst= carInst.instance()
		carInst.name= "bestAI"
		get_node("/root/Spatial").add_child(carInst)
		c= carInst
	
	c.linear_velocity= Vector3(0,0,0)
	c.angular_velocity= Vector3(0,0,0)
	c.translation= Vector3(0,-0.938,10)
	c.rotation_degrees= Vector3(0,0,0)
	
	var camN= get_node_or_null("bestAI/Camera")
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
		c.add_child(cam)
		
	$"/root/Spatial/bestAI/Camera/UI/viewbestbutton".text= "Cancel"
	$"/root/Spatial/bestAI/Camera/UI/viewbestbutton".rect_size= Vector2(165,30)
	$"/root/Spatial/bestAI/Camera/UI/inputs".visible= true
	$"/root/Spatial/bestAI/Camera/UI/net".visible= true
	$"/root/Spatial/bestAI/Camera/UI/autolearnbutton".visible= false
	$"/root/Spatial/bestAI/Camera/UI/loadbutton".visible= false
	$"/root/Spatial/bestAI/Camera/UI/savebutton".visible= false
	$"/root/Spatial/bestAI/Camera/UI/competebutton".visible= false
	$"/root/Spatial/bestAI/Camera/UI/Label".visible= false
	
	$"/root/Spatial/bestAI/Camera".make_current()
	$"/root/Spatial/bestAI/Camera".translation= Vector3(-18,5,0)
	$"/root/Spatial/bestAI/Camera".rotation_degrees= Vector3(-1.136,-90,0)
	$"/root/Spatial/bestAI".links= genList[0].duplicate(true)
	$"/root/Spatial/bestAI"._disable(false)
	
	bestCar= $"/root/Spatial/bestAI"
	
	var camNode= get_node_or_null("/root/Spatial/Camera")
	if camNode != null:
		camNode.queue_free()
	
	pass
	
func _cancel_view_best():
	_pause_and_hide_cars(false)
	$"/root/Spatial"._createFreeCam()
	bestCar.visible= false
	bestCar.queue_free()
	pass
	
func _pause_and_hide_cars(_bool):
	var b= true
	if _bool:
		b= false
	working= b
	if typeof(car) != 1: #no es bool, osea hay coches
		for i in car:
			i.visible= b
