extends Node2D
## Escena de prueba: mapa, jugador y ratas. Traduce la entrada a acciones de la simulación
## (`Mundo`) y la hace avanzar en el bucle de física; las vistas solo dibujan su estado.

const NOMBRES_TIPO := {
	Mapa.Tipo.VACIO: "vacío",
	Mapa.Tipo.SUELO: "suelo",
	Mapa.Tipo.MURO: "muro",
	Mapa.Tipo.COLUMNA: "columna",
}

## Teclas de movimiento: WASD y flechas, en direcciones de pantalla.
const TECLAS_DIRECCION := {
	KEY_W: Vector2i(0, -1), KEY_UP: Vector2i(0, -1),
	KEY_S: Vector2i(0, 1), KEY_DOWN: Vector2i(0, 1),
	KEY_A: Vector2i(-1, 0), KEY_LEFT: Vector2i(-1, 0),
	KEY_D: Vector2i(1, 0), KEY_RIGHT: Vector2i(1, 0),
}

## Clases que se pueden elegir al empezar.
const CLASES: Array[FichaCriatura] = [
	preload("res://data/criaturas/guerrero.tres"),
	preload("res://data/criaturas/mago.tres"),
]
const FICHA_RATA := preload("res://data/criaturas/rata_gigante.tres")

const MENSAJES_HABILIDAD := {
	Mundo.ResultadoHabilidad.SIN_MANA: "Sin maná",
	Mundo.ResultadoHabilidad.ENFRIANDO: "Aún no",
	Mundo.ResultadoHabilidad.SIN_OBJETIVO: "Sin objetivo",
	Mundo.ResultadoHabilidad.FUERA_DE_ALCANCE: "Muy lejos",
	Mundo.ResultadoHabilidad.SIN_VISTA: "No lo ves",
}

var mundo: Mundo
var jugador: Criatura

var _vistas := {} # Criatura -> CriaturaVista
var _vistas_objetos := {} # Mundo.ObjetoSuelo -> ObjetoSueloVista

@onready var _mapa_vista: MapaVista = $MapaVista
@onready var _info: Label = $Interfaz/Info
@onready var _hud: Hud = $Interfaz/Hud

# Se crean al elegir clase (antes no hay jugador que mostrar).
var _panel: PanelPersonaje
var _inventario: PanelInventario
var _barra: BarraHabilidades
var _selector := SelectorClase.new()


func _ready() -> void:
	mundo = Mundo.new(_mapa_vista.mapa)
	mundo.criatura_agregada.connect(_crear_vista)
	mundo.ataque_resuelto.connect(_al_resolver_ataque)
	mundo.habilidad_usada.connect(_al_usar_habilidad)
	mundo.objeto_en_suelo.connect(_al_aparecer_objeto)
	mundo.objeto_retirado.connect(_al_retirar_objeto)
	mundo.objeto_recogido.connect(_al_recoger_objeto)
	mundo.poblar("r", FICHA_RATA)
	_mapa_vista.casilla_senalada.connect(_al_senalar_casilla)
	# El mundo no avanza hasta elegir clase.
	_info.text = ""
	_selector.clases = CLASES
	_selector.elegida.connect(iniciar)
	$Interfaz.add_child(_selector)


## Crea al jugador con la clase elegida y arranca la partida.
func iniciar(ficha: FichaCriatura) -> void:
	_selector.queue_free()
	jugador = mundo.crear_jugador(ficha)
	_vistas[jugador].add_child(CamaraJuego.new())
	_hud.jugador = jugador
	_panel = PanelPersonaje.new()
	_panel.jugador = jugador
	_inventario = PanelInventario.new()
	_inventario.jugador = jugador
	_inventario.mundo = mundo
	_barra = BarraHabilidades.new()
	$Interfaz.add_child(_panel)
	$Interfaz.add_child(_inventario)
	$Interfaz.add_child(_barra)
	_barra.configurar(jugador)
	_barra.usar.connect(usar_habilidad)


## Usa una habilidad sobre el objetivo actual o, si no hay, sobre el enemigo bajo el ratón.
func usar_habilidad(indice: int) -> void:
	if jugador == null:
		return
	var blanco := jugador.objetivo
	if blanco == null or not blanco.esta_vivo():
		var bajo_raton := mundo.criatura_en(_mapa_vista.casilla_bajo_el_raton())
		if bajo_raton and bajo_raton.bando == Criatura.Bando.ENEMIGO:
			blanco = bajo_raton
	var resultado := mundo.usar_habilidad(jugador, indice, blanco)
	if MENSAJES_HABILIDAD.has(resultado):
		_vistas[jugador].texto_flotante(MENSAJES_HABILIDAD[resultado], Color(0.75, 0.8, 1.0), 13, -12.0)


func _crear_vista(criatura: Criatura) -> void:
	var vista := CriaturaVista.new(criatura, mundo, _mapa_vista)
	_vistas[criatura] = vista
	_mapa_vista.agregar_al_mundo(vista)


func _physics_process(delta: float) -> void:
	if jugador == null:
		return
	if jugador.esta_vivo():
		var direccion := _direccion_de_teclado()
		if direccion != Vector2i.ZERO:
			jugador.perseguir = false
		jugador.personaje.fijar_direccion(direccion)
	mundo.avanzar(delta)


