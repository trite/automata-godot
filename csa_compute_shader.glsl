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
    // gl_GlobalInvocationID.x uniquely identifies this invocation across all work groups
    // simulation_buffer.data[gl_GlobalInvocationID.x] *= kernel_buffer.data[0];
    simulation_buffer.data[gl_GlobalInvocationID.x] *= float(row_length_info_buffer.kernel_row_length);
}