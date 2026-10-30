class_name CamaraJuego
extends Camera2D
## Cámara que sigue a su nodo padre (el jugador) con suavizado y zoom por pasos
## con la rueda del ratón o las teclas + y -.

const NIVELES_ZOOM: Array[float] = [0.5, 1.0, 1.5, 2.0, 3.0]
const VELOCIDAD_ZOOM := 10.0

var _nivel := 2 # 1.5x al empezar


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 6.0
	zoom = Vector2.ONE * NIVELES_ZOOM[_nivel]
	make_current()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			cambiar_zoom(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cambiar_zoom(-1)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_PLUS, KEY_KP_ADD, KEY_EQUAL]:
			cambiar_zoom(1)
		elif event.keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
			cambiar_zoom(-1)


func cambiar_zoom(pasos: int) -> void:
	_nivel = clampi(_nivel + pasos, 0, NIVELES_ZOOM.size() - 1)


func _process(delta: float) -> void:
	var objetivo := Vector2.ONE * NIVELES_ZOOM[_nivel]
	zoom = zoom.lerp(objetivo, minf(1.0, VELOCIDAD_ZOOM * delta))
