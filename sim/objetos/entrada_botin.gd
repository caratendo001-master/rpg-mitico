class_name EntradaBotin
extends Resource
## Una línea de una tabla de botín: qué objeto, con qué probabilidad y cuántos.

@export var objeto: FichaObjeto
## 0.0 a 1.0 (0.25 = 25%).
@export_range(0.0, 1.0, 0.001) var probabilidad := 1.0
@export var cantidad_min := 1
@export var cantidad_max := 1
