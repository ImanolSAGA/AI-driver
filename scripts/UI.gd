extends Node2D

var timeCount= 0
var scoreMax= 300
var scoreMult= 1
var itemCount= 0

func _ready():
	_draw_links()
	itemCount= get_node("/root/GenAlg").listCount
	for i in itemCount:
		$GenAlgStats/ItemList.add_item(" ")
	
	$savemenu.visible= false
	$loadmenu.visible= false

func _process(delta):
	timeCount+= delta
	if timeCount > 0.5:
		if get_node("/root/GenAlg").graph.size() != $GenAlgStats/Line2D.points.size():
			_refresh_data()
		timeCount= 0

func _refresh_data():
	$GenAlgStats/Line2D.points= get_node("/root/GenAlg").graph
	$GenAlgStats/bestScore.text= "Best Score: "+str(int(get_node("/root/GenAlg").bestScore))
	$GenAlgStats/sims.text= "Sims nº : "+str(int(get_node("/root/GenAlg").sims))
	
	for i in itemCount:
		var nuevoTexto= str(int(get_node("/root/GenAlg").scoreList[i]))+" | "
		for i2 in 66:
			var v= get_node("/root/GenAlg").genList[i][i2]
			v= int(v * 10) * 0.1
			nuevoTexto+= str(v)+": "
		$GenAlgStats/ItemList.set_item_text(i, nuevoTexto)
		
	var time= int(get_node("/root/GenAlg").timeTotal)
	var h= int(time * 0.000277777777778) % 24
	var m= int(time * 0.0166666666667) % 60
	var s= time % 60
	$GenAlgStats/time.text= "Time : %02d:%02d:%02d" % [h, m, s]
	$GenAlgStats/manualscore.text= "Manual Score : "+str($"/root/GenAlg".manualScore)

func _draw_links():
	var color= Color(1,0,0,0.4)
	var width= 2
	var iX= 80
	var iY= [95, 125, 155, 185, 215, 245, 275, 305, 335]
	var c1X= 150
	var c1Y= [145, 175, 205, 235, 265]
	for i in 9:
		for i2 in 5:
			var line= Line2D.new()
			line.add_point(Vector2(iX,iY[i]), 0)
			line.add_point(Vector2(c1X,c1Y[i2]), 1)
			line.default_color= color
			line.width= width
			$net/lines.add_child(line)
			
	c1X= 230
	var c2X= 270
	var c2Y= [172, 202, 232]
	for i in 5:
		for i2 in 3:
			var line= Line2D.new()
			line.add_point(Vector2(c1X,c1Y[i]), 0)
			line.add_point(Vector2(c2X,c2Y[i2]), 1)
			line.default_color= color
			line.width= width
			$net/lines.add_child(line)
			
	c2X= 350
	var oX= 380
	var oY= [187, 222]
	for i in 3:
		for i2 in 2:
			var line= Line2D.new()
			line.add_point(Vector2(c2X,c2Y[i]), 0)
			line.add_point(Vector2(oX,oY[i2]), 1)
			line.default_color= color
			line.width= width
			$net/lines.add_child(line)
	pass

func _on_autolearnbutton_pressed():
	if $autolearnbutton.text == "Pause":
		$autolearnbutton.text= "Continue"
		get_node("/root/GenAlg").working= false
	elif get_node("/root/GenAlg").scoreList[0] < 1:
		$autolearnbutton.text= "Pause"
		get_node("/root/GenAlg")._start()
	else:
		$autolearnbutton.text= "Pause"
		get_node("/root/GenAlg").working= true

func _on_viewbestbutton_pressed():
	if $viewbestbutton.text == "View Best":
		if get_node("/root/GenAlg").bestScore > 0:
			$"/root/GenAlg"._spam_view_best()
			$viewbestbutton.text= "Cancel"
	else:
		$"/root/GenAlg"._cancel_view_best()
		$viewbestbutton.text= "View Best"
	pass

func _on_competebutton_pressed():
	if get_node("/root/GenAlg").bestScore > 0:
		$"/root/GenAlg"._spam_view_best()
		$"/root/Spatial"._spamNewCar()

func _on_savebutton_pressed():
	if get_node("/root/GenAlg").bestScore > 0:
		$"/root/Spatial".waitsaveloadmenu= true
		$"/root/GenAlg".working= false
		$savemenu.visible= true
		_get_files($savemenu/filelist)

func _on_loadbutton_pressed():
	$"/root/GenAlg".working= false
	$"/root/Spatial".waitsaveloadmenu= true
	$loadmenu.visible= true
	_get_files($loadmenu/filelist2)

func _get_files(_filelist):
	_filelist.clear()
	var dir= Directory.new()
	dir.open("user://")
	dir.list_dir_begin()
	while(true):
		var filename= dir.get_next()
		if filename == "":
			break
		elif filename.ends_with(".mem"):
			_filelist.add_item(filename)
	dir.list_dir_end()

func _on_cancelbutton_pressed():
	$savemenu.visible= false
	$loadmenu.visible= false
	$"/root/Spatial".waitsaveloadmenu= false
	if $"/root/GenAlg".bestScore > 1:
		$autolearnbutton.text= "Continue"

func _on_finalsavebutton_pressed():
	var file = File.new()
	var filename= $savemenu/filename.text
	filename= filename.strip_edges()
	if !filename.is_valid_filename():
		filename= "filename.mem"
	if !filename.ends_with(".mem"):
		filename+= ".mem"
	filename= "user://" + filename
	file.open(filename, File.WRITE)
	var dict= {
		"scList": $"/root/GenAlg".scoreList, 
		"gnList": $"/root/GenAlg".genList,
		"mult": $"/root/GenAlg".scoreMult,
		"sims": $"/root/GenAlg".sims,
		"time": $"/root/GenAlg".timeTotal
		}
	file.store_string(to_json(dict))
	file.close()
	$savemenu.visible= false
	$"/root/Spatial".waitsaveloadmenu= false
	if $"/root/GenAlg".bestScore > 1:
		$autolearnbutton.text= "Continue"

func _on_filelist_item_selected(index):
	$savemenu/filename.text= $savemenu/filelist.get_item_text(index)

func _on_filelist2_item_selected(index):
	$loadmenu/filename2.text= $loadmenu/filelist2.get_item_text(index)

func _on_finalloadbutton_pressed():
	var file = File.new()
	var filename= "user://" + $loadmenu/filename2.text
	if file.file_exists(filename):
		file.open(filename, File.READ)
		var data = parse_json(file.get_as_text())
		file.close()
		if typeof(data) == TYPE_DICTIONARY:
			var correct= data.has("scList") and data.has("gnList")
			if correct and data.has("mult"):
				correct= data.has("sims") and data.has("time")
			if correct:
				$"/root/GenAlg".scoreList= data["scList"]
				$"/root/GenAlg".genList= data["gnList"]
				$"/root/GenAlg".scoreMult= data["mult"]
				$"/root/GenAlg".sims= data["sims"]
				$"/root/GenAlg".timeTotal= data["time"]
				$"/root/GenAlg".bestScore= $"/root/GenAlg".scoreList.max()
			else: 
				printerr("Not scList or gnList saved")
		else:
			printerr("Not dictionary saved")
	else:
		printerr("No saved data!")
		
	$"/root/Spatial".waitsaveloadmenu= false
	_refresh_data()
	$loadmenu.visible= false
	if $"/root/GenAlg".bestScore > 1:
		$autolearnbutton.text= "Continue"
