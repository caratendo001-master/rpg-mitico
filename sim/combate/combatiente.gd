class_name Combatiente
extends RefCounted
## Vida, maná, atributos y progresión (experiencia y nivel) de una criatura.
## Los atributos se copian de la `FichaCriatura` al crearse: cada combatiente
## sube los suyos sin cambiar la ficha compartida.

signal herido(cantidad: int, critico: bool)
signal esquivo
signal curado(cantidad: int)
signal murio
signal experiencia_ganada(cantidad: int)
signal subio_nivel(nivel: int)

## El orden coincide con `FichaArma.Atributo` (FUERZA = 0, DESTREZA = 1).
enum Atributo { FUERZA, DESTREZA, CONSTITUCION, INTELIGENCIA, SABIDURIA }

const NIVEL_MAXIMO := 100
const PUNTOS_POR_NIVEL := 2
## Al morir se pierde esta fracción de lo que falta para el siguiente nivel (sin bajar de nivel).
const PENALIZACION_MUERTE := 0.1

var ficha: FichaCriatura
var vida: int
var mana: int
var nivel := 1
## Experiencia total acumulada.
var experiencia := 0
var puntos_atributo := 0
## Opcional: el equipo puesto suma defensa y atributos.
var equipo: Equipo

var _atributos: Array[int] = []

var vida_max: int:
	get: return maxi(1, ficha.vida_base + 2 * modificador(Atributo.CONSTITUCION) + (nivel - 1) * ficha.vida_por_nivel)
var mana_max: int:
	get: return maxi(0, ficha.mana_base + 2 * modificador(Atributo.INTELIGENCIA) + (nivel - 1) * ficha.mana_por_nivel)
## Destreza mejora la defensa (esquiva).
var defensa: int:
	get: return ficha.defensa_base + modificador(Atributo.DESTREZA) + (equipo.defensa() if equipo else 0)


func _init(p_ficha: FichaCriatura) -> void:
	ficha = p_ficha
	_atributos = [ficha.fuerza, ficha.destreza, ficha.constitucion, ficha.inteligencia, ficha.sabiduria]
	restaurar()


## Experiencia total necesaria para estar en `n`: 0, 100, 300, 600, 1000...
static func experiencia_para_nivel(n: int) -> int:
	return 50 * (n - 1) * n


## Valor total del atributo: el propio más lo que sume el equipo.
func atributo(a: Atributo) -> int:
	return _atributos[a] + (equipo.bonus_atributo(a) if equipo else 0)


## Valor propio, sin equipo (el que suben los puntos de atributo).
func atributo_base(a: Atributo) -> int:
	return _atributos[a]


func fijar_atributo(a: Atributo, valor: int) -> void:
	_atributos[a] = valor


func modificador(a: Atributo) -> int:
	return FichaCriatura.modificador(atributo(a))


func usar_equipo(p_equipo: Equipo) -> void:
	equipo = p_equipo
	equipo.cambiado.connect(_ajustar_a_maximos)


## Quitarse equipo puede bajar los máximos: la vida y el maná actuales no pueden pasarse.
func _ajustar_a_maximos() -> void:
	vida = mini(vida, vida_max)
	mana = mini(mana, mana_max)


func restaurar() -> void:
	vida = vida_max
	mana = mana_max


func esta_vivo() -> bool:
	return vida > 0


## Bonificación de impacto y de daño con un arma (fuerza o destreza).
func bonus_ataque(arma: FichaArma) -> int:
	return modificador(arma.atributo as Atributo)


func recibir_dano(cantidad: int, critico: bool = false) -> void:
	if not esta_vivo():
		return
	vida = maxi(0, vida - cantidad)
	herido.emit(cantidad, critico)
	if vida == 0:
		_penalizar_muerte()
		murio.emit()


func esquivar() -> void:
	esquivo.emit()


func curar(cantidad: int) -> void:
	if not esta_vivo() or cantidad <= 0 or vida >= vida_max:
		return
	var antes := vida
	vida = mini(vida_max, vida + cantidad)
	curado.emit(vida - antes)


## Recuperación de cada tick: vida según la ficha; maná según sabiduría.
func regenerar() -> void:
	curar(ficha.regen_vida)
	if mana_max > 0:
		mana = mini(mana_max, mana + maxi(1, 1 + modificador(Atributo.SABIDURIA)))


## Suma experiencia y sube los niveles que correspondan. Cada nivel da puntos de
## atributo, más vida y maná máximos, y cura por completo.
func ganar_experiencia(cantidad: int) -> void:
	if cantidad <= 0:
		return
	experiencia += cantidad
	experiencia_ganada.emit(cantidad)
	while nivel < NIVEL_MAXIMO and experiencia >= experiencia_para_nivel(nivel + 1):
		nivel += 1
		puntos_atributo += PUNTOS_POR_NIVEL
		restaurar()
		subio_nivel.emit(nivel)


## Gasta un punto en un atributo. Devuelve false si no hay puntos.
func asignar_punto(a: Atributo) -> bool:
	if puntos_atributo <= 0:
		return false
	puntos_atributo -= 1
	var vida_antes := vida_max
	var mana_antes := mana_max
	_atributos[a] += 1
	# Si sube el máximo, la vida y el maná actuales suben lo mismo.
	vida += vida_max - vida_antes
	mana += mana_max - mana_antes
	return true


## Fracción (0..1) del camino entre el nivel actual y el siguiente.
func progreso_nivel() -> float:
	var desde := experiencia_para_nivel(nivel)
	var hasta := experiencia_para_nivel(nivel + 1)
	return clampf(float(experiencia - desde) / (hasta - desde), 0.0, 1.0)


func _penalizar_muerte() -> void:
	var minimo := experiencia_para_nivel(nivel)
	var perdida := int((experiencia_para_nivel(nivel + 1) - minimo) * PENALIZACION_MUERTE)
	experiencia = maxi(minimo, experiencia - perdida)
