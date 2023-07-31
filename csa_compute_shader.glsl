#[compute]
#version 450

layout(local_size_x = 2, local_size_y = 1, local_size_z = 1) in;

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
    // float top_left = simulation_buffer.data[gl_GlobalInvocationID.x - row_length_info_buffer.simulation_row_length - 1] * kernel_buffer.data[0];
    float top_left = getCellValue(-1, -1, 0);
    float top = getCellValue(0, -1, 1);
    float top_right = getCellValue(1, -1, 2);
    float left = getCellValue(-1, 1, 3);
    float center = getCellValue(0, 1, 4);
    float right = getCellValue(1, 1, 5);
    float bottom_left = getCellValue(-1, 1, 6);
    float bottom = getCellValue(0, 1, 7);
    float bottom_right = getCellValue(1, 1, 8);

    float sum = top_left + top + top_right + left + center + right + bottom_left + bottom + bottom_right;

    if (sum == 3.0) {
        simulation_buffer.data[gl_GlobalInvocationID.x] = 1.0;
    } else if (sum == 2.0) {
        simulation_buffer.data[gl_GlobalInvocationID.x] = simulation_buffer.data[gl_GlobalInvocationID.x];
    } else {
        simulation_buffer.data[gl_GlobalInvocationID.x] = 0.0;
    }
}