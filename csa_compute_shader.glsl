#[compute]
#version 450

// Invocations in the (x, y, z) dimension
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

// The code we want to execute in each invocation
void main() {
    float top_left = simulation_buffer.data[gl_GlobalInvocationID.x - row_length_info_buffer.simulation_row_length - 1] * kernel_buffer.data[0];
    float top = simulation_buffer.data[gl_GlobalInvocationID.x - row_length_info_buffer.simulation_row_length] * kernel_buffer.data[1];
    float top_right = simulation_buffer.data[gl_GlobalInvocationID.x - row_length_info_buffer.simulation_row_length + 1] * kernel_buffer.data[2];

    float left = simulation_buffer.data[gl_GlobalInvocationID.x-1] * kernel_buffer.data[3];
    float center = simulation_buffer.data[gl_GlobalInvocationID.x] * kernel_buffer.data[4];
    float right = simulation_buffer.data[gl_GlobalInvocationID.x+1] * kernel_buffer.data[5];

    float bottom_left = simulation_buffer.data[gl_GlobalInvocationID.x + row_length_info_buffer.simulation_row_length - 1] * kernel_buffer.data[6];
    float bottom = simulation_buffer.data[gl_GlobalInvocationID.x + row_length_info_buffer.simulation_row_length] * kernel_buffer.data[7];
    float bottom_right = simulation_buffer.data[gl_GlobalInvocationID.x + row_length_info_buffer.simulation_row_length + 1] * kernel_buffer.data[8];

    float sum = top_left + top + top_right + left + center + right + bottom_left + bottom + bottom_right;

    if (sum == 3.0) {
        simulation_buffer.data[gl_GlobalInvocationID.x] = 1.0;
    } else if (sum == 2.0) {
        simulation_buffer.data[gl_GlobalInvocationID.x] = simulation_buffer.data[gl_GlobalInvocationID.x];
    } else {
        simulation_buffer.data[gl_GlobalInvocationID.x] = 0.0;
    }
}