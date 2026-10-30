class_name PersonajeVista
extends Node2D
## Dibuja un `Personaje` de la simulación (placeholder hasta tener sprites).
## Su origen está en los pies, al centro de la casilla: eso es lo que usa el y-sort.

const COLOR_CUERPO := Color("3f6fb5")
const COLOR_CABEZA := Color("e8c39e")
const COLOR_SOMBRA := Color(0, 0, 0, 0.35)
const COLOR_SILUETA := Color(1, 1, 1, 0.55)

var personaje: Personaje
var mapa_vista: MapaVista

var _silueta := Node2D.new()


func _init(p_personaje: Personaje, p_mapa_vista: MapaVista) -> void:
	personaje = p_personaje
	mapa_vista = p_mapa_vista
	name = "Jugador"


func _ready() -> void:
	# Contorno que se dibuja encima de todo: deja ver al jugador cuando un muro lo tapa.
	_silueta.z_index = 100
	_silueta.draw.connect(_dibujar_silueta)
	add_child(_silueta)
	position = _posicion_en_pantalla()


func _process(_delta: float) -> void:
	position = _posicion_en_pantalla()


func _posicion_en_pantalla() -> Vector2:
	var desde := mapa_vista.casilla_a_local(personaje.paso_desde)
	var hacia := mapa_vista.casilla_a_local(personaje.casilla)
	return desde.lerp(hacia, personaje.fraccion_paso())


func _draw() -> void:
	_dibujar_elipse(Vector2.ZERO, Vector2(13, 6), COLOR_SOMBRA)
	draw_rect(Rect2(-8, -34, 16, 30), COLOR_CUERPO)
	draw_rect(Rect2(-8, -34, 5, 30), COLOR_CUERPO.lightened(0.15))
	draw_circle(Vector2(0, -42), 8, COLOR_CABEZA)


func _dibujar_silueta() -> void:
	_silueta.draw_rect(Rect2(-8, -34, 16, 30), COLOR_SILUETA, false, 1.0)
	_silueta.draw_arc(Vector2(0, -42), 8, 0, TAU, 20, COLOR_SILUETA, 1.0)


func _dibujar_elipse(centro: Vector2, radios: Vector2, color: Color) -> void:
	var puntos := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		puntos.append(centro + Vector2(cos(a) * radios.x, sin(a) * radios.y))
	draw_colored_polygon(puntos, color)
