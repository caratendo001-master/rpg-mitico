class_name ObjetoSueloVista
extends Node2D
## Un objeto tirado en el suelo. Varios en la misma casilla se reparten un poco.

const TAMANO := 20.0

var objeto_suelo: Mundo.ObjetoSuelo


func _init(p_objeto_suelo: Mundo.ObjetoSuelo, centro_casilla: Vector2, indice: int) -> void:
	objeto_suelo = p_objeto_suelo
	var angulo := indice * 2.4
	position = centro_casilla + Vector2(cos(angulo) * 9.0, sin(angulo) * 4.0) * minf(indice, 1.0)


func _ready() -> void:
	scale = Vector2(0.3, 0.3)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(_delta: float) -> void:
	# Parpadea los últimos segundos antes de desaparecer.
	var t := objeto_suelo.ticks_restantes
	modulate.a = 1.0 if t > 10 else 0.4 + 0.6 * absf(sin(Time.get_ticks_msec() / 150.0))


func _draw() -> void:
	draw_set_transform(Vector2(0, 2), 0, Vector2(1, 0.5))
	draw_circle(Vector2.ZERO, TAMANO * 0.55, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)
	Iconos.dibujar(self, objeto_suelo.pila.objeto, Rect2(-TAMANO / 2, -TAMANO - 2, TAMANO, TAMANO))
