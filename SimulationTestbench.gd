extends Control

var weights := [ 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0]

func updateWeights(newWeights):
	weights = newWeights

	var cw := get_node("SimulationSettingsWindow/Tabs/Kernel/CellWeights/CurrentWeights/WeightValues")
	cw.get_node("TopLeft").text = str(weights[0])
	cw.get_node("Top").text = str(weights[1])
	cw.get_node("TopRight").text = str(weights[2])
	cw.get_node("Left").text = str(weights[3])
	cw.get_node("Center").text = str(weights[4])
	cw.get_node("Right").text = str(weights[5])
	cw.get_node("BottomLeft").text = str(weights[6])
	cw.get_node("Bottom").text = str(weights[7])
	cw.get_node("BottomRight").text = str(weights[8])

	var nw := get_node("SimulationSettingsWindow/Tabs/Kernel/CellWeights/NewWeights/WeightValues")
	nw.get_node("TopLeft").text = str(weights[0])
	nw.get_node("Top").text = str(weights[1])
	nw.get_node("TopRight").text = str(weights[2])
	nw.get_node("Left").text = str(weights[3])
	nw.get_node("Center").text = str(weights[4])
	nw.get_node("Right").text = str(weights[5])
	nw.get_node("BottomLeft").text = str(weights[6])
	nw.get_node("Bottom").text = str(weights[7])
	nw.get_node("BottomRight").text = str(weights[8])

	print("New weights:")
	print(weights)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_simulation_settings_window_close_requested():
	$VBoxContainer/HBoxContainer/ShowSimSettings.visible = true

func _on_show_sim_settings_pressed():
	$VBoxContainer/HBoxContainer/ShowSimSettings.visible = false
	$SimulationSettingsWindow.visible = true


func _on_apply_weights_pressed():
	var wv := get_node("SimulationSettingsWindow/Tabs/Kernel/CellWeights/NewWeights/WeightValues")
	updateWeights([
		float(wv.get_node("TopLeft").text),
		float(wv.get_node("Top").text),
		float(wv.get_node("TopRight").text),
		float(wv.get_node("Left").text),
		float(wv.get_node("Center").text),
		float(wv.get_node("Right").text),
		float(wv.get_node("BottomLeft").text),
		float(wv.get_node("Bottom").text),
		float(wv.get_node("BottomRight").text)
	])
