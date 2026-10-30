class_name MapaVista
extends Node2D
## Dibuja un `Mapa` de la simulación con dos TileMapLayer (suelo y bloques).
## No decide colisiones: solo pregunta al mapa y lo muestra.

signal casilla_senalada(casilla: Vector2i, tipo: Mapa.Tipo, transitable: bool)

@export_file("*.txt") var ruta_mapa := "res://data/mapas/prueba.txt"

var mapa: Mapa

@onready var _suelo: TileMapLayer = $Suelo
@onready var _cursor: Node2D = $Cursor
## Capa con y-sort: muros, columnas y personajes se ordenan entre sí por su casilla,
## así el jugador pasa por detrás de lo que está más cerca de la cámara.
@onready var _mundo: Node2D = $Mundo
@onready var _bloques: TileMapLayer = $Mundo/Bloques

var _casilla_cursor := Vector2i(-1, -1)


func _ready() -> void:
	mapa = Mapa.desde_archivo(ruta_mapa)
	var tileset := TilesPlaceholder.crear_tileset()
	_suelo.tile_set = tileset
	_bloques.tile_set = tileset
	_pintar()
	_cursor.draw.connect(_dibujar_cursor)


## Centro en pantalla (coordenadas locales) de una casilla.
func casilla_a_local(c: Vector2i) -> Vector2:
	return _suelo.map_to_local(c)


func local_a_casilla(p: Vector2) -> Vector2i:
	return _suelo.local_to_map(p)


func casilla_bajo_el_raton() -> Vector2i:
	return local_a_casilla(get_local_mouse_position())


## Agrega algo que debe ordenarse en profundidad con muros y columnas.
func agregar_al_mundo(nodo: Node2D) -> void:
	_mundo.add_child(nodo)


func centro_del_mapa() -> Vector2:
	return casilla_a_local(Vector2i(mapa.ancho / 2, mapa.alto / 2))


func _pintar() -> void:
	_suelo.clear()
	_bloques.clear()
	for y in mapa.alto:
		for x in mapa.ancho:
			var c := Vector2i(x, y)
			var tipo := mapa.tipo_en(c)
			if tipo == Mapa.Tipo.VACIO:
				continue
			# Ajedrezado sutil para leer mejor las casillas.
			var variante := TilesPlaceholder.SUELO_A if (x + y) % 2 == 0 else TilesPlaceholder.SUELO_B
			_suelo.set_cell(c, TilesPlaceholder.FUENTE_SUELO, variante)
			match tipo:
				Mapa.Tipo.MURO:
					_bloques.set_cell(c, TilesPlaceholder.FUENTE_BLOQUES, TilesPlaceholder.MURO)
				Mapa.Tipo.COLUMNA:
					_bloques.set_cell(c, TilesPlaceholder.FUENTE_BLOQUES, TilesPlaceholder.COLUMNA)


func _process(_delta: float) -> void:
	var c := casilla_bajo_el_raton()
	if c != _casilla_cursor:
		_casilla_cursor = c
		_cursor.queue_redraw()
		casilla_senalada.emit(c, mapa.tipo_en(c), mapa.es_transitable(c))


## Rombo verde si la casilla se puede pisar, rojo si bloquea.
func _dibujar_cursor() -> void:
	if not mapa.esta_dentro(_casilla_cursor):
		return
	var centro := casilla_a_local(_casilla_cursor)
	var m := Vector2(TilesPlaceholder.TAM_TILE) / 2.0
	var rombo := PackedVector2Array([
		centro + Vector2(0, -m.y), centro + Vector2(m.x, 0),
		centro + Vector2(0, m.y), centro + Vector2(-m.x, 0),
	])
	var color := Color(0.3, 0.9, 0.4, 0.45) if mapa.es_transitable(_casilla_cursor) else Color(0.95, 0.25, 0.2, 0.45)
	_cursor.draw_colored_polygon(rombo, color)
	rombo.append(rombo[0])
	_cursor.draw_polyline(rombo, Color(color, 0.9), 1.0)
