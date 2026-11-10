## title: "Auditoría de diseño de software: EIEInfo"
subtitle: "Entrega 1 · Levantamiento del sistema y diagnóstico inicial"
author: "Gabriel Ulloa - C27890 · IE0417 – Diseño de Software para Ingeniería"
date: "12 de noviembre de 2026 · Commit auditado d7c8c1b"

## El punto de partida

Un sistema con **10 años de historia**, **2567 cambios** acumulados, **21 áreas internas** y unas **60 000 líneas de Python**.

Pregunta de la entrega: **¿qué sistema tenemos enfrente y cómo está construido?**

Trabajé siempre sobre una «fotografía» exacta: el commit `d7c8c1b` (14/10/2026).

## Qué se pidió y qué se entregó

| Requisito | Entregado | 
| ----- | ----- | 
| Ficha técnica | Piezas, tecnologías y conexiones del sistema | 
| Mapa del sistema | 3 diagramas | 
| Inventario funcional | Usuarios, roles, flujos y módulos críticos | 
| Hallazgos (8 a 15) | **15**, con evidencia, impacto y criticidad | 
| Matriz de riesgos | **10** riesgos priorizados | 

Regla de trabajo: **nada sin evidencia** (archivo, línea o comando).

## Cómo hice el levantamiento

| Herramienta | Qué es | Para qué la usé | 
| ----- | ----- | ----- | 
| Docker | Una «caja» que trae el sistema con todo lo que necesita | Verlo funcionando en mi computadora | 
| `recon.sh` | Script de «reconocimiento»: un programa pequeño que recorre el repositorio y junta datos | 11 archivos de datos en minutos | 
| `cloc` | *Count Lines Of Code*: cuenta líneas por lenguaje y carpeta | Medir el tamaño del sistema | 
| `git log` | Historial de cambios del proyecto | Ver qué archivos cambian más | 
| `grep` | Buscador de texto dentro de archivos | Hallar configuraciones y conexiones | 

## Una pista no es un hallazgo

1. **Pista en `recon.sh`:** el script contó los archivos de migración y dio casi cero (`mig=0`):

```bash
# De recon.sh — Conteo de migraciones por app
mig=$(find "$d/migrations" -name '0*.py' 2>/dev/null | wc -l)
printf "%-28s %8s %8s %8s %8s %6s\n" "$d" "$models" "$views" "$forms" "$tests" "$mig"
```

2. **Verificación:** abrí `migraciones.sh` y vi un `find … -delete`.

3. **Hallazgo:** las migraciones se **borran y regeneran** en cada arranque.

4. **Registro:** evidencia E-007, E-008 (E-001 a E-028 en total).

Cuando encontré claves, **no las copié ni las probé**: usé comandos para ver solo sus nombres.

## Uso de asistentes de IA

* Herramientas: **Codex, Antigravity, GitHub Copilot y Claude**

* Apoyo en exploración, comandos, automatización y redacción

* **La verificación no se delega:** cada hallazgo se contrastó con el repositorio

* Me corregí varias veces (p. ej., sí existe CI: `.drone.yml`)

## Las piezas del sistema

| Pieza | Qué es | En EIEInfo | 
| ----- | ----- | ----- | 
| Django (monolito) | Marco de trabajo en Python; todo el sistema en un solo bloque | 21 apps internas | 
| MariaDB vía `mysqlclient` | MariaDB: la base de datos (compatible con MySQL). `mysqlclient`: el «traductor» con el que Python le habla | Guarda toda la información | 
| `settings.py` | El «panel de control»: base de datos, claves, modo de prueba o producción, hosts permitidos | Hay secretos y lógica por nombre de máquina | 
| Migraciones | El «historial de planos» de la base de datos: cada cambio queda registrado y se puede aplicar o deshacer | No se guardan y se regeneran | 
| nginx + gunicorn | La «recepción» que atiende y el servidor que ejecuta el sistema | nginx :8080 → gunicorn :8001 | 

## Cómo se prueba y se publica

| Concepto | Qué es | En EIEInfo | 
| ----- | ----- | ----- | 
| CI (integración continua) | Cada cambio se arma y se prueba solo | Drone: ≈80 pruebas de humo + pruebas en 11 apps | 
| CD (despliegue continuo) | Lo que pasa las pruebas se publica solo | El paso «deployment» solo ejecuta `git status` | 
| `.drone.yml` | La «receta» del revisor automático: lista de pasos | 74 modificaciones en su historial | 
| Integraciones | Conexiones con servicios de terceros | Google, Facebook, Imgur, reCAPTCHA, OwnCloud, correo, Firmador Libre | 
| Entornos | Copias del sistema con distinto fin: desarrollo, pruebas, producción | Contenedores en CI y desarrollo; servidor aparte en producción (inferido) | 

## Quién lo usa

| Usuario | Portal | Roles detectados | 
| ----- | ----- | ----- | 
| Estudiantes | `/estudiantes` | estudiante, bodega, proyecto eléctrico | 
| Profesores | `/profesores` | 11 (director, comisión de docencia, consejo asesor…) | 
| Administrativos | `/administrativos` | 5 (inventario, jefatura, recepción, asuntos estudiantiles…) | 
| Egresados / Público | `/alumni`, `/` | alumni / sin rol | 

**Módulos críticos:** `administrativos`, `profesores`, `estudiantes`, `cursos`, `webpage`, `firma_digital`

## Mapa del sistema: contexto

