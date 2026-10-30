# RPG Mítico Online — Documento de Diseño y Plan del Vertical Slice

28 oct 2026 · Jorge Cano Ramírez

## Visión del juego

Un RPG de fantasía mítica en vista isométrica, donde el jugador explora mazmorras y tierras salvajes,
pelea en tiempo real y crece su personaje; primero para un jugador y, al final, como mundo online
persistente tipo Tibia.

### Inspiraciones
- **Dungeons & Dragons:** clases, atributos, criaturas míticas y el tono de aventura.
- **Project Zomboid:** vista isométrica 2.5D, mundo detallado, sistemas que simulan cosas (hambre, luz, ruido) y una IA que reacciona.
- **Tibia:** movimiento por casillas, combate en tiempo real, muerte con consecuencias y mundo compartido.

### Pilares de diseño (todo lo que se agregue debe reforzar al menos uno)
1. **Peligro real.** Las mazmorras dan miedo; morir cuesta algo.
2. **Mundo que reacciona.** Enemigos que escuchan, persiguen, huyen y se coordinan.
3. **Progresión que se siente.** Cada nivel, objeto o hechizo cambia cómo juegas.
4. **Hecho para compartir.** Cada sistema se diseña pensando en que algún día lo jugarán varias personas a la vez.

## Decisiones técnicas

| Tema | Decisión | Por qué |
|---|---|---|
| Motor | Godot 4 (estable más reciente: 4.7) | Gratis, ligero, buen soporte isométrico (TileMapLayer) y networking integrado |
| Lenguaje | GDScript | Fácil de leer y de pedirle cambios a Claude Code; C# solo si hace falta rendimiento |
| Perspectiva | Isométrica 2:1 por casillas (tiles 64×32 px) | Look tipo Project Zomboid y movimiento tipo Tibia, que simplifica el online |
| Arte | Pixel art isométrico; placeholders al inicio | Packs gratuitos o comprados para prototipar; artista después |
| Control de versiones | Git + GitHub desde el día 1 | Historial para regresar si algo se rompe |
| Datos del juego | Objetos, enemigos y hechizos en Resources o JSON | Balancear sin tocar código y luego servirlos desde el servidor |

**Regla de arquitectura clave:** el estado del juego (posiciones, vida, inventario, combate) vive en
clases de "simulación" que no dependen de nodos visuales. Los nodos de Godot solo leen ese estado y lo
dibujan. Cuando llegue el online, la simulación se muda al servidor y el cliente solo dibuja y envía acciones.

## Mundo y tono (propuesta editable)

- **Tono:** fantasía oscura pero aventurera. Ruinas antiguas, magia peligrosa, dioses olvidados.
- **Premisa:** un reino fronterizo construido sobre las ruinas de una civilización que selló algo bajo tierra. Los sellos se están rompiendo y las mazmorras despiertan.
- **Región inicial:** un pueblo amurallado (zona segura con mercader, herrero y sacerdote) y, a las afueras, la primera mazmorra: una cripta de tres pisos.
- **Facciones (después):** la Guardia del pueblo, una orden de magos que estudia los sellos y un culto que quiere romperlos.
- **Criaturas del primer arco:** ratas gigantes, esqueletos, goblins y un jefe nigromante al fondo de la cripta.
- Nombres del reino, del pueblo y de la cripta: **pendientes**.

## Mecánicas núcleo

### Movimiento
- Por casillas en 8 direcciones, con clic para caminar (pathfinding A*) y teclado opcional.
- Velocidad de movimiento como atributo; el terreno puede ralentizar.
- Puertas, escaleras entre pisos y objetos que bloquean el paso.

### Combate
- Tiempo real con turnos internos (ticks de ~1 s): cada tick, cada criatura puede atacar una vez.
- Habilidades con enfriamiento global estilo WoW (confirmado).
- Cuerpo a cuerpo, a distancia y hechizos con costo de maná y enfriamiento.
- Tirada de impacto y daño estilo D&D (d20 + modificador contra defensa), siempre en la simulación, nunca en lo visual.

### Atributos y clases

| Atributo | Afecta |
|---|---|
| Fuerza | Daño cuerpo a cuerpo, carga máxima |
| Destreza | Precisión, daño a distancia, esquiva |
| Constitución | Vida máxima, resistencias |
| Inteligencia | Maná, daño de hechizos |
| Sabiduría | Regeneración de maná, curación |

Clases del slice: **Guerrero** y **Mago**. Pícaro y Clérigo después.

### Progresión, inventario y botín
- Experiencia por matar y por misiones; al subir de nivel: vida, maná y puntos de atributo.
- Inventario por cuadrícula con peso máximo; equipo en ranuras (cabeza, torso, manos, arma, escudo, anillo).
- Botín por tablas de probabilidad por criatura.
- Muerte: pierdes parte de la experiencia y reapareces en el templo del pueblo.

## IA, diálogos y cinemáticas

