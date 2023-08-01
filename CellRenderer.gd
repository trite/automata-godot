extends SubViewportContainer

@export var cells := []

var cell_sprites := []

@onready var sprite_width: int = $Viewport/Cell.texture.get_width() * $Viewport/Cell.scale.x
@onready var sprite_height: int = $Viewport/Cell.texture.get_height() * $Viewport/Cell.scale.y

@export var deadCellModulation: Color = Color(0.25, 0.25, 0.25, 0.75)

func setCellSprite(x: int, y: int, newValue: int) -> void:
	while cell_sprites.size() <= y:
		cell_sprites.append([])

	while cell_sprites[y].size() <= x:
		var cell_sprite = $Viewport/Cell.duplicate()

		cell_sprite.position = Vector2(x * sprite_width, y * sprite_height)
		cell_sprite.visible = true
		cell_sprite.self_modulate = deadCellModulation
		cell_sprite.get_node("Label").text = str(x) + "," + str(y)
		$Viewport/Canvas.add_child(cell_sprite)

		cell_sprites[y].append(cell_sprite)

	if newValue == 1:
		cell_sprites[y][x].self_modulate = Color.WHITE
	else:
		cell_sprites[y][x].self_modulate = deadCellModulation
	
func _ready():
	# Make sure to hide the template cell
	$Viewport/Cell.visible = false

	print(sprite_width)
	print(sprite_height)

	for y in range(0, cells.size()):
		cell_sprites.append([])

		for x in range(0, cells[y].size()):
			var cell_sprite = $Viewport/Cell.duplicate()

			cell_sprite.position = Vector2(x * sprite_width, y * sprite_height)
			cell_sprite.visible = true
			cell_sprite.get_node("Label").text = str(x) + "," + str(y)
			$Viewport/Canvas.add_child(cell_sprite)

			cell_sprites[y].append(cell_sprite)

func _process(_delta):
	for y in range(0, cells.size()):
		for x in range(0, cells[y].size()):
			setCellSprite(x, y, cells[y][x])