```
flowchart LR
  Pub[Público general] --> S[EIEInfo<br/>monolito Django]
  Est[Estudiantes] --> S
  Prof[Profesores] --> S
  Adm[Administrativos<br/>roles internos] --> S
  Alu[Egresados] --> S
  S --> DB[(MariaDB)]
  S --> SMTP[Correo institucional]
  S --> G[Google: calendario,<br/>búsqueda, Scholar, reCAPTCHA]
  S --> RS[Facebook / Instagram]
  S --> IM[Imgur]
  S --> OC[OwnCloud]
  Est -.->|navegador| FL[Firmador Libre<br/>local :3516]
  CI[Drone CI] -->|build y pruebas| S
  CI --> TG[Telegram y correo]
  CI -->|SSH| F[Servidor de producción]

```

## Entornos: lo que se prueba no es lo que se usa

```
flowchart TB
  subgraph CIDEV["CI y desarrollo (Docker Compose)"]
    N[nginx :8080<br/>/media/tfg denegado] --> A[gunicorn + Django :8001]
    A --> D[(MariaDB :3307 publicado)]
    N --- V[(volúmenes static y media)]
    A --- V
  end
  subgraph PROD["Producción (host faraday, inferido)"]
    N2[nginx] --> A2[servicio eieinfo<br/>systemd + socket]
    A2 --> D2[(Base de datos)]
  end
  DRONE[Drone CI] -->|docker compose| CIDEV
  DRONE -->|SSH: solo git status| PROD

```

## Cómo están conectadas las áreas

```
flowchart LR
  profesores -->|22| administrativos
  administrativos -->|8| profesores
  profesores -->|13| cursos
  administrativos -->|10| cursos
  cursos -->|6| administrativos
  profesores -->|10| proyectos
  profesores -->|8| estudiantes
  estudiantes -->|7| administrativos
  administrativos -->|7| estudiantes
  tfg[trabajo_final_de_graduacion] -->|7| profesores
  tfg -->|7| administrativos
  tfg -->|5| estudiantes
  profesores -->|6| webpage
  estudiantes -->|6| webpage
  estudiantes -->|6| cursos
  inventario -->|5| administrativos
  administrativos -->|5| webpage

  style administrativos fill:#e8833a,color:#ffffff

```

**16 de 20** áreas dependen de `administrativos` · **más de 25** parejas se necesitan mutuamente

## Código frente a pruebas

| Módulo / App | Líneas de Código (vistas) | Líneas de Pruebas | Comparación | 
| ----- | ----- | ----- | ----- | 
| `profesores` | 5 190 | 3 679 | Vistas > Pruebas | 
| `firma_digital` | 2 918 | 6 151 | **Pruebas > 2× Vistas** | 
| `administrativos` | 2 428 | 1 853 | Vistas > Pruebas | 
| `estudiantes` | 1 483 | 442 | Cobertura muy baja | 
| `trabajo_final_de_graduacion` | 1 352 | 1 289 | Cobertura equilibrada | 
| `solicitud_documentos_externo` | 511 | 1 829 | **Pruebas > 3× Vistas** | 

La calidad no es pareja: `firma_digital` tiene más del doble de pruebas que de código; otras áreas casi ninguna.

## Los 15 hallazgos en cuatro bloques

| Bloque | De qué se trata | Ejemplo con evidencia | Gravedad | 
| ----- | ----- | ----- | ----- | 
| **1. Operación y configuración** (H-02, 03, 04, 05, 09) | Cómo se guardan los cambios de la base, cómo se decide el modo del sistema y cómo se publica | `migraciones.sh` borra y regenera las migraciones en cada arranque | Crítica | 
| **2. Seguridad y datos** (H-01, 14, 15) | Claves en el repositorio, un archivo con columna «Contraseña» y accesos repartidos en muchos puntos | `settings.py:345`, `.env`, `OwncloudProfesores.csv` | Crítica | 
| **3. Plataforma y pruebas** (H-06, 08) | Software base sin correcciones de seguridad y pruebas que cubren solo una parte | `python:buster`, Django 4.1.3; el CI prueba 11 de 21 áreas | Alta | 
| **4. Estructura y personas** (H-07, 10, 11, 12, 13) | Áreas enredadas, archivos enormes, dominio disperso y conocimiento en pocas manos | 16 de 20 áreas dependen de `administrativos`; un autor con ≈45 % de los commits | Alta | 

**Lo que une los cuatro bloques:** lo más serio está en **cómo se cuida y se opera** el sistema, no en la lógica del negocio.

## Lo bueno, y cómo ordené los riesgos

**Fortalezas:** revisor automático real · cultura de pruebas amplia · claves del pipeline bien resguardadas · protección de archivos de TFG en nginx · apps por dominio como base para ordenar

| Prioridad (impacto × probabilidad) | Riesgo | 
| ----- | ----- | 
| **9** | Esquema de la base de datos irrecuperable | 
| **6** | Claves y datos mal usados · modo de prueba expuesto · publicación irrecuperable · software sin parches · cambios con efectos colaterales | 

## Lo que me llevo

* **La evidencia le gana a la intuición**

* **Los problemas serios no están donde uno mira primero:** estaban en el cuidado del sistema

* **Con la IA se gana velocidad, pero la responsabilidad se queda**

* **La información sensible se cuida:** no se copia, no se prueba, se avisa

* **Leer un sistema es leer decisiones de personas:** se trata de entender, no de culpar

**Entrega 2:** profundizar en 5 áreas · `pip-audit` · pantallas sin protección · confirmar si las claves son reales

**Gracias.**