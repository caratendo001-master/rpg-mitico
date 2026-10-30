class_name PanelInventario
extends PanelContainer
## Inventario y equipo (tecla I). Clic en un objeto: usarlo o equiparlo. Clic derecho: tirarlo.
## Clic en una ranura de equipo: quitárselo. Lee la simulación y le manda acciones.

const RANURAS := [
	[FichaObjeto.Ranura.CABEZA, "Cabeza"],
	[FichaObjeto.Ranura.TORSO, "Torso"],
	[FichaObjeto.Ranura.MANOS, "Manos"],
	[FichaObjeto.Ranura.ARMA, "Arma"],
	[FichaObjeto.Ranura.ESCUDO, "Escudo"],
	[FichaObjeto.Ranura.ANILLO, "Anillo"],
]
const AYUDA_INVENTARIO := "Clic: usar / equipar · Clic derecho: tirar al suelo"
const AYUDA_EQUIPO := "Clic: quitar"

var jugador: Criatura
var mundo: Mundo

var _peso := Label.new()
var _botones_equipo := {} # Ranura -> BotonObjeto
var _botones_inventario: Array[BotonObjeto] = []


func _ready() -> void:
	visible = false
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = 24
	offset_right = 24 + 330
	offset_top = -210
	offset_bottom = 210
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 8)
	add_child(caja)
	var titulo := Label.new()
	titulo.text = "Inventario"
	titulo.add_theme_font_size_override("font_size", 20)
	caja.add_child(titulo)
	caja.add_child(_peso)

	caja.add_child(_etiqueta("Equipo"))
	var rejilla_equipo := GridContainer.new()
	rejilla_equipo.columns = 6
	caja.add_child(rejilla_equipo)
	for r in RANURAS:
		var b := BotonObjeto.new()
		b.etiqueta_vacia = r[1]
		var ranura: FichaObjeto.Ranura = r[0]
		b.pressed.connect(func() -> void: jugador.equipo.desequipar(ranura, jugador.inventario))
		rejilla_equipo.add_child(b)
		_botones_equipo[ranura] = b

	caja.add_child(_etiqueta("Mochila"))
	var rejilla := GridContainer.new()
	rejilla.columns = 5
	caja.add_child(rejilla)
	for i in Inventario.CASILLAS:
		var b := BotonObjeto.new()
		b.pressed.connect(func() -> void: jugador.usar(i))
		b.clic_derecho.connect(func() -> void: mundo.tirar_del_inventario(jugador, i))
		rejilla.add_child(b)
		_botones_inventario.append(b)

	var ayuda := Label.new()
	ayuda.text = "I: cerrar · Q: beber poción"
	ayuda.modulate = Color(1, 1, 1, 0.6)
	caja.add_child(ayuda)


func _etiqueta(texto: String) -> Label:
	var l := Label.new()
	l.text = texto
	l.modulate = Color(1, 0.9, 0.6)
	return l


func alternar() -> void:
	visible = not visible


func _process(_delta: float) -> void:
	if not visible or jugador == null:
		return
	var inv := jugador.inventario
	_peso.text = "Peso: %.1f / %.0f" % [inv.peso_total(), inv.carga_maxima()]
	for r in _botones_equipo:
		_botones_equipo[r].mostrar(jugador.equipo.en(r), 1, AYUDA_EQUIPO)
	for i in _botones_inventario.size():
		var p := inv.casillas[i]
		_botones_inventario[i].mostrar(p.objeto if p else null, p.cantidad if p else 0, AYUDA_INVENTARIO)
