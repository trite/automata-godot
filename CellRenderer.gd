extends SubViewportContainer

@export var cells := [[]]

var cell_sprites := [[]]

@onready var sprite_width: int = $Viewport/Cell.texture.get_width() * $Viewport/Cell.scale.x
@onready var sprite_height: int = $Viewport/Cell.texture.get_height() * $Viewport/Cell.scale.y

@export var deadCellModulation: Color = Color(0.25, 0.25, 0.25, 0.75)

func setCellSprite(x: int, y: int, newValue: int) -> void:
	if newValue == 1:
		cell_sprites[y][x].self_modulate = Color.WHITE
	else:
		cell_sprites[y][x].self_modulate = deadCellModulation

func populateCellSprites():
	# var emptyRow = []
	# emptyRow.resize(cells[0].size())
	# emptyRow.fill(0)

	# var emptyArr = []
	# emptyArr.resize(cells.size())
	# emptyArr.fill(emptyRow)

	cell_sprites = []
	cell_sprites.resize(cells.size())

	for y in range(0, cells.size()):
		cell_sprites[y] = []
		cell_sprites[y].resize(cells[y].size())
		for x in range(0, cells[y].size()):
			var cell_sprite = $Viewport/Cell.duplicate()

			cell_sprite.position = Vector2(x * sprite_width, y * sprite_height)
			cell_sprite.self_modulate = deadCellModulation
			cell_sprite.visible = true
			cell_sprite.get_node("Label").text = str(x) + "," + str(y)
			$Viewport/Canvas.add_child(cell_sprite)

			cell_sprites[y][x] = cell_sprite
	
func _ready():
	# Make sure to hide the template cell
	$Viewport/Cell.visible = false

	print(sprite_width)
	print(sprite_height)

	# for y in range(0, cells.size()):
	# 	cell_sprites.append([])

	# 	for x in range(0, cells[y].size()):
	# 		var cell_sprite = $Viewport/Cell.duplicate()

	# 		cell_sprite.position = Vector2(x * sprite_width, y * sprite_height)
	# 		cell_sprite.visible = true
	# 		cell_sprite.get_node("Label").text = str(x) + "," + str(y)
	# 		$Viewport/Canvas.add_child(cell_sprite)

	# 		cell_sprites[y].append(cell_sprite)

func _process(_delta):
	var cell_sprites_size = cell_sprites.size()
	var cells_size = cells.size() 
	var cell_sprites_row_size = cell_sprites[0].size()
	var cells_row_size = cells[0].size()

	# if cell_sprites.size() != cells.size() or cell_sprites[0].size() != cells[0].size():
	if cell_sprites_size != cells_size or cell_sprites_row_size != cells_row_size:
		populateCellSprites()

	for y in range(0, cells.size()):
		for x in range(0, cells[y].size()):
			setCellSprite(x, y, cells[y][x])

