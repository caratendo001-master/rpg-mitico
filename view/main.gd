extends Node2D
## Escena de prueba de la Fase 1: muestra el mapa e informa la casilla bajo el ratón.

const NOMBRES_TIPO := {
	Mapa.Tipo.VACIO: "vacío",
	Mapa.Tipo.SUELO: "suelo",
	Mapa.Tipo.MURO: "muro",
	Mapa.Tipo.COLUMNA: "columna",
}

@onready var _mapa_vista: MapaVista = $MapaVista
@onready var _camara: Camera2D = $Camara
@onready var _info: Label = $Interfaz/Info


func _ready() -> void:
	_camara.position = _mapa_vista.centro_del_mapa()
	_mapa_vista.casilla_senalada.connect(_al_senalar_casilla)


func _al_senalar_casilla(casilla: Vector2i, tipo: Mapa.Tipo, transitable: bool) -> void:
	_info.text = "Casilla (%d, %d): %s — %s" % [
		casilla.x, casilla.y, NOMBRES_TIPO[tipo], "se puede pisar" if transitable else "bloquea el paso",
	]
