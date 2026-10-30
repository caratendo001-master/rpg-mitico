extends GdUnitTestSuite
## Pruebas del pathfinding A*.

const SALAS := """
#########
#.......#
#.......#
####.####
#.......#
#...O...#
#########
"""

var _mapa: Mapa
var _buscador: BuscadorCamino


func before_test() -> void:
	_mapa = Mapa.desde_texto(SALAS)
	_buscador = BuscadorCamino.new(_mapa)


func test_linea_recta() -> void:
	var camino := _buscador.camino(Vector2i(1, 1), Vector2i(4, 1))
	assert_array(camino).is_equal([Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1)])


func test_misma_casilla_no_camina() -> void:
	assert_array(_buscador.camino(Vector2i(2, 2), Vector2i(2, 2))).is_empty()


func test_rodea_el_muro_por_la_puerta() -> void:
	var camino := _buscador.camino(Vector2i(1, 1), Vector2i(1, 4))
	assert_array(camino).contains([Vector2i(4, 3)]) # la única puerta
	assert_that(camino.back()).is_equal(Vector2i(1, 4))
	_assert_pasos_validos(Vector2i(1, 1), camino)


func test_cada_paso_respeta_las_reglas_del_mapa() -> void:
	# Pasa junto a la columna: no debe cortar la esquina.
	var camino := _buscador.camino(Vector2i(1, 1), Vector2i(7, 5))
	assert_array(camino).is_not_empty()
	_assert_pasos_validos(Vector2i(1, 1), camino)


func test_destino_bloqueado_llega_lo_mas_cerca_posible() -> void:
	var camino := _buscador.camino(Vector2i(1, 4), Vector2i(4, 5)) # la columna
	assert_array(camino).is_not_empty()
	var final: Vector2i = camino.back()
	assert_bool(_mapa.es_transitable(final)).is_true()
	assert_int(maxi(absi(final.x - 4), absi(final.y - 5))).is_equal(1)


func test_fuera_del_mapa_no_camina() -> void:
	assert_array(_buscador.camino(Vector2i(1, 1), Vector2i(50, 50))).is_empty()
	assert_array(_buscador.camino(Vector2i(1, 1), Vector2i(-1, 0))).is_empty()


func _assert_pasos_validos(inicio: Vector2i, camino: Array[Vector2i]) -> void:
	var actual := inicio
	for siguiente in camino:
		assert_bool(_mapa.puede_moverse(actual, siguiente)) \
			.override_failure_message("Paso inválido %s -> %s" % [actual, siguiente]).is_true()
		actual = siguiente
