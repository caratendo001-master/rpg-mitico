class_name FichaHabilidad
extends Resource
## Una habilidad o hechizo. Se guarda en data/habilidades/*.tres y se asigna a una clase
## (`FichaCriatura.habilidades`). La resuelve `Mundo.usar_habilidad`.

enum Forma {
	OBJETIVO, ## golpea a un enemigo
	AREA_PROPIA, ## golpea a todos los enemigos alrededor de quien la usa
	AREA_OBJETIVO, ## golpea al enemigo y a los que estén a su alrededor
	PROPIA, ## sobre uno mismo (curación)
}

@export var nombre := "Habilidad"
@export_multiline var descripcion := ""
@export var icono: Texture2D
@export var color := Color.WHITE

@export_group("Uso")
@export var forma: Forma = Forma.OBJETIVO
@export var costo_mana := 0
## Segundos hasta poder volver a usarla (además del enfriamiento global).
@export var enfriamiento := 0.0
## Alcance en casillas. Si usa el arma, manda el alcance del arma.
@export var alcance := 1
## Radio del área (formas de área).
@export var radio := 1

@export_group("Efecto")
## Ataque con el arma equipada (sus dados + los de la habilidad).
@export var usa_arma := false
## Bonificación extra para impactar.
@export var bonus_impacto := 0
## Si es true no tira d20: siempre impacta (y nunca es crítico).
@export var siempre_impacta := false
## Dados propios de la habilidad (daño o curación).
@export var dados := 0
@export var caras := 4
## Atributo que suma a impacto y daño/curación cuando no usa arma (`Combatiente.Atributo`).
@export_enum("Fuerza", "Destreza", "Constitución", "Inteligencia", "Sabiduría") var atributo := 3
## Si es true, cura en vez de dañar.
@export var cura := false


func necesita_objetivo() -> bool:
	return forma == Forma.OBJETIVO or forma == Forma.AREA_OBJETIVO


func resumen() -> String:
	var lineas: Array[String] = [nombre]
	if descripcion:
		lineas.append(descripcion)
	lineas.append("Maná %d · Enfriamiento %.0f s" % [costo_mana, enfriamiento])
	return "\n".join(lineas)
