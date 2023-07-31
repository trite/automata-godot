#[compute]
#version 450

// Local sizes here and dispatch groups in the SimulationTestbench.gd code
//   When the totals were 10 (local sizes 2,1,1 and dispatch groups 5,1,1)
//     the simulation only seemed to alter about the first 10 cells
//   When the totals were at least 25 (ls 5,1,1 dg 5,1,1 -or- ls 25,1,1 dg 1,1,1)
//     the simulation seems to run for the entire array
layout(local_size_x = 25, local_size_y = 1, local_size_z = 1) in;

// Local Size is listed as "invocations" in the Godot manual:
//   https://docs.godotengine.org/en/stable/tutorials/shaders/compute_shaders.html

layout(set = 0, binding = 0, std430) restrict buffer KernelBuffer {
    float data[];
} kernel_buffer;

layout(set = 0, binding = 1, std430) restrict buffer RowLengthInfoBuffer {
    int kernel_row_length;
    int simulation_row_length;
} row_length_info_buffer;

// A binding to the buffer we create in our script
layout(set = 0, binding = 2, std430) restrict buffer SimulationBuffer {
    float data[];
} simulation_buffer;

int getCellValue(int x, int y, int kernel_position) {
    uint pos = 
        gl_GlobalInvocationID.x
        + y * row_length_info_buffer.simulation_row_length
        + x;

    if (pos >= 0 && pos < simulation_buffer.data.length()) {
        return int(simulation_buffer.data[pos] * kernel_buffer.data[kernel_position]);
    }

    return 0;
}

// The code we want to execute in each invocation
void main() {
    int top_left = getCellValue(-1, -1, 0);
    int top = getCellValue(0, -1, 1);
    int top_right = getCellValue(1, -1, 2);
    int left = getCellValue(-1, 0, 3);
    int center = getCellValue(0, 0, 4);
    int right = getCellValue(1, 0, 5);
    int bottom_left = getCellValue(-1, 1, 6);
    int bottom = getCellValue(0, 1, 7);
    int bottom_right = getCellValue(1, 1, 8);

    int sum = top_left + top + top_right + left + center + right + bottom_left + bottom + bottom_right;

    if (sum == 3) {
        simulation_buffer.data[gl_GlobalInvocationID.x] = 1.0;
    } else if (sum == 2) {
        simulation_buffer.data[gl_GlobalInvocationID.x] = simulation_buffer.data[gl_GlobalInvocationID.x];
    } else {
        simulation_buffer.data[gl_GlobalInvocationID.x] = 0.0;
    }
}