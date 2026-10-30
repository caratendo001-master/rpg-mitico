extends GdUnitTestSuite
## Pruebas de habilidades: maná, enfriamientos, alcance, áreas, curación, provocación y equilibrio del Mago.

const R := Mundo.ResultadoHabilidad

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
var _mago: FichaCriatura = load("res://data/criaturas/mago.tres")
var _rata: FichaCriatura = load("res://data/criaturas/rata_gigante.tres")


func _mundo(semilla: int = 1) -> Mundo:
	return Mundo.new(Mapa.desde_texto(ARENA), semilla)


func _rata_quieta(m: Mundo, en: Vector2i, vida: int = 999) -> Criatura:
	var r := m.crear_enemigo(_rata, en)
	r.ia = null
	r.combatiente.vida = vida
	return r


func test_cada_clase_tiene_tres_habilidades() -> void:
	assert_int(_guerrero.habilidades.size()).is_equal(3)
	assert_int(_mago.habilidades.size()).is_equal(3)


func test_valores_del_mago() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_mago, Vector2i(1, 1))
	assert_int(j.combatiente.vida_max).is_equal(22) # 20 + 2·(+1 con)
	assert_int(j.combatiente.mana_max).is_equal(22) # 16 + 2·(+3 int, 17 con el báculo)
	assert_int(j.combatiente.defensa).is_equal(12) # 10 + 2 (des 14)
	assert_str(j.arma.nombre).is_equal("Báculo")


func test_proyectil_magico_gasta_mana_y_siempre_impacta() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_mago, Vector2i(1, 1))
	var r := _rata_quieta(m, Vector2i(6, 1))
	assert_int(m.usar_habilidad(j, 0, r)).is_equal(R.OK)
	assert_int(j.combatiente.mana).is_equal(j.combatiente.mana_max - j.habilidades[0].costo_mana)
	var dano := 999 - r.combatiente.vida
	assert_int(dano).is_between(4, 9) # 1d6 + 3


func test_enfriamiento_global_y_propio() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_mago, Vector2i(1, 1))
	var r := _rata_quieta(m, Vector2i(4, 1))
	assert_int(m.usar_habilidad(j, 0, r)).is_equal(R.OK)
	assert_int(m.usar_habilidad(j, 0, r)).is_equal(R.ENFRIANDO) # global de 1 s
	assert_int(m.usar_habilidad(j, 1, r)).is_equal(R.ENFRIANDO)
	m.avanzar(1.0)
	assert_int(m.usar_habilidad(j, 1, r)).is_equal(R.OK) # bola de fuego
	m.avanzar(1.0)
	assert_int(m.usar_habilidad(j, 1, r)).is_equal(R.ENFRIANDO) # tiene su propio enfriamiento
	assert_float(j.enfriamiento_de(j.habilidades[1])).is_equal_approx(j.habilidades[1].enfriamiento - 1.0, 0.01)


func test_sin_mana_no_lanza() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_mago, Vector2i(1, 1))
	var r := _rata_quieta(m, Vector2i(3, 1))
	j.combatiente.mana = j.habilidades[0].costo_mana - 1
	assert_int(m.usar_habilidad(j, 0, r)).is_equal(R.SIN_MANA)
	assert_int(r.combatiente.vida).is_equal(999)


func test_alcance_y_linea_de_vista() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_mago, Vector2i(1, 1))
	var lejos := _rata_quieta(m, Vector2i(9, 1))
	assert_int(m.usar_habilidad(j, 0, lejos)).is_equal(R.FUERA_DE_ALCANCE)
	j.personaje.teletransportar(Vector2i(3, 4))
	var tras_muro := _rata_quieta(m, Vector2i(7, 4)) # el muro (5,4) en medio
	assert_int(m.usar_habilidad(j, 0, tras_muro)).is_equal(R.SIN_VISTA)


func test_sin_objetivo() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_mago, Vector2i(1, 1))
	assert_int(m.usar_habilidad(j, 0)).is_equal(R.SIN_OBJETIVO)


func test_bola_de_fuego_quema_al_objetivo_y_a_su_lado() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_mago, Vector2i(1, 1))
	var centro := _rata_quieta(m, Vector2i(5, 2))
	var vecina := _rata_quieta(m, Vector2i(6, 3))
	var lejana := _rata_quieta(m, Vector2i(8, 2))
	assert_int(m.usar_habilidad(j, 1, centro)).is_equal(R.OK)
	assert_int(centro.combatiente.vida).is_less(999)
	assert_int(vecina.combatiente.vida).is_less(999)
	assert_int(lejana.combatiente.vida).is_equal(999)


func test_torbellino_golpea_a_todos_los_vecinos() -> void:
	var m := _mundo(5)
	var j := m.crear_jugador(_guerrero, Vector2i(4, 2))
	var ratas: Array[Criatura] = [_rata_quieta(m, Vector2i(3, 1)), _rata_quieta(m, Vector2i(5, 3)), _rata_quieta(m, Vector2i(4, 3))]
	var lejana := _rata_quieta(m, Vector2i(8, 2))
	var golpes := [0]
	m.ataque_resuelto.connect(func(_a: Criatura, _d: Criatura, res: Combate.Resultado) -> void:
		if res.habilidad: golpes[0] += 1)
	assert_int(m.usar_habilidad(j, 1)).is_equal(R.OK)
	assert_int(golpes[0]).is_equal(3) # una tirada por rata vecina (pueden fallar)
	assert_int(lejana.combatiente.vida).is_equal(999)


func test_torbellino_sin_nadie_cerca_no_gasta_mana() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_guerrero, Vector2i(4, 2))
	assert_int(m.usar_habilidad(j, 1)).is_equal(R.SIN_OBJETIVO)
	assert_int(j.combatiente.mana).is_equal(j.combatiente.mana_max)


