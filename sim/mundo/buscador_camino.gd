class_name BuscadorCamino
extends RefCounted
## Pathfinding A* sobre un `Mapa`, con las mismas reglas de paso que `Mapa.puede_moverse`:
## 8 direcciones y sin cortar esquinas en diagonal.

var _astar := AStarGrid2D.new()


func _init(mapa: Mapa) -> void:
	_astar.region = Rect2i(0, 0, mapa.ancho, mapa.alto)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.update()
	for y in mapa.alto:
		for x in mapa.ancho:
			var c := Vector2i(x, y)
			_astar.set_point_solid(c, not mapa.es_transitable(c))


## Casillas a recorrer desde `desde` (sin incluirla) hasta `hacia`.
## Si `hacia` está bloqueada o no se puede alcanzar, el camino llega lo más cerca posible.
## Devuelve vacío si no hay nada que caminar.
func camino(desde: Vector2i, hacia: Vector2i) -> Array[Vector2i]:
	var resultado: Array[Vector2i] = []
	if not _astar.region.has_point(desde) or not _astar.region.has_point(hacia):
		return resultado
	if _astar.is_point_solid(desde):
		return resultado
	var puntos := _astar.get_id_path(desde, hacia, true)
	for i in range(1, puntos.size()):
		resultado.append(puntos[i])
	return resultado
