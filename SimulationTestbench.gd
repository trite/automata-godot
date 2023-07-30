extends Control

var weights := [ 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0]

enum SimulationState {
	PAUSE_REQUESTED,
	PAUSED,
	RUN_REQUESTED,
	RUNNING,
	# STEP_REQUESTED,
	# STEPPING
}

var simulationState := SimulationState.PAUSED

func makeDebugInfo():
	$VBoxContainer/BodyRow/DebugInfo.text = \
		"Current state: " + str(simulationState)


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

# Called when the node enters the scene tree for the first time.
func _ready():
	makeDebugInfo()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	match simulationState:
		SimulationState.PAUSE_REQUESTED:
			# TODO: Pause simulation here
			simulationState = SimulationState.PAUSED

		SimulationState.RUN_REQUESTED:
			# TODO: Start simulation here
			simulationState = SimulationState.RUNNING

		SimulationState.PAUSED:
			pass

		SimulationState.RUNNING:
			# TODO: Any processing logic during simulation
			pass

		_:
			pass

	makeDebugInfo()

func _on_simulation_settings_window_close_requested():
	$VBoxContainer/HeaderRow/ShowSimSettings.visible = true

func _on_show_sim_settings_pressed():
	$VBoxContainer/HeaderRow/ShowSimSettings.visible = false
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

func toggleSimulationState():
	match simulationState:
		SimulationState.PAUSED:
			simulationState = SimulationState.RUN_REQUESTED
		SimulationState.RUNNING:
			simulationState = SimulationState.PAUSE_REQUESTED
		_:
			pass

# func _unhandled_input(event):
# 	if event.is_action_pressed("ui_accept"):
# 		toggleSimulationState()
# 	# match event:
# 	# 	InputEventKey:

func _input(event):
	if event.is_action_pressed("ui_accept"):
		toggleSimulationState()