func test_golpe_poderoso_hace_mas_dano_que_un_ataque_normal() -> void:
	var golpe := 0
	var normal := 0
	for semilla in range(1, 41):
		var m := _mundo(semilla)
		var j := m.crear_jugador(_guerrero, Vector2i(2, 2))
		var r := _rata_quieta(m, Vector2i(3, 2))
		m.usar_habilidad(j, 0, r)
		golpe += 999 - r.combatiente.vida
		var m2 := _mundo(semilla)
		var j2 := m2.crear_jugador(_guerrero, Vector2i(2, 2))
		var r2 := _rata_quieta(m2, Vector2i(3, 2))
		Combate.resolver(j2.combatiente, j2.arma, r2.combatiente, m2.dados)
		normal += 999 - r2.combatiente.vida
	assert_int(golpe).is_greater(normal + 100)


func test_curacion_propia() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_guerrero, Vector2i(2, 2))
	j.combatiente.recibir_dano(20)
	assert_int(m.usar_habilidad(j, 2)).is_equal(R.OK)
	var curado := j.combatiente.vida - (j.combatiente.vida_max - 20)
	assert_int(curado).is_between(4, 14) # 2d6 + 2


func test_atacar_desde_lejos_provoca_a_la_rata() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_mago, Vector2i(1, 1))
	var r := m.crear_enemigo(_rata, Vector2i(7, 1)) # a 6: fuera de su vista (5)
	r.combatiente.vida = 999
	assert_int(r.ia.estado).is_equal(IaCriatura.Estado.PATRULLAR)
	m.usar_habilidad(j, 0, r)
	assert_int(r.ia.estado).is_equal(IaCriatura.Estado.PERSEGUIR)
	assert_that(r.objetivo).is_same(j)


## Con sus habilidades, cada clase debe ganarle a 3 ratas casi siempre, pero perdiendo
## una parte real de su vida (que la pelea sea peligrosa, no un paseo).
func test_equilibrio_mago_contra_tres_ratas() -> void:
	var stats := _pelear_contra_tres_ratas(_mago, _jugar_como_mago)
	print("Mago (con hechizos) vs 3 ratas: %d%% victorias, vida perdida media %d%%" % [stats.x * 100, stats.y * 100])
	assert_float(stats.x).is_between(0.7, 0.95) # clase frágil: más riesgo que el guerrero
	assert_float(stats.y).is_greater_equal(0.25)


func test_equilibrio_guerrero_con_habilidades_contra_tres_ratas() -> void:
	var stats := _pelear_contra_tres_ratas(_guerrero, _jugar_como_guerrero)
	print("Guerrero (con habilidades) vs 3 ratas: %d%% victorias, vida perdida media %d%%" % [stats.x * 100, stats.y * 100])
	assert_float(stats.x).is_between(0.75, 0.99)
	assert_float(stats.y).is_greater_equal(0.25)


## Devuelve (fracción de victorias, fracción media de vida perdida en las victorias).
func _pelear_contra_tres_ratas(ficha: FichaCriatura, estrategia: Callable) -> Vector2:
	var victorias := 0
	var perdida := 0.0
	var peleas := 60
	for semilla in range(1, peleas + 1):
		var m := _mundo(semilla)
		var j := m.crear_jugador(ficha, Vector2i(5, 2))
		var ratas: Array[Criatura] = []
		for c in [Vector2i(2, 5), Vector2i(8, 5), Vector2i(9, 1)]:
			ratas.append(m.crear_enemigo(_rata, c))
		var t := 0.0
		while t < 120.0 and j.esta_vivo() and ratas.any(func(r: Criatura) -> bool: return r.esta_vivo()):
			estrategia.call(m, j, ratas)
			m.avanzar(0.1)
			t += 0.1
		if j.esta_vivo():
			victorias += 1
			perdida += 1.0 - float(j.combatiente.vida) / j.combatiente.vida_max
	return Vector2(float(victorias) / peleas, perdida / maxi(1, victorias))


func _rata_mas_cercana(j: Criatura, ratas: Array[Criatura]) -> Criatura:
	var cercana: Criatura = null
	for r in ratas:
		if r.esta_vivo() and (cercana == null or Mundo.distancia(j.casilla, r.casilla) < Mundo.distancia(j.casilla, cercana.casilla)):
			cercana = r
	return cercana


## Curarse si está bajo; torbellino si hay 2+ al lado; golpe poderoso al objetivo.
func _jugar_como_guerrero(m: Mundo, j: Criatura, ratas: Array[Criatura]) -> void:
	if j.combatiente.vida < 15 and m.usar_habilidad(j, 2) == R.OK:
		return
	var cercana := _rata_mas_cercana(j, ratas)
	if cercana == null:
		return
	if j.objetivo == null:
		j.atacar(cercana)
	var vecinas := ratas.filter(func(r: Criatura) -> bool: return r.esta_vivo() and Mundo.distancia(j.casilla, r.casilla) <= 1)
	if vecinas.size() >= 2 and m.usar_habilidad(j, 1) == R.OK:
		return
	m.usar_habilidad(j, 0, j.objetivo)


## Estrategia simple: curarse si está bajo, bola de fuego si hay varias juntas, si no proyectil.
func _jugar_como_mago(m: Mundo, j: Criatura, ratas: Array[Criatura]) -> void:
	if j.combatiente.vida < 10 and m.usar_habilidad(j, 2) == R.OK:
		return
	var cercana := _rata_mas_cercana(j, ratas)
	if cercana == null:
		return
	if j.objetivo == null:
		j.atacar(cercana)
	if m.usar_habilidad(j, 1, cercana) == R.OK:
		return
	m.usar_habilidad(j, 0, cercana)
