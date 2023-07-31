extends SubViewportContainer

@export var grid_width := 20

@export var grid_height := 20

@export var cells := []

var cell_sprites := []

@onready var sprite_width: int = $Viewport/Cell.texture.get_width() * $Viewport/Cell.scale.x
@onready var sprite_height: int = $Viewport/Cell.texture.get_height() * $Viewport/Cell.scale.y

@export var deadCellModulation: Color = Color(0.25, 0.25, 0.25, 0.75)

# Called when the node enters the scene tree for the first time.
func _ready():
	# Make sure to hide the template cell
	$Viewport/Cell.visible = false

	print(sprite_width)
	print(sprite_height)

	for y in range(0, grid_height):
		cell_sprites.append([])

		for x in range(0, grid_width):
			var cell_sprite = $Viewport/Cell.duplicate()

			cell_sprite.position = Vector2(x * sprite_width, y * sprite_height)
			cell_sprite.visible = true
			cell_sprite.get_node("Label").text = str(x) + "," + str(y)
			$Viewport/Canvas.add_child(cell_sprite)

			cell_sprites[y].append(cell_sprite)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	for y in range(0, grid_height):
		for x in range(0, grid_width):
			cell_sprites[x][y].self_modulate = Color.WHITE if cells[x][y] == 1 else deadCellModulation