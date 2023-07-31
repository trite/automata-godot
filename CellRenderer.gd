extends SubViewportContainer

@export var cells := [
  [0, 1, 0, 1, 0],
  [1, 0, 1, 0, 1],
  [0, 1, 0, 1, 0],
  [1, 0, 1, 0, 1],
  [0, 1, 0, 1, 0],
];

var cell_sprites := [
  [null, null, null, null, null],
  [null, null, null, null, null],
  [null, null, null, null, null],
  [null, null, null, null, null],
  [null, null, null, null, null],
]

@onready var sprite_width: int = $Viewport/Cell.texture.get_width() * $Viewport/Cell.scale.x
@onready var sprite_height: int = $Viewport/Cell.texture.get_height() * $Viewport/Cell.scale.y

# Called when the node enters the scene tree for the first time.
func _ready():
	print(sprite_width)
	print(sprite_height)

	for y in range(0, cell_sprites.size()):
		for x in range(0, cell_sprites[y].size()):
			var cell = $Viewport/Cell.duplicate()
			cell.visible = cells[x][y] == 1
			cell.position = Vector2(y * sprite_width, x * sprite_height)
			$Viewport/Canvas.add_child(cell)
			cell_sprites[x][y] = cell

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	for y in range(0, cell_sprites.size()):
		for x in range(0, cell_sprites[y].size()):
			cell_sprites[x][y].visible = cells[x][y] == 1
