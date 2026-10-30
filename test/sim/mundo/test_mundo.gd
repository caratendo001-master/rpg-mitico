extends GdUnitTestSuite
## Pruebas de ticks, alcance de ataques, ocupación, IA de la rata, muerte y equilibrio.

const ARENA := """
############
#..........#
#..........#
#..........#
#....#.....#
#..........#
############
"""

var _guerrero: FichaCriatura = load("res://data/criaturas/guerrero.tres")
var _rata: FichaCriatura = load("res://data/criaturas/rata_gigante.tres")
var _arco: FichaArma = load("res://data/armas/arco.tres")


func _mundo(semilla: int = 1) -> Mundo:
	return Mundo.new(Mapa.desde_texto(ARENA), semilla)


func _simular(m: Mundo, segundos: float) -> void:
	var dt := 1.0 / 30.0
	var t := 0.0
	while t < segundos:
		m.avanzar(dt)
		t += dt


func test_un_tick_por_segundo() -> void:
	var m := _mundo()
	_simular(m, 3.5)
	assert_int(m.tick_actual).is_equal(3)


func test_un_ataque_por_tick_cuerpo_a_cuerpo() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_guerrero, Vector2i(2, 2))
	var r := m.crear_enemigo(_rata, Vector2i(3, 3)) # vecina en diagonal
	r.combatiente.vida = 999
	var ataques := [0]
	m.ataque_resuelto.connect(func(a: Criatura, _d: Criatura, _res: Combate.Resultado) -> void:
		if a == j: ataques[0] += 1)
	j.atacar(r)
	for i in 4:
		m.tick()
	assert_int(ataques[0]).is_equal(4)


func test_cuerpo_a_cuerpo_necesita_estar_al_lado() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_guerrero, Vector2i(1, 1))
	var r := m.crear_enemigo(_rata, Vector2i(3, 1))
	assert_bool(m.puede_atacar(j, r)).is_false()
	j.arma = _arco
	assert_bool(m.puede_atacar(j, r)).is_true()


func test_a_distancia_necesita_linea_de_vista() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_guerrero, Vector2i(3, 4))
	var r := m.crear_enemigo(_rata, Vector2i(7, 4)) # el muro (5,4) está en medio
	j.arma = _arco
	assert_bool(m.puede_atacar(j, r)).is_false()
	r.personaje.teletransportar(Vector2i(7, 2))
	assert_bool(m.puede_atacar(j, r)).is_true()


func test_dos_criaturas_no_comparten_casilla() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_guerrero, Vector2i(1, 1))
	m.crear_enemigo(_rata, Vector2i(2, 1)).ia = null # quieta
	j.personaje.fijar_direccion(Vector2i(1, 0))
	_simular(m, 1.0)
	assert_that(j.casilla).is_equal(Vector2i(1, 1))


func test_jugador_persigue_y_ataca_al_objetivo() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_guerrero, Vector2i(1, 1))
	var r := m.crear_enemigo(_rata, Vector2i(8, 1))
	r.ia = null
	j.atacar(r)
	_simular(m, 6.0)
	assert_int(Mundo.distancia(j.casilla, r.casilla)).is_less_equal(1)
	assert_int(r.combatiente.vida).is_less(r.combatiente.vida_max)


func test_rata_patrulla_sin_alejarse_de_casa() -> void:
	var m := _mundo(3)
	m.crear_jugador(_guerrero, Vector2i(10, 5))
	var r := m.crear_enemigo(_rata, Vector2i(2, 1))
	r.ia.radio_vision = 0 # que no vea al jugador
	var se_movio := false
	for i in 20:
		_simular(m, 1.0)
		assert_int(Mundo.distancia(r.casilla, r.origen)).is_less_equal(r.ia.radio_patrulla)
		se_movio = se_movio or r.casilla != r.origen
	assert_bool(se_movio).is_true()
	assert_int(r.ia.estado).is_equal(IaCriatura.Estado.PATRULLAR)


func test_rata_ve_al_jugador_persigue_y_ataca() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_guerrero, Vector2i(2, 2))
	j.combatiente.vida = 999
	var r := m.crear_enemigo(_rata, Vector2i(6, 2)) # a 4 casillas, a la vista
	m.tick()
	assert_int(r.ia.estado).is_equal(IaCriatura.Estado.PERSEGUIR)
	assert_that(r.objetivo).is_same(j)
	_simular(m, 4.0)
	assert_int(r.ia.estado).is_equal(IaCriatura.Estado.ATACAR)
	assert_int(Mundo.distancia(r.casilla, j.casilla)).is_equal(1)