func _unhandled_input(event: InputEvent) -> void:
	if jugador == null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not jugador.esta_vivo():
			return
		var casilla := _mapa_vista.casilla_bajo_el_raton()
		var otra := mundo.criatura_en(casilla)
		if otra and otra.bando == Criatura.Bando.ENEMIGO:
			jugador.atacar(otra)
		else:
			jugador.perseguir = false
			jugador.personaje.ir_a(casilla)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_2, KEY_3, KEY_4:
				usar_habilidad(event.keycode - KEY_1)
			KEY_I:
				_inventario.alternar()
			KEY_Q:
				var indice := jugador.inventario.buscar(func(o: FichaObjeto) -> bool: return o.cura_vida > 0)
				if indice >= 0:
					jugador.usar(indice)
			KEY_C:
				_panel.alternar()
			KEY_ESCAPE:
				jugador.olvidar_objetivo()


## Convierte la dirección de pantalla (arriba, derecha...) a dirección de casillas.
## En el mapa isométrico, "arriba en pantalla" es (-1, -1) en casillas.
func _direccion_de_teclado() -> Vector2i:
	var pantalla := Vector2i.ZERO
	for tecla in TECLAS_DIRECCION:
		if Input.is_physical_key_pressed(tecla):
			pantalla += TECLAS_DIRECCION[tecla]
	pantalla = pantalla.clamp(Vector2i(-1, -1), Vector2i(1, 1))
	return Vector2i(pantalla.x + pantalla.y, pantalla.y - pantalla.x).clamp(Vector2i(-1, -1), Vector2i(1, 1))


func _al_resolver_ataque(atacante: Criatura, defensor: Criatura, resultado: Combate.Resultado) -> void:
	if resultado.habilidad and not resultado.habilidad.usa_arma:
		return # los hechizos se dibujan en _al_usar_habilidad
	var desde: CriaturaVista = _vistas[atacante]
	var hacia: CriaturaVista = _vistas[defensor]
	if Mundo.distancia(atacante.casilla, defensor.casilla) > 1:
		_lanzar_flecha(desde.position + Vector2(0, -24), hacia.position + Vector2(0, -20))
	else:
		desde.embestir(hacia.position)


func _lanzar_flecha(desde: Vector2, hacia: Vector2) -> void:
	var flecha := Line2D.new()
	flecha.points = PackedVector2Array([Vector2(-8, 0), Vector2(8, 0)])
	flecha.width = 2.0
	flecha.default_color = Color(0.95, 0.9, 0.7)
	flecha.z_index = 150
	flecha.position = desde
	flecha.rotation = (hacia - desde).angle()
	_mapa_vista.agregar_al_mundo(flecha)
	var t := flecha.create_tween()
	t.tween_property(flecha, "position", hacia, 0.15)
	t.tween_callback(flecha.queue_free)


func _al_usar_habilidad(lanzador: Criatura, h: FichaHabilidad, centro: Vector2i, _afectados: Array[Criatura]) -> void:
	var vista: CriaturaVista = _vistas[lanzador]
	vista.texto_flotante(h.nombre, h.color.lightened(0.3), 13, -34.0)
	var mundo_nodo := _mapa_vista.capa_mundo()
	var destino := _mapa_vista.casilla_a_local(centro)
	match h.forma:
		FichaHabilidad.Forma.OBJETIVO, FichaHabilidad.Forma.AREA_OBJETIVO:
			if h.usa_arma:
				return
			var al_llegar := Callable()
			if h.forma == FichaHabilidad.Forma.AREA_OBJETIVO:
				al_llegar = func() -> void: Efectos.onda(mundo_nodo, destino, h.radio, h.color)
			Efectos.proyectil(mundo_nodo, vista.position + Vector2(0, -26), destino + Vector2(0, -16), h.color, al_llegar)
		FichaHabilidad.Forma.AREA_PROPIA, FichaHabilidad.Forma.PROPIA:
			Efectos.onda(mundo_nodo, vista.position, h.radio if h.forma == FichaHabilidad.Forma.AREA_PROPIA else 0, h.color)


func _al_aparecer_objeto(o: Mundo.ObjetoSuelo) -> void:
	var indice := mundo.objetos_en(o.casilla).size() - 1
	var vista := ObjetoSueloVista.new(o, _mapa_vista.casilla_a_local(o.casilla), indice)
	_vistas_objetos[o] = vista
	_mapa_vista.agregar_al_mundo(vista)


func _al_retirar_objeto(o: Mundo.ObjetoSuelo) -> void:
	var vista: ObjetoSueloVista = _vistas_objetos.get(o)
	if vista:
		_vistas_objetos.erase(o)
		vista.queue_free()


func _al_recoger_objeto(c: Criatura, objeto: FichaObjeto, cantidad: int) -> void:
	var texto := "+%d %s" % [cantidad, objeto.nombre] if cantidad > 1 else "+ %s" % objeto.nombre
	_vistas[c].texto_flotante(texto, Color(0.85, 0.95, 1.0), 13, -12.0)


func _al_senalar_casilla(casilla: Vector2i, tipo: Mapa.Tipo, transitable: bool) -> void:
	if jugador == null:
		return
	var otra := mundo.criatura_en(casilla) if mundo else null
	if otra and otra != jugador:
		_info.text = "%s — vida %d / %d  (clic para atacar)" % [
			otra.ficha.nombre, otra.combatiente.vida, otra.combatiente.vida_max,
		]
		return
	var en_suelo := mundo.objetos_en(casilla) if mundo else []
	if not en_suelo.is_empty():
		var nombres: Array[String] = []
		for o in en_suelo:
			nombres.append("%s ×%d" % [o.pila.objeto.nombre, o.pila.cantidad] if o.pila.cantidad > 1 else o.pila.objeto.nombre)
		_info.text = "En el suelo: %s  (clic para ir y recoger)" % ", ".join(nombres)
		return
	_info.text = "Casilla (%d, %d): %s — %s" % [
		casilla.x, casilla.y, NOMBRES_TIPO[tipo], "se puede pisar" if transitable else "bloquea el paso",
	]
