class_name Combatiente
extends RefCounted
## Vida, maná y valores de combate derivados de una `FichaCriatura`.

signal herido(cantidad: int, critico: bool)
signal esquivo
signal curado(cantidad: int)
signal murio

var ficha: FichaCriatura
var vida: int
var mana: int

## Constitución suma 2 de vida por punto de modificador.
var vida_max: int:
	get: return maxi(1, ficha.vida_base + 2 * FichaCriatura.modificador(ficha.constitucion))
## Inteligencia suma 2 de maná por punto de modificador.
var mana_max: int:
	get: return maxi(0, ficha.mana_base + 2 * FichaCriatura.modificador(ficha.inteligencia))
## Destreza mejora la defensa (esquiva).
var defensa: int:
	get: return ficha.defensa_base + FichaCriatura.modificador(ficha.destreza)


func _init(p_ficha: FichaCriatura) -> void:
	ficha = p_ficha
	restaurar()


func restaurar() -> void:
	vida = vida_max
	mana = mana_max


func esta_vivo() -> bool:
	return vida > 0


## Bonificación de impacto y de daño con un arma (fuerza o destreza).
func bonus_ataque(arma: FichaArma) -> int:
	var valor := ficha.fuerza if arma.atributo == FichaArma.Atributo.FUERZA else ficha.destreza
	return FichaCriatura.modificador(valor)


func recibir_dano(cantidad: int, critico: bool = false) -> void:
	if not esta_vivo():
		return
	vida = maxi(0, vida - cantidad)
	herido.emit(cantidad, critico)
	if vida == 0:
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
		mana = mini(mana_max, mana + maxi(1, 1 + FichaCriatura.modificador(ficha.sabiduria)))
