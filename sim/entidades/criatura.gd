class_name Criatura
extends RefCounted
## Jugador o enemigo: une movimiento (`Personaje`), combate (`Combatiente`) y, si es
## un enemigo, su inteligencia (`IaCriatura`). La crea y la hace funcionar `Mundo`.

enum Bando { JUGADOR, ENEMIGO }

signal reaparecio

var ficha: FichaCriatura
var bando: Bando
var combatiente: Combatiente
var personaje: Personaje
var arma: FichaArma
var ia: IaCriatura
## Casilla donde aparece y a la que regresa.
var origen: Vector2i
## A quién ataca cuando está a su alcance (en cada tick). Se guarda como referencia débil:
## dos criaturas que se atacan entre sí no deben mantenerse vivas en memoria mutuamente.
var objetivo: Criatura:
	get: return _objetivo.get_ref() if _objetivo else null
	set(valor): _objetivo = weakref(valor) if valor else null
## Si es true, camina solo hasta tener al objetivo a su alcance.
var perseguir := false
var ticks_muerto := 0

var _objetivo: WeakRef

var casilla: Vector2i:
	get: return personaje.casilla


func _init(p_ficha: FichaCriatura, p_bando: Bando, mapa: Mapa, buscador: BuscadorCamino, p_origen: Vector2i) -> void:
	ficha = p_ficha
	bando = p_bando
	origen = p_origen
	arma = ficha.arma
	combatiente = Combatiente.new(ficha)
	personaje = Personaje.new(mapa, buscador, origen)
	personaje.velocidad = ficha.velocidad
	combatiente.murio.connect(_al_morir)


func esta_vivo() -> bool:
	return combatiente.esta_vivo()


## Marca a otra criatura como objetivo y camina hacia ella hasta tenerla a su alcance.
func atacar(otra: Criatura) -> void:
	objetivo = otra
	perseguir = true


func olvidar_objetivo() -> void:
	objetivo = null
	perseguir = false


func reaparecer() -> void:
	personaje.teletransportar(origen)
	combatiente.restaurar()
	olvidar_objetivo()
	ticks_muerto = 0
	if ia:
		ia.reiniciar()
	reaparecio.emit()


func _al_morir() -> void:
	olvidar_objetivo()
	personaje.detener()
	ticks_muerto = 0
