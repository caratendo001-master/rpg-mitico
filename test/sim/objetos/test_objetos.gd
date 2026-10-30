extends GdUnitTestSuite
## Pruebas de inventario, equipo, consumibles, botín y objetos en el suelo.

const A := Combatiente.Atributo


class DadosFijos extends Dados:
	var valores: Array[int] = []

	func tirar(_caras: int) -> int:
		return valores.pop_front()


var _guerrero: FichaCriatura = load("res://data/criaturas/guerrero.tres")
var _rata: FichaCriatura = load("res://data/criaturas/rata_gigante.tres")
var _pocion: FichaObjeto = load("res://data/objetos/pocion_vida.tres")
var _oro: FichaObjeto = load("res://data/objetos/moneda_oro.tres")
var _casco: FichaObjeto = load("res://data/objetos/casco_cuero.tres")
var _armadura: FichaObjeto = load("res://data/objetos/armadura_cuero.tres")
var _guantes: FichaObjeto = load("res://data/objetos/guantes_cuero.tres")
var _anillo: FichaObjeto = load("res://data/objetos/anillo_vigor.tres")
var _espada: FichaObjeto = load("res://data/objetos/espada_corta.tres")
var _arco: FichaObjeto = load("res://data/objetos/arco_corto.tres")


func _mundo() -> Mundo:
	return Mundo.new(Mapa.desde_texto("#######\n#.....#\n#.....#\n#######"), 1)


# --- Inventario ---

func test_apila_hasta_el_maximo() -> void:
	var inv := Inventario.new()
	assert_int(inv.agregar(_pocion, 13)).is_equal(0)
	assert_int(inv.casillas[0].cantidad).is_equal(10)
	assert_int(inv.casillas[1].cantidad).is_equal(3)
	assert_int(inv.cantidad_de(_pocion)).is_equal(13)


func test_no_cabe_por_espacio() -> void:
	var inv := Inventario.new(2)
	assert_int(inv.agregar(_casco, 3)).is_equal(1)
	assert_int(inv.cantidad_de(_casco)).is_equal(2)


func test_no_cabe_por_peso() -> void:
	var inv := Inventario.new()
	inv.peso_maximo = 10.0
	assert_int(inv.agregar(_armadura, 2)).is_equal(1) # 6 + 6 > 10
	assert_float(inv.peso_total()).is_equal_approx(6.0, 0.001)


func test_quitar_y_mover() -> void:
	var inv := Inventario.new()
	inv.agregar(_pocion, 4)
	var sacado := inv.quitar(0, 3)
	assert_int(sacado.cantidad).is_equal(3)
	assert_int(inv.casillas[0].cantidad).is_equal(1)
	inv.mover(0, 5)
	assert_object(inv.casillas[0]).is_null()
	assert_int(inv.casillas[5].cantidad).is_equal(1)


func test_la_carga_crece_con_la_fuerza() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_guerrero, Vector2i(1, 1))
	assert_float(j.carga_maxima()).is_equal_approx(96.0, 0.001) # 40 + 4·14
	j.combatiente.fijar_atributo(A.FUERZA, 16)
	assert_float(j.inventario.carga_maxima()).is_equal_approx(104.0, 0.001)


# --- Equipo ---

func test_equipo_inicial_del_guerrero() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_guerrero, Vector2i(1, 1))
	assert_object(j.equipo.en(FichaObjeto.Ranura.ARMA)).is_same(_espada)
	assert_str(j.arma.nombre).is_equal("Espada")
	assert_int(j.inventario.cantidad_de(_arco)).is_equal(1)
	assert_int(j.inventario.cantidad_de(_pocion)).is_equal(2)


func test_equipar_arco_devuelve_la_espada_y_cambia_el_ataque() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_guerrero, Vector2i(1, 1))
	var indice := j.inventario.buscar(func(o: FichaObjeto) -> bool: return o == _arco)
	assert_bool(j.usar(indice)).is_true()
	assert_int(j.arma.alcance).is_equal(5)
	assert_int(j.inventario.cantidad_de(_espada)).is_equal(1)
	assert_int(j.inventario.cantidad_de(_arco)).is_equal(0)


func test_sin_arma_pelea_con_los_punos() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_guerrero, Vector2i(1, 1))
	assert_bool(j.equipo.desequipar(FichaObjeto.Ranura.ARMA, j.inventario)).is_true()
	assert_str(j.arma.nombre).is_equal("Puños")


func test_armadura_sube_la_defensa() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_guerrero, Vector2i(1, 1))
	var antes := j.combatiente.defensa
	j.inventario.agregar(_casco)
	j.inventario.agregar(_armadura)
	j.usar(j.inventario.buscar(func(o: FichaObjeto) -> bool: return o == _casco))
	j.usar(j.inventario.buscar(func(o: FichaObjeto) -> bool: return o == _armadura))
	assert_int(j.combatiente.defensa).is_equal(antes + 3)


