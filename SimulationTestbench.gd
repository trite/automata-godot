extends Control

var weights := [ 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0]

var kernel_row_length := 3

var simulation_row_length := 10

enum SimulationState {
	PAUSE_REQUESTED,
	PAUSED,
	RUN_REQUESTED,
	RUNNING,
	# STEP_REQUESTED,
	# STEPPING
}

var simulationState := SimulationState.PAUSED

var rd := RenderingServer.create_local_rendering_device()
var shader_file := load("res://csa_compute_shader.glsl")
var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
var shader := rd.shader_create_from_spirv(shader_spirv)

func simStateToString(simState):
	match simState:
		0:
			return "PAUSE_REQUESTED"
		1:
			return "PAUSED"
		2:
			return "RUN_REQUESTED"
		3:
			return "RUNNING"
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

# Called when the node enters the scene tree for the first time.
func _ready():
	makeDebugInfo()

	var kernel := PackedFloat32Array([1, 1, 1, 1, 0, 1, 1, 1, 1])
	var kernel_bytes := kernel.to_byte_array()

	var kernel_buffer := rd.storage_buffer_create(kernel_bytes.size(), kernel_bytes)

	var kernel_uniform := RDUniform.new()
	kernel_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	kernel_uniform.binding = 0 # this needs to match the "binding" in our shader file
	kernel_uniform.add_id(kernel_buffer)

	var kernel_row_length_uniform := RDUniform.new()
	kernel_row_length_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER

	var row_length_info_bytes := PackedByteArray(
		PackedInt32Array([kernel_row_length, simulation_row_length]).to_byte_array())

	var row_length_info_buffer := rd.storage_buffer_create(
		row_length_info_bytes.size(), row_length_info_bytes)

	var row_length_info_uniform := RDUniform.new()
	row_length_info_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	row_length_info_uniform.binding = 1
	row_length_info_uniform.add_id(row_length_info_buffer)


	# Prepare our data. We use floats in the shader, so we need 32 bit.
	var simulation_input := PackedFloat32Array([
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    1, 1, 1, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0
  ])

# [1, 1, 1, 0, 0, 
#  0, 0, 0, 0, 0,
#  1, 1, 1, 0, 0,
#  0, 0, 0, 0, 0,
#  0, 0, 0, 0, 0]



	var simulation_bytes := simulation_input.to_byte_array()

	# Create a storage buffer that can hold our float values.
	# Each float has 4 bytes (32 bit) so 10 x 4 = 40 bytes
	var simulation_buffer := rd.storage_buffer_create(simulation_bytes.size(), simulation_bytes)

	# Create a uniform to assign the buffer to the rendering device
	var simulation_uniform := RDUniform.new()
	simulation_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	simulation_uniform.binding = 2 # this needs to match the "binding" in our shader file
	simulation_uniform.add_id(simulation_buffer)


	# TODO: missing 2 uniforms here (total of 4)
	var uniform_set := rd.uniform_set_create([
		kernel_uniform,
		row_length_info_uniform,
		simulation_uniform
	], shader, 0) # the last parameter (the 0) needs to match the "set" in our shader file

	# Create a compute pipeline
	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 5, 1, 1)
	rd.compute_list_end()

	# Submit to GPU and wait for sync
	rd.submit()
	rd.sync()

	# Read back the data from the buffer
	var output_bytes := rd.buffer_get_data(simulation_buffer)
	var output := output_bytes.to_float32_array()
	print("Input: ", simulation_input)
	print("Output: ", output)

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