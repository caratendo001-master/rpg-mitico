class_name PanelPersonaje
extends PanelContainer
## Hoja de personaje (tecla C): nivel, experiencia, atributos con botón "+" para gastar
## puntos y valores derivados. Lee la simulación y le manda acciones (`asignar_punto`).

const NOMBRES := {
	Combatiente.Atributo.FUERZA: ["Fuerza", "daño cuerpo a cuerpo"],
	Combatiente.Atributo.DESTREZA: ["Destreza", "precisión, arco y esquiva"],
	Combatiente.Atributo.CONSTITUCION: ["Constitución", "vida máxima"],
	Combatiente.Atributo.INTELIGENCIA: ["Inteligencia", "maná y hechizos"],
	Combatiente.Atributo.SABIDURIA: ["Sabiduría", "regeneración de maná"],
}

var jugador: Criatura

var _titulo := Label.new()
var _resumen := Label.new()
var _valores := {} # Atributo -> Label
var _botones := {} # Atributo -> Button
var _derivados := Label.new()


func _ready() -> void:
	visible = false
	# Pegado al borde derecho, centrado en vertical; crece hacia la izquierda y hacia ambos lados.
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = -364
	offset_right = -24
	offset_top = -170
	offset_bottom = 170
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 8)
	add_child(caja)
	_titulo.add_theme_font_size_override("font_size", 20)
	caja.add_child(_titulo)
	caja.add_child(_resumen)
	caja.add_child(HSeparator.new())
	var rejilla := GridContainer.new()
	rejilla.columns = 3
	rejilla.add_theme_constant_override("h_separation", 12)
	caja.add_child(rejilla)
	for a in NOMBRES:
		var nombre := Label.new()
		nombre.text = NOMBRES[a][0]
		nombre.tooltip_text = NOMBRES[a][1]
		nombre.mouse_filter = Control.MOUSE_FILTER_PASS
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rejilla.add_child(nombre)
		var valor := Label.new()
		rejilla.add_child(valor)
		_valores[a] = valor
		var mas := Button.new()
		mas.text = "+"
		mas.custom_minimum_size = Vector2(32, 0)
		mas.pressed.connect(func() -> void: jugador.combatiente.asignar_punto(a))
		rejilla.add_child(mas)
		_botones[a] = mas
	caja.add_child(HSeparator.new())
	caja.add_child(_derivados)
	var ayuda := Label.new()
	ayuda.text = "C: cerrar"
	ayuda.modulate = Color(1, 1, 1, 0.6)
	caja.add_child(ayuda)


func alternar() -> void:
	visible = not visible


func _process(_delta: float) -> void:
	if not visible or jugador == null:
		return
	var c := jugador.combatiente
	_titulo.text = "%s — nivel %d" % [jugador.ficha.nombre, c.nivel]
	_resumen.text = "Experiencia: %d / %d\nPuntos por asignar: %d" % [
		c.experiencia, Combatiente.experiencia_para_nivel(c.nivel + 1), c.puntos_atributo,
	]
	for a in NOMBRES:
		var mod := c.modificador(a)
		_valores[a].text = "%d  (%s%d)" % [c.atributo(a), "+" if mod >= 0 else "", mod]
		_botones[a].disabled = c.puntos_atributo <= 0
	_derivados.text = "Vida máx.: %d    Maná máx.: %d\nDefensa: %d    Ataque con %s: +%d" % [
		c.vida_max, c.mana_max, c.defensa, jugador.arma.nombre, c.bonus_ataque(jugador.arma),
	]
