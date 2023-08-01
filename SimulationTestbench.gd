extends Control

var weights := [ 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0 ]

var kernel_row_length := 3

# TODO: This should probably live somewhere else
var simulation_grid_width := 20
var simulation_grid_height := 20

enum SimulationState {
	PAUSE_REQUESTED,
	PAUSED,
	RUN_REQUESTED,
	RUNNING,
	STEP_REQUESTED
}

var simulationState := SimulationState.PAUSED

# i: 0, limit: <400, move_by: 20
# slice from 0 to 20

const initialSimulationData := [
		0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
]

var simulationData := initialSimulationData

var rd := RenderingServer.create_local_rendering_device()
var shader_file := load("res://csa_compute_shader.glsl")
var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
var shader := rd.shader_create_from_spirv(shader_spirv)


func simStateToString(simState):
	match simState:
		SimulationState.PAUSE_REQUESTED:
			return "PAUSE_REQUESTED"
		SimulationState.PAUSED:
			return "PAUSED"
		SimulationState.RUN_REQUESTED:
			return "RUN_REQUESTED"
		SimulationState.RUNNING:
			return "RUNNING"
		SimulationState.STEP_REQUESTED:
			return "STEP_REQUESTED"
		_:
			return "UNKNOWN STATE!!!!!!!!"

func makeDebugInfo():
	$VBoxContainer/BodyRow/DebugInfo.text = \
		"Current state: " + simStateToString(simulationState)

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

func updateCellRenderer():
	var arr2d = []

	for i in range(0, simulationData.size(), simulation_grid_width):
		var row = simulationData.slice(i, i + simulation_grid_width)

		# For debugging only, will print a ton of data very rapidly
		# print(row)

		arr2d.append(row)

	# For debugging only, will print a ton of data very rapidly
	# print()

	$VBoxContainer/BodyRow/CellRenderer.cells = arr2d
	
func stepSimulationForward(_frames: int):
	# Kernel uniform
	var kernel := PackedFloat32Array(weights)
	var kernel_bytes := kernel.to_byte_array()
	var kernel_buffer := rd.storage_buffer_create(kernel_bytes.size(), kernel_bytes)
	var kernel_uniform := RDUniform.new()
	kernel_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	kernel_uniform.binding = 0 # this needs to match the "binding" in our shader file
	kernel_uniform.add_id(kernel_buffer)

	# Row lengths uniform
	var row_length_info_bytes := PackedInt32Array([kernel_row_length, simulation_grid_width]).to_byte_array()
	var row_length_info_buffer := rd.storage_buffer_create(row_length_info_bytes.size(), row_length_info_bytes)
	var row_length_info_uniform := RDUniform.new()
	row_length_info_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	row_length_info_uniform.binding = 1
	row_length_info_uniform.add_id(row_length_info_buffer)

	# Cell data uniform
	var simulation_input := PackedFloat32Array(simulationData)
	var simulation_bytes := simulation_input.to_byte_array()
	var simulation_buffer := rd.storage_buffer_create(simulation_bytes.size(), simulation_bytes)
	var simulation_uniform := RDUniform.new()
	simulation_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	simulation_uniform.binding = 2
	simulation_uniform.add_id(simulation_buffer)

	var uniform_set := rd.uniform_set_create([
		kernel_uniform,
		row_length_info_uniform,
		simulation_uniform
	], shader, 0)

	# Create a compute pipeline
	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 16, 1, 1)
	rd.compute_list_end()

	# Submit to GPU and wait for sync
	# TODO: Docs say that we shouldn't normally sync here,
	#         so figure that out at some point
	rd.submit()
	rd.sync()

	# Read back the data from the buffer
	var output_bytes := rd.buffer_get_data(simulation_buffer)
	simulationData = output_bytes.to_float32_array()

	updateCellRenderer()

# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/BodyRow/CellRenderer.grid_width = simulation_grid_width
	$VBoxContainer/BodyRow/CellRenderer.grid_height = simulation_grid_height

	updateCellRenderer()
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
			stepSimulationForward(1)

		SimulationState.STEP_REQUESTED:
			stepSimulationForward(1)
			simulationState = SimulationState.PAUSED

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

func _input(event):
	if event.is_action_pressed("ui_accept"):
		toggleSimulationState()

	if event.is_action_pressed("step_simulation"):
		simulationState = SimulationState.STEP_REQUESTED

	if event.is_action_pressed("reset_simulation"):
		simulationData = initialSimulationData
		match simulationState:
			SimulationState.PAUSED, \
			SimulationState.PAUSE_REQUESTED, \
			SimulationState.STEP_REQUESTED:
				updateCellRenderer()

			_:
				pass

			

