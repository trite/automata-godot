extends Control

var weights := [ 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0, 1.0 ]

var kernel_row_length := 3

# TODO: This should probably live somewhere else
var simulation_grid_width := 100
var simulation_grid_height := 100

# var simulation_x_size := 2
# var x_groups := 1

enum SimulationState {
	PAUSE_REQUESTED,
	PAUSED,
	RUN_REQUESTED,
	RUNNING,
	STEP_REQUESTED
}

var simulationState := SimulationState.PAUSED

var initialSimulationData := [[]]

var simulationData := [[]]

var shaderPath = "res://csa_compute_shader.glsl"

var rd := RenderingServer.create_local_rendering_device()
var shader := rd.shader_create_from_spirv(load(shaderPath).get_spirv())

func generateInitialSimulationData():
	initialSimulationData = []

	for y in range(0, simulation_grid_height):
		initialSimulationData.append([])
		for x in range(0, simulation_grid_width):
			initialSimulationData[y].append(0)

	initialSimulationData[0][1] = 1
	initialSimulationData[1][2] = 1
	initialSimulationData[2][0] = 1
	initialSimulationData[2][1] = 1
	initialSimulationData[2][2] = 1

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

func updateDebugInfo():
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
	# var arr2d = []

	# for i in range(0, simulationData.size(), simulation_grid_width):
	# 	var row = simulationData.slice(i, i + simulation_grid_width)

	# 	# For debugging only, will print a ton of data very rapidly
	# 	# if i == 0:
	# 	# 	print()
	# 	# print(row)

	# 	arr2d.append(row)

	# for debugging only, prints a ton
	# print("Sim data:")
	# print(simulationData)

	$VBoxContainer/BodyRow/CellRenderer.cells = simulationData
	
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
	simulationData = rd.buffer_get_data(simulation_buffer).to_float32_array()

	updateCellRenderer()

# chunking settings
#   this will make a 7x7 grid of input data
#   the padding is needed so each target cell can access its neighbors in that chunk
#   target cells are the inner 5x5 grid, this is also the output for the chunk from the shader
const CHUNK_SIZE = 5  # the core size of each chunk
const CHUNK_PADDING = 1     # extra padding around each chunk
const TOTAL_CHUNK_SIZE = CHUNK_SIZE + 2 * CHUNK_PADDING

# creates an array that is (CHUNK_SIZE + PADDING)^2 in total length
func create_chunks(data):
	var chunks = []
	var grid_width = data.size()
	var grid_height = data[0].size()  # Assuming all inner arrays are the same size
	for x in range(0, grid_width, CHUNK_SIZE):
		for y in range(0, grid_height, CHUNK_SIZE):
			var chunk = PackedFloat32Array()
			for i in range(x - CHUNK_PADDING, x + CHUNK_SIZE + CHUNK_PADDING):
				for j in range(y - CHUNK_PADDING, y + CHUNK_SIZE + CHUNK_PADDING):
					var wrapped_i = (i + grid_width) % grid_width  # wrap around the grid if needed
					var wrapped_j = (j + grid_height) % grid_height
					chunk.append(data[wrapped_i][wrapped_j])
			chunks.append(chunk)
	return chunks

func unflatten_chunks(flattened_chunks, grid_width, grid_height):
	var grid = []
	grid.resize(grid_height)
	for y in range(grid_height):
		var row = []
		row.resize(grid_width)
		row.fill(0)
		grid[y] = row
	
	var num_chunks_x = ceil(grid_width / CHUNK_SIZE)
	var num_chunks_y = ceil(grid_height / CHUNK_SIZE)
	var chunk_index = 0
	
	for chunk_x in range(num_chunks_x):
		for chunk_y in range(num_chunks_y):
			for local_x in range(CHUNK_SIZE):
				for local_y in range(CHUNK_SIZE):
					var global_x = chunk_x * CHUNK_SIZE + local_x
					var global_y = chunk_y * CHUNK_SIZE + local_y
					
					if global_x >= grid_width or global_y >= grid_height:
						continue

					var flattened_index = chunk_index * (TOTAL_CHUNK_SIZE * TOTAL_CHUNK_SIZE) + \
						(local_y + CHUNK_PADDING) * TOTAL_CHUNK_SIZE + (local_x + CHUNK_PADDING)

					# print("chunk_x:", chunk_x, " chunk_y:", chunk_y, " local_x:", local_x, " local_y:", local_y)
					# print("global_x:", global_x, " global_y:", global_y, " flattened_index:", flattened_index)
					
					if flattened_index < len(flattened_chunks): # This check is optional but prevents out-of-range errors
						grid[global_y][global_x] = flattened_chunks[flattened_index]
			chunk_index += 1


	print("grid to unflatten (truncated):")
	flattened_chunks.resize(800)
	print(flattened_chunks)
	print("unflattened grid (truncated):")

	for row in range(0, 8):
		print(grid[row])
					
	return grid

