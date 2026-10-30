class_name TablaBotin
extends Resource
## Lo que puede soltar una criatura al morir. Cada entrada se tira por separado.

@export var entradas: Array[EntradaBotin] = []


func tirar(dados: Dados) -> Array[Pila]:
	var resultado: Array[Pila] = []
	for e in entradas:
		if e.objeto == null:
			continue
		if dados.tirar(1000) > roundi(e.probabilidad * 1000.0):
			continue
		var cantidad := e.cantidad_min
		if e.cantidad_max > e.cantidad_min:
			cantidad += dados.tirar(e.cantidad_max - e.cantidad_min + 1) - 1
		resultado.append(Pila.new(e.objeto, cantidad))
	return resultado
