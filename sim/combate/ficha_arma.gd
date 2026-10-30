class_name FichaArma
extends Resource
## Datos de un arma (o ataque natural, como una mordida). Se guarda en data/armas/*.tres.

enum Atributo { FUERZA, DESTREZA }

@export var nombre := "Puños"
## Daño: `dados` d `caras` + modificador del atributo. Ej.: 1d8 → dados = 1, caras = 8.
@export var dados := 1
@export var caras := 2
## Distancia máxima en casillas (1 = cuerpo a cuerpo). A distancia hace falta línea de vista.
@export var alcance := 1
## Atributo que suma al impacto y al daño.
@export var atributo: Atributo = Atributo.FUERZA
