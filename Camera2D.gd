extends Camera2D

# Define pan and zoom speed
var pan_speed: float = 300
var zoom_speed: float = 0.05
var dragging: bool = false
var drag_start: Vector2
var target_position: Vector2
var lerp_speed: float = 0.1

var zoom_min: float = 0.1
var zoom_max: float = 4.0

# func _ready():

func _process(delta):
  # Panning
  if Input.is_key_pressed(KEY_W):
    position.y -= pan_speed * delta
  if Input.is_key_pressed(KEY_S):
    position.y += pan_speed * delta
  if Input.is_key_pressed(KEY_A):
    position.x -= pan_speed * delta
  if Input.is_key_pressed(KEY_D):
    position.x += pan_speed * delta

  # Zooming
  if Input.is_key_pressed(KEY_Q):
    zoom.x -= zoom_speed * delta
    zoom.y -= zoom_speed * delta
  if Input.is_key_pressed(KEY_E):
    zoom.x += zoom_speed * delta
    zoom.y += zoom_speed * delta

  # Clamp zoom to avoid negative values
  zoom.x = clamp(zoom.x, zoom_min, zoom_max)
  zoom.y = clamp(zoom.y, zoom_min, zoom_max)

  position = position.lerp(target_position, lerp_speed)

func _unhandled_input(event):
  if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_LEFT:
      if event.is_pressed():
        dragging = true
        drag_start = get_global_mouse_position()
      else:
        dragging = false

    elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
      zoom.x -= zoom_speed
      zoom.y -= zoom_speed

    elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
      zoom.x += zoom_speed
      zoom.y += zoom_speed

  elif event is InputEventMouseMotion and dragging:
    var drag_current = get_global_mouse_position()
    var drag_delta = drag_start - drag_current
    target_position += drag_delta
    drag_start = drag_current

  # Clamp zoom to avoid negative values
  zoom.x = clamp(zoom.x, zoom_min, zoom_max)
  zoom.y = clamp(zoom.y, zoom_min, zoom_max)