### IA de enemigos
- Estados: Patrullar → Sospechar → Perseguir → Atacar → Huir (vida baja) → Regresar.
- Percepción: cono de visión con línea de vista y radio de oído; correr o pelear hace más ruido que caminar.
- Por tipo: ratas en grupo, esqueletos lentos pero resistentes, goblins que huyen y llaman refuerzos, magos que mantienen distancia.
- Todo corre dentro de la simulación.

### NPCs y diálogos
- Árboles de opciones guardados como datos, con condiciones ("tiene la llave") y efectos ("da misión").
- NPCs del slice: mercader, herrero, sacerdote y un guardia que entrega la misión de la cripta.

### Cinemáticas
- Con el motor (AnimationPlayer): cámara, texto, personajes; sin videos.
- Slice: intro al llegar al pueblo y escena antes del jefe. Siempre se pueden saltar.

## Alcance del vertical slice

Un pueblo, una cripta de tres pisos y un jefe, jugable de principio a fin en 20–30 min, un jugador.

| Entra | No entra (por ahora) |
|---|---|
| 2 clases: Guerrero y Mago | Pícaro, Clérigo, razas |
| 4 enemigos + 1 jefe | Mundo abierto entre pueblos |
| 4 NPCs con diálogo y 1 misión principal | Facciones y reputación |
| Inventario, equipo, botín, tienda | Crafteo, casas, mascotas |
| Ciclo día/noche simple y luz de antorcha | Clima, hambre, sed |
| 2 cinemáticas cortas | Doblaje de voz |
| Guardar y cargar partida local | Cuentas, servidor, multijugador |

**Criterio de éxito:** alguien que no seas tú lo juega completo, entiende qué hacer sin ayuda y quiere seguir jugando.

## Tareas por fases

No pasar a la siguiente fase hasta que la anterior cumpla su criterio de terminado al jugarla.

### Fase 0 — Cimientos
- [x] Instalar Godot 4 (4.7.2 en `GODOT/`), Git y Claude Code.
- [x] Crear repositorio en GitHub (github.com/caratendo001-master/rpg-mitico).
- [x] Proyecto base con estructura (sim/, view/, data/, ui/, assets/) y CLAUDE.md con las reglas de arquitectura.
- [x] Pruebas automáticas para la simulación (gdUnit4).

Terminado cuando: el proyecto abre en Godot, corre una escena vacía y las pruebas pasan.

### Fase 1 — Mundo y movimiento
- [x] Mapa isométrico de prueba con TileMapLayer y colisiones (colisiones en `sim/mundo/mapa.gd`).
- [ ] Jugador que camina por casillas con clic (A*) y teclado.
- [ ] Cámara que sigue al jugador, con zoom.
- [ ] Orden de dibujado correcto (el jugador pasa detrás de muros y columnas).

Terminado cuando: puedes recorrer el mapa sin atravesar paredes ni ver errores de orden visual.

### Fase 2 — Combate y enemigos
- [ ] Sistema de ticks, atributos, vida y maná en la simulación.
- [ ] Ataque cuerpo a cuerpo y a distancia con tiradas d20.
- [ ] Primer enemigo con máquina de estados (patrullar, perseguir, atacar).
- [ ] Barra de vida, números de daño y muerte con reaparición.

Terminado cuando: pelear contra 3 ratas es justo y entendible.

### Fase 3 — Progresión e inventario
- [ ] Experiencia, niveles y puntos de atributo.
- [ ] Inventario con peso, equipo en ranuras y botín por tablas.
- [ ] Clases Guerrero y Mago con 3 habilidades cada una.

Terminado cuando: subir de nivel y cambiar de arma se nota en el combate.

### Fase 4 — Pueblo, NPCs y misión
- [ ] Pueblo con zona segura, tienda y templo de reaparición.
- [ ] Sistema de diálogos por datos con condiciones y efectos.
- [ ] Misión principal de la cripta.

### Fase 5 — La cripta
- [ ] Tres pisos con escaleras, oscuridad y luz de antorcha.
- [ ] Resto de enemigos con percepción de vista y oído.
- [ ] Jefe nigromante con 2 fases.

### Fase 6 — Pulido
- [ ] Dos cinemáticas con AnimationPlayer.
- [ ] Menú principal, guardar y cargar, opciones de sonido.
- [ ] Música y efectos de sonido.
- [ ] Prueba con 3 personas y lista de ajustes.

**Cómo pedir cada tarea a Claude Code:** una tarea por sesión, describir qué debe pasar al jugar (no cómo
programarlo), pedir pruebas para la simulación y hacer commit al terminar cada tarea que funcione.

## Decisiones pendientes (antes de la Fase 2)
- [x] Combate en tiempo real por ticks, como Tibia, con enfriamiento global estilo WoW.
- [ ] Nombres del reino, pueblo y cripta.
- [ ] Estilo exacto del arte y origen de los sprites.
- [ ] Plataforma objetivo: solo PC o también móvil.
