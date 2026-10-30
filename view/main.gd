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

const FICHA_JUGADOR := preload("res://data/criaturas/guerrero.tres")
const FICHA_RATA := preload("res://data/criaturas/rata_gigante.tres")

var mundo: Mundo
var jugador: Criatura

var _vistas := {} # Criatura -> CriaturaVista
var _vistas_objetos := {} # Mundo.ObjetoSuelo -> ObjetoSueloVista

@onready var _mapa_vista: MapaVista = $MapaVista
@onready var _info: Label = $Interfaz/Info
@onready var _hud: Hud = $Interfaz/Hud

var _panel := PanelPersonaje.new()
var _inventario := PanelInventario.new()


func _ready() -> void:
	mundo = Mundo.new(_mapa_vista.mapa)
	mundo.criatura_agregada.connect(_crear_vista)
	mundo.ataque_resuelto.connect(_al_resolver_ataque)
	mundo.objeto_en_suelo.connect(_al_aparecer_objeto)
	mundo.objeto_retirado.connect(_al_retirar_objeto)
	mundo.objeto_recogido.connect(_al_recoger_objeto)
	jugador = mundo.crear_jugador(FICHA_JUGADOR)
	mundo.poblar("r", FICHA_RATA)
	_vistas[jugador].add_child(CamaraJuego.new())
	_hud.jugador = jugador
	_panel.jugador = jugador
	_inventario.jugador = jugador
	_inventario.mundo = mundo
	$Interfaz.add_child(_panel)
	$Interfaz.add_child(_inventario)
	_mapa_vista.casilla_senalada.connect(_al_senalar_casilla)


func _crear_vista(criatura: Criatura) -> void:
	var vista := CriaturaVista.new(criatura, mundo, _mapa_vista)
	_vistas[criatura] = vista
	_mapa_vista.agregar_al_mundo(vista)


func _physics_process(delta: float) -> void:
	if jugador.esta_vivo():
		var direccion := _direccion_de_teclado()
		if direccion != Vector2i.ZERO:
			jugador.perseguir = false
		jugador.personaje.fijar_direccion(direccion)
	mundo.avanzar(delta)


func _unhandled_input(event: InputEvent) -> void:
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


func _al_resolver_ataque(atacante: Criatura, defensor: Criatura, _resultado: Combate.Resultado) -> void:
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
