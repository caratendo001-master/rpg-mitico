extends GdUnitTestSuite
## Pruebas de experiencia, niveles, puntos de atributo y penalización por muerte.

const A := Combatiente.Atributo

var _ficha_guerrero: FichaCriatura = load("res://data/criaturas/guerrero.tres")


func _guerrero() -> Combatiente:
	return Combatiente.new(_ficha_guerrero)


func test_curva_de_experiencia() -> void:
	assert_int(Combatiente.experiencia_para_nivel(1)).is_equal(0)
	assert_int(Combatiente.experiencia_para_nivel(2)).is_equal(100)
	assert_int(Combatiente.experiencia_para_nivel(3)).is_equal(300)
	assert_int(Combatiente.experiencia_para_nivel(4)).is_equal(600)


func test_subir_de_nivel_mejora_y_cura() -> void:
	var g := _guerrero()
	var niveles: Array[int] = []
	g.subio_nivel.connect(func(n: int) -> void: niveles.append(n))
	g.recibir_dano(20)
	g.ganar_experiencia(99)
	assert_int(g.nivel).is_equal(1)
	g.ganar_experiencia(1)
	assert_int(g.nivel).is_equal(2)
	assert_array(niveles).is_equal([2])
	assert_int(g.puntos_atributo).is_equal(2)
	assert_int(g.vida_max).is_equal(40) # 34 + 6
	assert_int(g.vida).is_equal(40) # curado al subir
	assert_int(g.mana_max).is_equal(10) # 8 + 2


func test_varios_niveles_de_golpe() -> void:
	var g := _guerrero()
	g.ganar_experiencia(650)
	assert_int(g.nivel).is_equal(4)
	assert_int(g.puntos_atributo).is_equal(6)


func test_progreso_hacia_el_siguiente_nivel() -> void:
	var g := _guerrero()
	g.ganar_experiencia(150) # nivel 2: de 100 a 300
	assert_float(g.progreso_nivel()).is_equal_approx(0.25, 0.001)


func test_asignar_puntos_cambia_los_valores_derivados() -> void:
	var g := _guerrero()
	g.ganar_experiencia(100)
	var vida_antes := g.vida_max
	assert_bool(g.asignar_punto(A.CONSTITUCION)).is_true() # 14 → 15: mismo modificador
	assert_int(g.vida_max).is_equal(vida_antes)
	assert_bool(g.asignar_punto(A.CONSTITUCION)).is_true() # 16: +1 de modificador → +2 vida
	assert_int(g.vida_max).is_equal(vida_antes + 2)
	assert_int(g.vida).is_equal(g.vida_max)
	assert_bool(g.asignar_punto(A.FUERZA)).is_false() # ya no hay puntos
	assert_int(g.atributo(A.CONSTITUCION)).is_equal(16)


func test_subir_atributo_no_cambia_la_ficha_compartida() -> void:
	var g := _guerrero()
	g.ganar_experiencia(100)
	g.asignar_punto(A.FUERZA)
	assert_int(g.atributo(A.FUERZA)).is_equal(15)
	assert_int(_ficha_guerrero.fuerza).is_equal(14)
	assert_int(_guerrero().atributo(A.FUERZA)).is_equal(14)


func test_la_fuerza_mejora_el_ataque_con_espada() -> void:
	var g := _guerrero()
	var espada: FichaArma = load("res://data/armas/espada.tres")
	assert_int(g.bonus_ataque(espada)).is_equal(2)
	g.fijar_atributo(A.FUERZA, 16)
	assert_int(g.bonus_ataque(espada)).is_equal(3)


func test_morir_quita_experiencia_sin_bajar_de_nivel() -> void:
	var g := _guerrero()
	g.ganar_experiencia(250) # nivel 2 (100..300)
	g.recibir_dano(999)
	assert_int(g.experiencia).is_equal(230) # pierde 10% de 200
	assert_int(g.nivel).is_equal(2)
	var h := _guerrero()
	h.ganar_experiencia(105)
	h.recibir_dano(999)
	assert_int(h.experiencia).is_equal(100) # no baja del mínimo del nivel


func test_matar_una_rata_da_experiencia_al_jugador() -> void:
	var m := Mundo.new(Mapa.desde_texto("#####\n#...#\n#####"), 1)
	var j := m.crear_jugador(_ficha_guerrero, Vector2i(1, 1))
	var r := m.crear_enemigo(load("res://data/criaturas/rata_gigante.tres"), Vector2i(2, 1))
	r.ia = null
	r.combatiente.vida = 1
	j.atacar(r)
	for i in 30:
		if not r.esta_vivo():
			break
		m.tick()
	assert_bool(r.esta_vivo()).is_false()
	assert_int(j.combatiente.experiencia).is_equal(25)