func stepSimulationForwardV2(_frames: int):
	var chunks = create_chunks(simulationData)

	print("preparing simulation run with input data (trunated):")
	for row in range(0, 8):
		print(simulationData[row])

	# Flatten the 2D chunks into a 1D array
	var flattened_chunks = []
	for chunk in chunks:
		for value in chunk:
			flattened_chunks.append(value)

	print("simulation data flattened to (truncated):")
	var temp_flattened_chunks = flattened_chunks
	temp_flattened_chunks.resize(800)
	print(temp_flattened_chunks)
					
	# Data chunks uniform
	var chunk_data = PackedFloat32Array(flattened_chunks)
	var chunk_data_bytes = chunk_data.to_byte_array()
	var chunk_buffer = rd.storage_buffer_create(chunk_data_bytes.size(), chunk_data_bytes)
	var chunk_uniform = RDUniform.new()
	chunk_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	chunk_uniform.binding = 0 # Assign a new binding
	chunk_uniform.add_id(chunk_buffer)

	# Kernel uniform
	var kernel := PackedFloat32Array(weights)
	var kernel_bytes := kernel.to_byte_array()
	var kernel_buffer := rd.storage_buffer_create(kernel_bytes.size(), kernel_bytes)
	var kernel_uniform := RDUniform.new()
	kernel_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	kernel_uniform.binding = 1 # this needs to match the "binding" in our shader file
	kernel_uniform.add_id(kernel_buffer)

	# Row lengths uniform
	# TODO: Is there a better way of making sure I don't forget these values when making this?
	# layout(set = 0, binding = 2, std430) restrict buffer DetailsBuffer {
	# 		int kernel_row_length;
	# 		int chunk_row_length;
	# 		int chunk_padding;
	# } details_buffer;
	var row_length_info_bytes := PackedInt32Array([kernel_row_length, CHUNK_SIZE, CHUNK_PADDING]).to_byte_array()
	var row_length_info_buffer := rd.storage_buffer_create(row_length_info_bytes.size(), row_length_info_bytes)
	var row_length_info_uniform := RDUniform.new()
	row_length_info_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	row_length_info_uniform.binding = 2
	row_length_info_uniform.add_id(row_length_info_buffer)

	var uniform_set := rd.uniform_set_create([
		kernel_uniform,
		row_length_info_uniform,
		chunk_uniform
	], shader, 0)

	# Determine workgroups needed
	@warning_ignore("integer_division")
	var workgroups_x = ceil(float(simulation_grid_width) / float(CHUNK_SIZE))
	@warning_ignore("integer_division")
	var workgroups_y = ceil(float(simulation_grid_height) / float(CHUNK_SIZE))

	# Create a compute pipeline
	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, workgroups_x, workgroups_y, 1)
	rd.compute_list_end()

	# Submit to GPU and wait for sync
	# TODO: Docs say that we shouldn't normally sync here,
	#         so figure that out at some point
	rd.submit()
	rd.sync()

	# Read back the data from the buffer
	var flattened_chunks_result = rd.buffer_get_data(chunk_buffer).to_float32_array()
	# print(flattened_chunks_result.size())
	simulationData = unflatten_chunks(flattened_chunks_result, simulation_grid_width, simulation_grid_height)

	updateCellRenderer()


func _ready():
	generateInitialSimulationData()
	simulationData = initialSimulationData

	# x_groups = simulation_x_size / simulation_grid_width + 1

	updateCellRenderer()

	updateDebugInfo()

func _process(_delta):
	match simulationState:
		SimulationState.PAUSE_REQUESTED:
			simulationState = SimulationState.PAUSED

		SimulationState.RUN_REQUESTED:
			simulationState = SimulationState.RUNNING

		SimulationState.PAUSED:
			pass

		SimulationState.RUNNING:
			stepSimulationForwardV2(1)

		SimulationState.STEP_REQUESTED:
			stepSimulationForwardV2(1)
			simulationState = SimulationState.PAUSED

		_:
			pass

	updateDebugInfo()

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
		# Reset the data itself
		simulationData = initialSimulationData

		match simulationState:
			# Manually update CellRenderer if in a state that wouldn't otherwise
			SimulationState.PAUSED, \
			SimulationState.PAUSE_REQUESTED, \
			SimulationState.STEP_REQUESTED:
				updateCellRenderer()

			# For events that will already update we have nothing to do
			_:
				pass

			

