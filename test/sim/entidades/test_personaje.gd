extends GdUnitTestSuite
## Pruebas del movimiento por casillas del personaje.

const SALA := """
#######
#.....#
#.O...#
#.....#
#######
"""

var _mapa: Mapa
var _buscador: BuscadorCamino


func before_test() -> void:
	_mapa = Mapa.desde_texto(SALA)
	_buscador = BuscadorCamino.new(_mapa)


func _crear(en: Vector2i) -> Personaje:
	var p := Personaje.new(_mapa, _buscador, en)
	p.velocidad = 4.0
	return p


## Avanza en pasos pequeños comprobando que nunca pisa algo bloqueado.
func _simular(p: Personaje, segundos: float) -> void:
	var dt := 1.0 / 60.0
	var t := 0.0
	while t < segundos:
		p.avanzar(dt)
		assert_bool(_mapa.es_transitable(p.casilla)).is_true()
		t += dt


func test_clic_lleva_hasta_el_destino() -> void:
	var p := _crear(Vector2i(1, 1))
	assert_bool(p.ir_a(Vector2i(5, 3))).is_true()
	_simular(p, 3.0)
	assert_that(p.casilla).is_equal(Vector2i(5, 3))
	assert_bool(p.esta_caminando()).is_false()


func test_clic_en_columna_se_queda_al_lado() -> void:
	var p := _crear(Vector2i(5, 1))
	assert_bool(p.ir_a(Vector2i(2, 2))).is_true()
	_simular(p, 3.0)
	assert_that(p.casilla).is_not_equal(Vector2i(2, 2))
	assert_int(maxi(absi(p.casilla.x - 2), absi(p.casilla.y - 2))).is_equal(1)


func test_un_paso_recto_dura_un_cuarto_de_segundo() -> void:
	var p := _crear(Vector2i(3, 1))
	p.fijar_direccion(Vector2i(1, 0))
	p.avanzar(0.01)
	p.fijar_direccion(Vector2i.ZERO)
	assert_that(p.casilla).is_equal(Vector2i(4, 1)) # ocupa el destino desde que empieza
	assert_that(p.paso_desde).is_equal(Vector2i(3, 1))
	assert_bool(p.esta_caminando()).is_true()
	p.avanzar(0.23)
	assert_bool(p.esta_caminando()).is_true()
	p.avanzar(0.02)
	assert_bool(p.esta_caminando()).is_false()
	assert_float(p.fraccion_paso()).is_equal(1.0)


func test_el_paso_diagonal_tarda_mas() -> void:
	var p := _crear(Vector2i(3, 1))
	p.fijar_direccion(Vector2i(1, 1))
	p.avanzar(0.01)
	p.fijar_direccion(Vector2i.ZERO)
	p.avanzar(0.3) # 0.31 s: un paso recto ya habría terminado, el diagonal (~0.354 s) no
	assert_bool(p.esta_caminando()).is_true()
	p.avanzar(0.05)
	assert_bool(p.esta_caminando()).is_false()
	assert_that(p.casilla).is_equal(Vector2i(4, 2))


func test_fraccion_de_paso_avanza() -> void:
	var p := _crear(Vector2i(3, 1))
	p.fijar_direccion(Vector2i(1, 0))
	p.avanzar(0.125)
	assert_float(p.fraccion_paso()).is_equal_approx(0.5, 0.01)


func test_teclado_contra_el_muro_no_se_mueve() -> void:
	var p := _crear(Vector2i(1, 1))
	p.fijar_direccion(Vector2i(0, -1))
	_simular(p, 1.0)
	assert_that(p.casilla).is_equal(Vector2i(1, 1))


func test_teclado_no_atraviesa_la_columna() -> void:
	var p := _crear(Vector2i(2, 1))
	p.fijar_direccion(Vector2i(0, 1)) # la columna está justo debajo
	_simular(p, 1.0)
	assert_that(p.casilla).is_equal(Vector2i(2, 1))


func test_teclado_se_desliza_por_el_muro_en_diagonal() -> void:
	var p := _crear(Vector2i(3, 1))
	p.fijar_direccion(Vector2i(1, -1)) # arriba está el muro: debe deslizarse a la derecha
	_simular(p, 0.26)
	assert_that(p.casilla.y).is_equal(1)
	assert_int(p.casilla.x).is_greater(3)


func test_teclado_cancela_la_ruta_del_clic() -> void:
	var p := _crear(Vector2i(1, 1))
	p.ir_a(Vector2i(5, 3))
	p.fijar_direccion(Vector2i(0, 1))
	assert_array(p.ruta_pendiente()).is_empty()
	_simular(p, 1.0)
	assert_that(p.casilla.x).is_equal(1)


func test_aparece_en_el_inicio_del_mapa_de_prueba() -> void:
	var mapa := Mapa.desde_archivo("res://data/mapas/prueba.txt")
	assert_that(mapa.inicio).is_equal(Vector2i(3, 2))
	assert_bool(mapa.es_transitable(mapa.inicio)).is_true()
