class_name Dados
extends RefCounted
## Tiradas de dados estilo D&D para la simulación.
## No depende de nodos: el servidor autoritativo la usará tal cual.
## Con una semilla fija las tiradas son reproducibles (pruebas, repeticiones).

var _rng := RandomNumberGenerator.new()


func _init(semilla: int = 0) -> void:
	if semilla == 0:
		_rng.randomize()
	else:
		_rng.seed = semilla


## Tira un dado de `caras` caras (1..caras).
func tirar(caras: int) -> int:
	assert(caras >= 1, "Un dado necesita al menos 1 cara")
	return _rng.randi_range(1, caras)


func d20() -> int:
	return tirar(20)


## Tirada de impacto: d20 + modificador contra la defensa del objetivo.
## El 20 natural siempre impacta y el 1 natural siempre falla.
func tirada_impacto(modificador: int, defensa: int) -> bool:
	var dado := d20()
	if dado == 20:
		return true
	if dado == 1:
		return false
	return dado + modificador >= defensa