func test_bonus_de_atributos_del_equipo() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_guerrero, Vector2i(1, 1))
	var vida_antes := j.combatiente.vida_max
	j.inventario.agregar(_anillo) # constitución +2 → +1 de modificador → +2 vida
	j.inventario.agregar(_guantes) # fuerza +1 (15: mismo modificador)
	j.usar(j.inventario.buscar(func(o: FichaObjeto) -> bool: return o == _anillo))
	j.usar(j.inventario.buscar(func(o: FichaObjeto) -> bool: return o == _guantes))
	assert_int(j.combatiente.vida_max).is_equal(vida_antes + 2)
	assert_int(j.combatiente.atributo(A.FUERZA)).is_equal(15)
	assert_int(j.combatiente.atributo_base(A.FUERZA)).is_equal(14)
	# Al quitarse el anillo, la vida actual no puede quedar por encima del máximo.
	j.combatiente.restaurar()
	j.equipo.desequipar(FichaObjeto.Ranura.ANILLO, j.inventario)
	assert_int(j.combatiente.vida).is_equal(vida_antes)


func test_pocion_cura_y_se_gasta() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_guerrero, Vector2i(1, 1))
	j.combatiente.recibir_dano(20)
	var indice := j.inventario.buscar(func(o: FichaObjeto) -> bool: return o.es_consumible())
	assert_bool(j.usar(indice)).is_true()
	assert_int(j.combatiente.vida).is_equal(j.combatiente.vida_max - 5)
	assert_int(j.inventario.cantidad_de(_pocion)).is_equal(1)


# --- Botín y suelo ---

func test_tabla_de_botin_respeta_probabilidades() -> void:
	var tabla := TablaBotin.new()
	var seguro := EntradaBotin.new()
	seguro.objeto = _oro
	seguro.probabilidad = 1.0
	seguro.cantidad_min = 2
	seguro.cantidad_max = 5
	var raro := EntradaBotin.new()
	raro.objeto = _anillo
	raro.probabilidad = 0.02
	tabla.entradas = [seguro, raro]
	var dados := DadosFijos.new()
	dados.valores = [1000, 3, 21] # oro sale (1000 ≤ 1000) con 2+3-1 = 4; anillo no (21 > 20)
	var botin := tabla.tirar(dados)
	assert_int(botin.size()).is_equal(1)
	assert_object(botin[0].objeto).is_same(_oro)
	assert_int(botin[0].cantidad).is_equal(4)


func test_la_rata_suelta_botin_al_morir() -> void:
	var m := _mundo()
	m.crear_jugador(_guerrero, Vector2i(5, 2))
	var total := 0
	for i in 20:
		var r := m.crear_enemigo(_rata, Vector2i(1 + i % 4, 1))
		r.ia = null
		r.combatiente.recibir_dano(999)
		total = m.objetos_suelo.size()
	assert_int(total).is_greater(10) # 60% cola + 80% oro por rata: casi seguro más de 10 en 20 ratas


func test_pisar_objetos_los_recoge() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_guerrero, Vector2i(1, 1))
	m.soltar_en(Vector2i(3, 1), Pila.new(_oro, 7))
	var recogidos := [0]
	m.objeto_recogido.connect(func(_c: Criatura, _o: FichaObjeto, n: int) -> void: recogidos[0] += n)
	j.personaje.ir_a(Vector2i(3, 1))
	for i in 30:
		m.avanzar(0.05)
	assert_int(j.inventario.cantidad_de(_oro)).is_equal(7)
	assert_int(recogidos[0]).is_equal(7)
	assert_array(m.objetos_suelo).is_empty()


func test_lo_que_no_cabe_se_queda_en_el_suelo() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_guerrero, Vector2i(1, 1))
	j.inventario.limite_peso = Callable()
	j.inventario.peso_maximo = j.inventario.peso_total() + 6.5
	m.soltar_en(Vector2i(1, 1), Pila.new(_armadura, 2))
	m.avanzar(0.05)
	assert_int(j.inventario.cantidad_de(_armadura)).is_equal(1)
	assert_int(m.objetos_en(Vector2i(1, 1))[0].pila.cantidad).is_equal(1)


func test_tirar_un_objeto_no_lo_recoge_de_inmediato() -> void:
	var m := _mundo()
	var j := m.crear_jugador(_guerrero, Vector2i(1, 1))
	var indice := j.inventario.buscar(func(o: FichaObjeto) -> bool: return o == _arco)
	m.tirar_del_inventario(j, indice)
	m.avanzar(0.1)
	assert_int(j.inventario.cantidad_de(_arco)).is_equal(0)
	assert_int(m.objetos_en(Vector2i(1, 1)).size()).is_equal(1)


func test_los_objetos_desaparecen_con_el_tiempo() -> void:
	var m := _mundo()
	m.crear_jugador(_guerrero, Vector2i(1, 1))
	m.soltar_en(Vector2i(4, 2), Pila.new(_oro, 1))
	for i in Mundo.TICKS_OBJETO_EN_SUELO:
		m.tick()
	assert_array(m.objetos_suelo).is_empty()
