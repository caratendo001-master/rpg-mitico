extends GdUnitTestSuite
## Prueba de ejemplo de la simulación: solo usa clases de sim/, sin escenas.


func test_d20_siempre_entre_1_y_20() -> void:
	var dados := Dados.new(1234)
	for i in 1000:
		assert_int(dados.d20()).is_between(1, 20)


func test_misma_semilla_mismas_tiradas() -> void:
	var a := Dados.new(42)
	var b := Dados.new(42)
	for i in 50:
		assert_int(a.d20()).is_equal(b.d20())


func test_defensa_imposible_solo_impacta_con_20_natural() -> void:
	var dados := Dados.new(7)
	var impactos := 0
	for i in 2000:
		if dados.tirada_impacto(0, 99):
			impactos += 1
	# ~5% de las tiradas son 20 natural; aceptamos un margen amplio.
	assert_int(impactos).is_between(40, 170)


func test_defensa_minima_falla_solo_con_1_natural() -> void:
	var dados := Dados.new(7)
	var fallos := 0
	for i in 2000:
		if not dados.tirada_impacto(0, -99):
			fallos += 1
	assert_int(fallos).is_between(40, 170)