func test_rata_no_ve_a_traves_del_muro() -> void:
	var m := _mundo()
	m.crear_jugador(_guerrero, Vector2i(3, 4))
	var r := m.crear_enemigo(_rata, Vector2i(7, 4))
	r.ia.radio_patrulla = 0
	m.tick()
	assert_int(r.ia.estado).is_equal(IaCriatura.Estado.PATRULLAR)


func test_rata_regresa_si_se_aleja_demasiado() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_guerrero, Vector2i(10, 1))
	var r := m.crear_enemigo(_rata, Vector2i(1, 5))
	r.ia.radio_correa = 5
	r.atacar(j)
	r.ia.estado = IaCriatura.Estado.PERSEGUIR
	r.personaje.teletransportar(Vector2i(10, 3)) # lejos de su origen
	r.combatiente.vida = 3
	m.tick()
	assert_int(r.ia.estado).is_equal(IaCriatura.Estado.REGRESAR)
	assert_object(r.objetivo).is_null()
	_simular(m, 3.0) # 9 casillas a 3 por segundo
	assert_int(Mundo.distancia(r.casilla, r.origen)).is_less_equal(1)
	assert_int(r.ia.estado).is_equal(IaCriatura.Estado.PATRULLAR) # llegó y vuelve a patrullar
	assert_int(r.combatiente.vida).is_equal(r.combatiente.vida_max)


func test_jugador_muere_y_reaparece_en_el_inicio() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_guerrero, Vector2i(2, 2))
	j.personaje.teletransportar(Vector2i(9, 5))
	j.combatiente.recibir_dano(999)
	assert_bool(j.esta_vivo()).is_false()
	for i in Mundo.TICKS_REAPARECER_JUGADOR - 1:
		m.tick()
	assert_bool(j.esta_vivo()).is_false()
	m.tick()
	assert_bool(j.esta_vivo()).is_true()
	assert_that(j.casilla).is_equal(Vector2i(2, 2))
	assert_int(j.combatiente.vida).is_equal(j.combatiente.vida_max)


func test_enemigo_muerto_no_ocupa_su_casilla_y_reaparece() -> void:
	var m := _mundo()
	m.crear_jugador(_guerrero, Vector2i(10, 5))
	var r := m.crear_enemigo(_rata, Vector2i(2, 2))
	r.combatiente.recibir_dano(999)
	assert_bool(m.esta_ocupada(Vector2i(2, 2))).is_false()
	for i in Mundo.TICKS_REAPARECER_ENEMIGO:
		m.tick()
	assert_bool(r.esta_vivo()).is_true()


func test_mapa_de_prueba_tiene_tres_ratas() -> void:
	var m := Mundo.new(Mapa.desde_archivo("res://data/mapas/prueba.txt"))
	m.crear_jugador(_guerrero)
	assert_int(m.poblar("r", _rata).size()).is_equal(3)


## Criterio de la Fase 2: pelear contra 3 ratas debe ser justo. El guerrero debe ganar
## casi siempre, pero recibiendo daño de verdad (no un paseo).
func test_equilibrio_guerrero_contra_tres_ratas() -> void:
	var victorias := 0
	var vida_perdida_total := 0
	var peleas := 60
	for semilla in range(1, peleas + 1):
		var m := _mundo(semilla)
		var j := m.crear_jugador(_guerrero, Vector2i(5, 2))
		var ratas: Array[Criatura] = []
		for c in [Vector2i(2, 5), Vector2i(8, 5), Vector2i(9, 1)]:
			ratas.append(m.crear_enemigo(_rata, c))
		var t := 0.0
		while t < 90.0 and j.esta_vivo() and ratas.any(func(r: Criatura) -> bool: return r.esta_vivo()):
			if j.objetivo == null:
				for r in ratas:
					if r.esta_vivo():
						j.atacar(r)
						break
			m.avanzar(0.1)
			t += 0.1
		if j.esta_vivo():
			victorias += 1
			vida_perdida_total += j.combatiente.vida_max - j.combatiente.vida
	var tasa := float(victorias) / peleas
	var vida_perdida_media := float(vida_perdida_total) / maxi(1, victorias)
	print("Guerrero vs 3 ratas: %d%% victorias, vida perdida media %.1f" % [tasa * 100, vida_perdida_media])
	assert_float(tasa).is_between(0.75, 0.99)
	assert_float(vida_perdida_media).is_greater_equal(10.0)
