extends GdUnitTestSuite
## Pruebas de la cuadrícula del mundo y sus colisiones.

const SALA := """
#####
#...#
#.O.#
#...#
#####
"""


func test_lee_dimensiones_y_tipos() -> void:
	var mapa := Mapa.desde_texto(SALA)
	assert_int(mapa.ancho).is_equal(5)
	assert_int(mapa.alto).is_equal(5)
	assert_int(mapa.tipo_en(Vector2i(0, 0))).is_equal(Mapa.Tipo.MURO)
	assert_int(mapa.tipo_en(Vector2i(1, 1))).is_equal(Mapa.Tipo.SUELO)
	assert_int(mapa.tipo_en(Vector2i(2, 2))).is_equal(Mapa.Tipo.COLUMNA)


func test_filas_cortas_se_rellenan_con_vacio() -> void:
	var mapa := Mapa.desde_texto("###\n#.\n#")
	assert_int(mapa.ancho).is_equal(3)
	assert_int(mapa.alto).is_equal(3)
	assert_int(mapa.tipo_en(Vector2i(2, 1))).is_equal(Mapa.Tipo.VACIO)
	assert_bool(mapa.es_transitable(Vector2i(2, 1))).is_false()


func test_solo_el_suelo_es_transitable() -> void:
	var mapa := Mapa.desde_texto(SALA)
	assert_bool(mapa.es_transitable(Vector2i(1, 1))).is_true()
	assert_bool(mapa.es_transitable(Vector2i(0, 0))).is_false() # muro
	assert_bool(mapa.es_transitable(Vector2i(2, 2))).is_false() # columna
	assert_bool(mapa.es_transitable(Vector2i(-1, 3))).is_false() # fuera del mapa
	assert_bool(mapa.es_transitable(Vector2i(9, 9))).is_false()


func test_no_se_atraviesan_muros_ni_columnas() -> void:
	var mapa := Mapa.desde_texto(SALA)
	assert_bool(mapa.puede_moverse(Vector2i(1, 1), Vector2i(0, 1))).is_false() # muro
	assert_bool(mapa.puede_moverse(Vector2i(1, 2), Vector2i(2, 2))).is_false() # columna
	assert_bool(mapa.puede_moverse(Vector2i(1, 1), Vector2i(2, 1))).is_true()


func test_solo_pasos_de_una_casilla() -> void:
	var mapa := Mapa.desde_texto(SALA)
	assert_bool(mapa.puede_moverse(Vector2i(1, 1), Vector2i(1, 1))).is_false()
	assert_bool(mapa.puede_moverse(Vector2i(1, 1), Vector2i(3, 1))).is_false()
	assert_bool(mapa.puede_moverse(Vector2i(1, 1), Vector2i(1, 3))).is_false()


func test_diagonal_libre_se_permite() -> void:
	var mapa := Mapa.desde_texto("####\n#..#\n#..#\n####")
	assert_bool(mapa.puede_moverse(Vector2i(1, 1), Vector2i(2, 2))).is_true()


func test_diagonal_no_corta_esquinas() -> void:
	# Rodear la columna (2,2) en diagonal la rozaría por un lado: no se permite.
	var mapa := Mapa.desde_texto(SALA)
	assert_bool(mapa.puede_moverse(Vector2i(1, 2), Vector2i(2, 3))).is_false()
	assert_bool(mapa.puede_moverse(Vector2i(2, 1), Vector2i(3, 2))).is_false()


func test_vecinos_alcanzables_en_esquina() -> void:
	var mapa := Mapa.desde_texto(SALA)
	var vecinos := mapa.vecinos_alcanzables(Vector2i(1, 1))
	# Desde la esquina solo hay derecha y abajo; la diagonal toca la columna.
	assert_array(vecinos).contains_exactly_in_any_order([Vector2i(2, 1), Vector2i(1, 2)])


func test_mapa_de_prueba_cerrado_y_conectado() -> void:
	var mapa := Mapa.desde_archivo("res://data/mapas/prueba.txt")
	assert_int(mapa.ancho).is_equal(20)
	assert_int(mapa.alto).is_equal(14)
	assert_int(mapa.casillas_de_tipo(Mapa.Tipo.COLUMNA).size()).is_greater_equal(2)
	# El borde es muro: no hay forma de salir del mapa.
	for x in mapa.ancho:
		assert_bool(mapa.es_transitable(Vector2i(x, 0))).is_false()
		assert_bool(mapa.es_transitable(Vector2i(x, mapa.alto - 1))).is_false()
	for y in mapa.alto:
		assert_bool(mapa.es_transitable(Vector2i(0, y))).is_false()
		assert_bool(mapa.es_transitable(Vector2i(mapa.ancho - 1, y))).is_false()
	# Las dos salas están conectadas por la puerta del muro central.
	assert_bool(_hay_camino(mapa, Vector2i(1, 1), Vector2i(18, 12))).is_true()


func test_marcas_en_minuscula_son_suelo() -> void:
	var mapa := Mapa.desde_texto("#####\n#r.r#\n#####")
	assert_array(mapa.marcas["r"]).contains_exactly([Vector2i(1, 1), Vector2i(3, 1)])
	assert_bool(mapa.es_transitable(Vector2i(1, 1))).is_true()


func test_linea_de_vision() -> void:
	var mapa := Mapa.desde_texto(SALA) # columna en (2,2)
	assert_bool(mapa.linea_de_vision(Vector2i(1, 1), Vector2i(3, 1))).is_true()
	assert_bool(mapa.linea_de_vision(Vector2i(1, 2), Vector2i(3, 2))).is_false()
	assert_bool(mapa.linea_de_vision(Vector2i(1, 1), Vector2i(3, 3))).is_false()
	# Los extremos no cuentan: se puede "ver" un muro.
	assert_bool(mapa.linea_de_vision(Vector2i(1, 1), Vector2i(0, 1))).is_true()


func test_linea_incluye_extremos() -> void:
	assert_array(Mapa.linea(Vector2i(0, 0), Vector2i(3, 0))) \
		.is_equal([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)])
	assert_array(Mapa.linea(Vector2i(2, 2), Vector2i(0, 0))) \
		.is_equal([Vector2i(2, 2), Vector2i(1, 1), Vector2i(0, 0)])


func _hay_camino(mapa: Mapa, inicio: Vector2i, meta: Vector2i) -> bool:
	var visitadas := {inicio: true}
	var cola: Array[Vector2i] = [inicio]
	while not cola.is_empty():
		var actual: Vector2i = cola.pop_front()
		if actual == meta:
			return true
		for vecino in mapa.vecinos_alcanzables(actual):
			if not visitadas.has(vecino):
				visitadas[vecino] = true
				cola.append(vecino)
	return false
