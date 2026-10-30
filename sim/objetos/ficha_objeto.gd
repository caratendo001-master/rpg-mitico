class_name FichaObjeto
extends Resource
## Datos de un objeto: equipo, consumible o material. Se guarda en data/objetos/*.tres.

enum Ranura { NINGUNA, CABEZA, TORSO, MANOS, ARMA, ESCUDO, ANILLO }

@export var nombre := "Objeto"
@export_multiline var descripcion := ""
## Icono para inventario y suelo. Si está vacío se dibuja un placeholder con `color`.
@export var icono: Texture2D
@export var color := Color.GRAY
@export var peso := 1.0
## Precio base (para la tienda).
@export var valor := 0
## Cuántos caben en una casilla del inventario (1 = no se apila).
@export var max_pila := 1

@export_group("Equipo")
@export var ranura: Ranura = Ranura.NINGUNA
## Solo para la ranura ARMA.
@export var arma: FichaArma
@export var defensa := 0
@export var fuerza := 0
@export var destreza := 0
@export var constitucion := 0
@export var inteligencia := 0
@export var sabiduria := 0

@export_group("Consumible")
@export var cura_vida := 0
@export var cura_mana := 0


func es_equipable() -> bool:
	return ranura != Ranura.NINGUNA


func es_consumible() -> bool:
	return cura_vida > 0 or cura_mana > 0


## Bonificación a un atributo (`Combatiente.Atributo`).
func bonus_atributo(atributo: int) -> int:
	return [fuerza, destreza, constitucion, inteligencia, sabiduria][atributo]


## Texto corto con lo que hace, para tooltips.
func resumen() -> String:
	var partes: Array[String] = [nombre]
	if arma:
		partes.append("Daño %dd%d, alcance %d" % [arma.dados, arma.caras, arma.alcance])
	if defensa:
		partes.append("Defensa +%d" % defensa)
	var nombres := ["Fuerza", "Destreza", "Constitución", "Inteligencia", "Sabiduría"]
	for i in nombres.size():
		if bonus_atributo(i):
			partes.append("%s %+d" % [nombres[i], bonus_atributo(i)])
	if cura_vida:
		partes.append("Cura %d de vida" % cura_vida)
	if cura_mana:
		partes.append("Recupera %d de maná" % cura_mana)
	if descripcion:
		partes.append(descripcion)
	partes.append("Peso %.1f · Valor %d" % [peso, valor])
	return "\n".join(partes)
