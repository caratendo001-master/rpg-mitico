class_name FichaCriatura
extends Resource
## Datos base de una criatura o del jugador. Se guarda en data/criaturas/*.tres
## para balancear sin tocar código.

@export var nombre := "Criatura"

@export_group("Atributos")
@export var fuerza := 10
@export var destreza := 10
@export var constitucion := 10
@export var inteligencia := 10
@export var sabiduria := 10

@export_group("Combate")
@export var vida_base := 10
@export var mana_base := 0
@export var defensa_base := 10
## Vida que recupera en cada tick.
@export var regen_vida := 0
## Ataque sin arma equipada (puños, mordida...).
@export var arma: FichaArma

@export_group("Objetos")
## Lo que lleva puesto al aparecer.
@export var equipo_inicial: Array[FichaObjeto] = []
## Lo que lleva en el inventario al aparecer (repetir un objeto para dar varios).
@export var inventario_inicial: Array[FichaObjeto] = []
## Lo que puede soltar al morir.
@export var botin: TablaBotin

@export_group("Progresión")
## Experiencia que da al morir.
@export var experiencia := 0
## Vida y maná extra por cada nivel por encima del 1.
@export var vida_por_nivel := 0
@export var mana_por_nivel := 0

@export_group("Movimiento")
## Casillas por segundo.
@export var velocidad := 4.0

@export_group("Vista")
@export var color := Color.WHITE
@export var tamano := 1.0


## Modificador estilo D&D: 10-11 → 0, 12-13 → +1, 8-9 → -1...
static func modificador(valor: int) -> int:
	return floori((valor - 10) / 2.0)
