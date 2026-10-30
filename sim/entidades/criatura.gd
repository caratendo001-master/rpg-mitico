class_name Criatura
extends RefCounted
## Jugador o enemigo: une movimiento (`Personaje`), combate (`Combatiente`), objetos
## (`Inventario` y `Equipo`) y, si es un enemigo, su inteligencia (`IaCriatura`).
## La crea y la hace funcionar `Mundo`.

enum Bando { JUGADOR, ENEMIGO }

signal murio(criatura: Criatura)
signal reaparecio

var ficha: FichaCriatura
var bando: Bando
var combatiente: Combatiente
var personaje: Personaje
var inventario: Inventario
var equipo: Equipo
## Arma con la que ataca: la equipada o, si no hay, la natural de la ficha.
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
## Segundos que faltan para poder usar cualquier habilidad (enfriamiento global).
var enfriamiento_global := 0.0

var _objetivo: WeakRef
var _enfriamientos := {} # FichaHabilidad -> segundos restantes

var casilla: Vector2i:
	get: return personaje.casilla


func _init(p_ficha: FichaCriatura, p_bando: Bando, mapa: Mapa, buscador: BuscadorCamino, p_origen: Vector2i) -> void:
	ficha = p_ficha
	bando = p_bando
	origen = p_origen
	combatiente = Combatiente.new(ficha)
	personaje = Personaje.new(mapa, buscador, origen)
	personaje.velocidad = ficha.velocidad
	inventario = Inventario.new()
	inventario.limite_peso = carga_maxima
	equipo = Equipo.new()
	combatiente.usar_equipo(equipo)
	equipo.cambiado.connect(_actualizar_arma)
	for o in ficha.equipo_inicial:
		equipo.poner(o)
	for o in ficha.inventario_inicial:
		inventario.agregar(o)
	_actualizar_arma()
	combatiente.restaurar()
	combatiente.murio.connect(_al_morir)


func esta_vivo() -> bool:
	return combatiente.esta_vivo()


## Peso que puede cargar: crece con la fuerza.
func carga_maxima() -> float:
	return 40.0 + 4.0 * combatiente.atributo(Combatiente.Atributo.FUERZA)


## Usa el objeto de una casilla del inventario: bebe un consumible o equipa un objeto.
func usar(indice: int) -> bool:
	var pila := inventario.casillas[indice]
	if pila == null or not esta_vivo():
		return false
	var objeto := pila.objeto
	if objeto.es_consumible():
		combatiente.curar(objeto.cura_vida)
		combatiente.mana = mini(combatiente.mana_max, combatiente.mana + objeto.cura_mana)
		inventario.quitar(indice, 1)
		return true
	if objeto.es_equipable():
		return equipo.equipar(inventario, indice)
	return false


var habilidades: Array[FichaHabilidad]:
	get: return ficha.habilidades


## Segundos que faltan para poder usar esta habilidad (el mayor entre el suyo y el global).
func enfriamiento_de(habilidad: FichaHabilidad) -> float:
	return maxf(_enfriamientos.get(habilidad, 0.0), enfriamiento_global)


func iniciar_enfriamiento(habilidad: FichaHabilidad, global: float) -> void:
	_enfriamientos[habilidad] = habilidad.enfriamiento
	enfriamiento_global = global


func avanzar_enfriamientos(segundos: float) -> void:
	enfriamiento_global = maxf(0.0, enfriamiento_global - segundos)
	for h in _enfriamientos:
		_enfriamientos[h] = maxf(0.0, _enfriamientos[h] - segundos)


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


func _actualizar_arma() -> void:
	var equipada := equipo.en(FichaObjeto.Ranura.ARMA)
	arma = equipada.arma if equipada and equipada.arma else ficha.arma


func _al_morir() -> void:
	olvidar_objetivo()
	personaje.detener()
	ticks_muerto = 0
	murio.emit(self)
