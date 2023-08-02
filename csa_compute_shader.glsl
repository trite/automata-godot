#[compute]
#version 450

layout(local_size_x = 5, local_size_y = 5, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict buffer Chunks {
  float data[];
} chunks_buffer;

layout(set = 0, binding = 1, std430) restrict buffer KernelBuffer {
    float data[];
} kernel_buffer;

layout(set = 0, binding = 2, std430) restrict buffer DetailsBuffer {
    int kernel_row_length;
    int chunk_row_length;
    int chunk_padding;
} details_buffer;

int getGlobalIndex(int x, int y) {
  int chunk_index = int(gl_WorkGroupID.x + gl_WorkGroupID.y * gl_NumWorkGroups.x);
  int local_index = int((y - details_buffer.chunk_padding) * details_buffer.chunk_row_length + (x - details_buffer.chunk_padding));
  return chunk_index * details_buffer.chunk_row_length * details_buffer.chunk_row_length + local_index;
}

float getCellValue(int x, int y, int kernel_x, int kernel_y) {
  int global_index = getGlobalIndex(x, y);

  // int pos = y * details_buffer.chunk_row_length + x;
  int kernel_pos = kernel_y * details_buffer.kernel_row_length + kernel_x;
  return chunks_buffer.data[global_index] * kernel_buffer.data[kernel_pos];
}

void setCellValue(int x, int y, float new_value) {
  int global_index = getGlobalIndex(x, y);
  chunks_buffer.data[global_index] = new_value;
}


// The code we want to execute in each invocation
void main() {
  int x = int(gl_LocalInvocationID.x + details_buffer.chunk_padding);
  int y = int(gl_LocalInvocationID.y + details_buffer.chunk_padding);


  float top_left = getCellValue(x-1, y-1, 0, 0);
  float top = getCellValue(x, y-1, 1, 0);
  float top_right = getCellValue(x+1, y-1, 2, 0);

  float left = getCellValue(x-1, y, 0, 1);
  float center = getCellValue(x, y, 1, 1);
  float right = getCellValue(x+1, y, 2, 1);

  float bottom_left = getCellValue(x-1, y+1, 0, 2);
  float bottom = getCellValue(x, y+1, 1, 2);
  float bottom_right = getCellValue(x+1, y+1, 2, 2);

  int sum = int(top_left + top + top_right + left + center + right + bottom_left + bottom + bottom_right);

  int global_index = getGlobalIndex(x, y);

  if (sum == 3) {
      chunks_buffer.data[global_index] = 1.0;
  } else if (sum == 2) {
      chunks_buffer.data[global_index] = chunks_buffer.data[global_index];
  } else {
      chunks_buffer.data[global_index] = 0.0;
  }

  // For debugging
  // chunks_buffer.data[global_index] = float(global_index);
}