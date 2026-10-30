extends Node2D
## Escena de prueba de la Fase 1: mapa, jugador que camina (clic o teclado) y cámara.
## Traduce la entrada a acciones de la simulación y la hace avanzar en el bucle de física.

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

var jugador: Personaje

@onready var _mapa_vista: MapaVista = $MapaVista
@onready var _info: Label = $Interfaz/Info


func _ready() -> void:
	var mapa := _mapa_vista.mapa
	jugador = Personaje.new(mapa, BuscadorCamino.new(mapa), mapa.inicio)
	var vista := PersonajeVista.new(jugador, _mapa_vista)
	vista.add_child(CamaraJuego.new())
	_mapa_vista.agregar_al_mundo(vista)
	_mapa_vista.casilla_senalada.connect(_al_senalar_casilla)


func _physics_process(delta: float) -> void:
	jugador.fijar_direccion(_direccion_de_teclado())
	jugador.avanzar(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		jugador.ir_a(_mapa_vista.casilla_bajo_el_raton())


## Convierte la dirección de pantalla (arriba, derecha...) a dirección de casillas.
## En el mapa isométrico, "arriba en pantalla" es (-1, -1) en casillas.
func _direccion_de_teclado() -> Vector2i:
	var pantalla := Vector2i.ZERO
	for tecla in TECLAS_DIRECCION:
		if Input.is_physical_key_pressed(tecla):
			pantalla += TECLAS_DIRECCION[tecla]
	pantalla = pantalla.clamp(Vector2i(-1, -1), Vector2i(1, 1))
	return Vector2i(pantalla.x + pantalla.y, pantalla.y - pantalla.x).clamp(Vector2i(-1, -1), Vector2i(1, 1))


func _al_senalar_casilla(casilla: Vector2i, tipo: Mapa.Tipo, transitable: bool) -> void:
	_info.text = "Casilla (%d, %d): %s — %s" % [
		casilla.x, casilla.y, NOMBRES_TIPO[tipo], "se puede pisar" if transitable else "bloquea el paso",
	]
