class_name TilesPlaceholder
extends RefCounted
## TileSet isométrico 2:1 (64×32) con texturas generadas por código.
## Sirve hasta que haya pixel art real: entonces se reemplaza por un TileSet .tres
## con las mismas fuentes y coordenadas de atlas.

const TAM_TILE := Vector2i(64, 32)
const ALTO_BLOQUE := 96 # 32 de rombo + 64 de altura

const FUENTE_SUELO := 0
const FUENTE_BLOQUES := 1

# Coordenadas dentro de cada atlas.
const SUELO_A := Vector2i(0, 0)
const SUELO_B := Vector2i(1, 0)
const MURO := Vector2i(0, 0)
const COLUMNA := Vector2i(1, 0)

const COLOR_SUELO_A := Color("5a5560")
const COLOR_SUELO_B := Color("4f4a56")
const COLOR_MURO := Color("7a5f4a")
const COLOR_COLUMNA := Color("a9a08c")


static func crear_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tileset.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	tileset.tile_size = TAM_TILE

	var suelo := TileSetAtlasSource.new()
	var img_suelo := Image.create_empty(TAM_TILE.x * 2, TAM_TILE.y, false, Image.FORMAT_RGBA8)
	_pintar_rombo(img_suelo, 0, COLOR_SUELO_A)
	_pintar_rombo(img_suelo, TAM_TILE.x, COLOR_SUELO_B)
	suelo.texture = ImageTexture.create_from_image(img_suelo)
	suelo.texture_region_size = TAM_TILE
	suelo.create_tile(SUELO_A)
	suelo.create_tile(SUELO_B)
	tileset.add_source(suelo, FUENTE_SUELO)

	var bloques := TileSetAtlasSource.new()
	var img_bloques := Image.create_empty(TAM_TILE.x * 2, ALTO_BLOQUE, false, Image.FORMAT_RGBA8)
	_pintar_prisma(img_bloques, 0, 32, 16, 64, COLOR_MURO)
	_pintar_prisma(img_bloques, TAM_TILE.x, 14, 7, 72, COLOR_COLUMNA)
	bloques.texture = ImageTexture.create_from_image(img_bloques)
	bloques.texture_region_size = Vector2i(TAM_TILE.x, ALTO_BLOQUE)
	bloques.create_tile(MURO)
	bloques.create_tile(COLUMNA)
	tileset.add_source(bloques, FUENTE_BLOQUES)
	# La textura es más alta que la casilla: se sube para que la base del bloque
	# coincida con el rombo de su casilla.
	for coords in [MURO, COLUMNA]:
		bloques.get_tile_data(coords, 0).texture_origin = Vector2i(0, (ALTO_BLOQUE - TAM_TILE.y) / 2)
	return tileset


## Rombo de suelo con un borde más oscuro para que se lea la cuadrícula.
static func _pintar_rombo(img: Image, x0: int, color: Color) -> void:
	var borde := color.darkened(0.35)
	for y in TAM_TILE.y:
		for x in TAM_TILE.x:
			var d := absf(x + 0.5 - TAM_TILE.x / 2.0) / (TAM_TILE.x / 2.0) \
				+ absf(y + 0.5 - TAM_TILE.y / 2.0) / (TAM_TILE.y / 2.0)
			if d <= 1.0:
				img.set_pixel(x0 + x, y, borde if d > 0.9 else color)


## Prisma isométrico cuya base es un rombo de semiejes (medio_ancho, medio_alto)
## centrado en la base de la celda; la cara superior queda `altura` px más arriba.
static func _pintar_prisma(img: Image, x0: int, medio_ancho: int, medio_alto: int, altura: int, color: Color) -> void:
	var cx := TAM_TILE.x / 2.0
	var base_y := ALTO_BLOQUE - TAM_TILE.y / 2.0
	var tapa_y := base_y - altura
	var izquierda := PackedVector2Array([
		Vector2(cx - medio_ancho, tapa_y), Vector2(cx, tapa_y + medio_alto),
		Vector2(cx, base_y + medio_alto), Vector2(cx - medio_ancho, base_y),
	])
	var derecha := PackedVector2Array([
		Vector2(cx, tapa_y + medio_alto), Vector2(cx + medio_ancho, tapa_y),
		Vector2(cx + medio_ancho, base_y), Vector2(cx, base_y + medio_alto),
	])
	var tapa := PackedVector2Array([
		Vector2(cx - medio_ancho, tapa_y), Vector2(cx, tapa_y - medio_alto),
		Vector2(cx + medio_ancho, tapa_y), Vector2(cx, tapa_y + medio_alto),
	])
	for y in ALTO_BLOQUE:
		for x in TAM_TILE.x:
			var punto := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(punto, tapa):
				img.set_pixel(x0 + x, y, color.lightened(0.2))
			elif Geometry2D.is_point_in_polygon(punto, izquierda):
				img.set_pixel(x0 + x, y, color)
			elif Geometry2D.is_point_in_polygon(punto, derecha):
				img.set_pixel(x0 + x, y, color.darkened(0.3))
