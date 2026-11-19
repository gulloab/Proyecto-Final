# Auditoría de diseño de software: EIEInfo
## Presentación Final · Propuesta de Evolución y Cierre de Auditoría
**Estudiante:** Gabriel Ulloa Bermúdez – C27890 · **Curso:** IE0417 – Diseño de Software para Ingeniería  
**Fecha:** Noviembre 2026 · **Commit auditado:** `d7c8c1b`

---

## 1. El sistema en perspectiva: 10 años y dos generaciones

- **El punto de partida:** Monolito Django de 60 000 líneas de Python, 21 aplicaciones registradas y 10 años de desarrollo activo (2016–2026).
- **Dos generaciones de software conviviendo:**
  - **Núcleo histórico (2016–2017):** Altamente acoplado, 52 excepciones sin tipo (`except:`) silenciadas con `# noqa` y 4 524 líneas comentadas en 6 módulos auditados.
  - **Desarrollo moderno (2025):** `firma_digital` y `trabajo_final_de_graduacion` con 0 excepciones desnudas y 456 pruebas autosuficientes, pero repitiendo vistas gigantes (2 918 líneas).
- **Pregunta central de la Entrega 3:**  
  *«Si el sistema tuviera que seguir evolucionando durante los próximos años, ¿qué debería hacerse primero, qué después y bajo qué estrategia?»*

---

## 2. Síntesis del diagnóstico: Los 18 Hallazgos consolidados

| Nivel | Hallazgos clave | Dimensión |
|---|---|---|
| **Críticos (2)** | **H2-01:** Secretos y CSV de contraseñas versionados<br/>**H2-02:** Migraciones borradas y regeneradas al vuelo (`migraciones.sh`) | Seguridad / Datos |
| **Altos (6)** | **H2-03:** Configuración divergente (`DEBUG=True` si `hostname != faraday`)<br/>**H2-04:** Despliegue manual e inconsistente con CI<br/>**H2-05:** 143 avisos OSV (Pillow 9.4.0 activo en subidas de imágenes)<br/>**H2-06:** Acoplamiento circular (`administrativos` fan-in 16)<br/>**H2-07:** Sin capa de servicios (118 consultas ORM en vistas)<br/>**H2-08:** Suite de pruebas local rota por permisos MySQL (error 1044) | Operación / Arquitectura / Dependencias |
| **Medios (7)** | Dominio ambiguo (2 modelos `Ciclo`), código copiado (348 líneas en consejo asesor), vistas de 2 900 líneas, linter silenciado | Calidad / Dominio |
| **Bajos (3)** | 4 524 líneas de código muerto (48.4 % en `trabajos_finales`), residuos de imports y logging | Mantenibilidad |

---

## 3. Árbol de causas: Separar lo urgente de lo estructural

- **Eje Operativo y de Datos (Lo Urgente):**
  - Migraciones no versionadas (`H2-02`) + Despliegue manual (`H2-04`) + Configuración divergente (`H2-03`)  
    $\rightarrow$ **El CI no garantiza producción y cada despliegue arriesga la integridad de los datos.**
- **Eje Estructural y de Diseño (Lo Importante):**
  - Organización por portales de actor $\rightarrow$ `administrativos` como falso núcleo (fan-in 16, `H2-06`) $\rightarrow$ Código duplicado (`H2-11`) y ambigüedad de conceptos (`H2-10`).
  - Ausencia de capa de servicios (`H2-07`) $\rightarrow$ Lógica de negocio incrustada en vistas $\rightarrow$ Vistas sobredimensionadas (`H2-12`) difíciles de probar y refactorizar.
- **Conclusión de ingeniería:**  
  *No se puede refactorizar la lógica si la base de datos o los entornos no son reproducibles.*

---

## 4. Radiografía empírica: Deuda técnica medida con datos

Cierre formal de los pendientes (⏳) con la versión definitiva del script de auditoría (`modulo(1).sh`):

| Módulo | Consultas ORM en Vistas | `except:` desnudas | Líneas comentadas (`#`) | Proporción de código muerto |
|---|:---:|:---:|:---:|:---:|
| `profesores` | **118** | 12 | 1 218 de 11 332 | 10.7 % |
| `firma_digital` | **77** | 0 | 353 de 10 175 | 3.5 % |
| `administrativos` | **55** | 14 | 756 de 8 009 | 9.4 % |
| `estudiantes` | **38** | 9 | 621 de 4 551 | 13.6 % |
| `trabajo_final_de_graduacion` | **34** | 0 | 191 de 3 968 | 4.8 % |
| `trabajos_finales` | **2** | 0 | **1 385 de 2 861** | **48.4 % (casi la mitad es residuo)** |

- **Confirmación del vector de riesgo de Pillow (E-093):** Se verificó el uso activo de `ImageField` en 5 aplicaciones (`administrativos`, `laboratorios`, `conferencias`, `inventario`, `anuncios`). Pillow 9.4.0 procesa archivos subidos por usuarios.

---

## 5. El Núcleo del Dominio y el Acoplamiento Circular

- **El nudo gordiano del sistema:**  
  `administrativos` actúa a la vez como portal visual y como contenedor de las entidades institucionales base (`Ciclo`, `Funcionario`, `Roles`, `Lugar`).
  - 16 de las otras 20 aplicaciones importan de `administrativos`.
  - Herencia polimórfica que cruza apps: `Profesor` hereda de `Funcionario`.
- **Ambigüedad conceptual:**
  - Dos modelos `Ciclo`: uno lectivo en `administrativos` y otro de mallas en `cursos` (donde el nombre cambia de significado dentro del mismo archivo).
  - Dos sistemas paralelos de trabajos finales (`trabajos_finales` vs `trabajo_final_de_graduacion`).
  - Dos sistemas de identidad: `User` de Django para funcionarios y contraseñas propias para estudiantes (`E-070`).

---

## 6. Arquitectura Objetivo: Por qué NO microservicios

> *«No se espera un rediseño idealizado ni una reescritura total. Se valorará más una propuesta evolutiva, justificada y viable.»* (Guía del proyecto)

- **¿Por qué NO microservicios?**
  - Equipo pequeño con alta concentración de conocimiento (45 % en un autor).
  - Infraestructura institucional con recursos limitados.
  - Transacciones distribuidas complejas en un dominio académico fuertemente entrelazado.
  - La red y la latencia no son el cuello de botella: lo es el diseño interno.
- **La solución técnica correcta:**  
  **Monolito Modular con Capa de Servicios e Inversión de Dependencias.**

---

## 7. Arquitectura Objetivo: Las Tres Capas

```
┌────────────────────────────────────────────────────────┐
│  1. CAPA DE PRESENTACIÓN (Portales y Vistas Delgadas)  │
│  administrativos, profesores, estudiantes, alumni, etc │
│  (Solo HTTP request/response y validación de permisos) │
└──────────────────────────┬─────────────────────────────┘
                           │ Llama servicios
┌──────────────────────────▼─────────────────────────────┐
│  2. CAPA DE SERVICIOS DE APLICACIÓN (services/)        │
│  ConsejoAsesorService, TFGService, EmailService, etc   │
│  (Lógica de negocio pura, transacciones, desacoplada)  │
└──────────────────────────┬─────────────────────────────┘
                           │ Lee y persiste
┌──────────────────────────▼─────────────────────────────┐
│  3. CAPA DE DOMINIO Y DATOS                            │
│  - core / comun (CicloLectivo, Funcionario, Roles)     │
│  - Apps de dominio acíclicas (cursos, tfg, asistencias)│
│  - MariaDB con migraciones versionadas y controladas   │
└────────────────────────────────────────────────────────┘
```
- **El cambio clave:** `core` no tiene vistas. Resuelve el fan-in 16 hacia `administrativos`.
- **Unificación:** Las 8 funciones duplicadas de consejo asesor se centralizan en un único servicio.

---

## 8. Hoja de Ruta de Evolución: 5 Fases en 12 Meses

```
[Mes 1]               [Meses 2–3]            [Meses 4–6]            [Meses 7–9]            [Meses 10–12]
Fase 1: Mitigación    Fase 2: Red de         Fase 3: Refactor       Fase 4: Modernización  Fase 5: Despliegue
Crítica y Entorno     Seguridad y Linter     Modular y Core         Django 4.2 y Acceso    Continuo y Métricas
  │                      │                      │                      │                      │
  ├─ Rotar secretos      ├─ Tests caracteriz.   ├─ Extraer 'core'      ├─ Subir a Django 4.2  ├─ Drone CD real
  ├─ Baseline migrac.    ├─ Eliminar c. muerto  ├─ Capa de servicios   ├─ Actualizar Pillow   ├─ Quitar sleep 200
  └─ Settings único      └─ Reemplazar except:  └─ Unificar C. Asesor  └─ Permisos estándar   └─ Logging unificado
```

1. **Fase 1 (Mes 1):** Parada de emergencia. Secretos, migraciones y reproducibilidad local.
2. **Fase 2 (Meses 2–3):** Red de seguridad. Pruebas de caracterización, linter y purga de código muerto.
3. **Fase 3 (Meses 4–6):** Refactorización estructural. Extracción de `core` y capa de servicios.
4. **Fase 4 (Meses 7–9):** Modernización tecnológica. Salto a Django 4.2 LTS y unificación de permisos.
5. **Fase 5 (Meses 10–12):** Automatización operativa. Despliegue continuo en Drone y observabilidad.

---

## 9. Intervenciones Prioritarias Inmediatas

| ID | Intervención | Hallazgos que atiende | Esfuerzo | Plazo |
|---|---|---|:---:|:---:|
| **INT-01** | **Higienización de secretos:** Purgar historial Git, rotar credenciales, eliminar CSV y usar variables de entorno. | H2-01 | 1 sem | **Mes 1** |
| **INT-02** | **Línea base de migraciones:** Eliminar `migraciones.sh`, versionar esquema y fijar baseline inicial. | H2-02 | 1 sem | **Mes 1** |
| **INT-03** | **Unificación de configuración:** `settings.py` único (`DEBUG=False` por defecto) y fijación de dependencias. | H2-03, H2-05 | 1 sem | **Mes 1** |
| **INT-04** | **Habilitación de tests locales:** Resolver permisos MySQL (error 1044) y tests de caracterización en flujos clave. | H2-08, H2-12 | 3 sem | **Mes 2** |
| **INT-05** | **Extracción de `core`:** Aislar `CicloLectivo`, `Funcionario` y `Roles` rompiendo el fan-in de `administrativos`. | H2-06, H2-10 | 5 sem | **Meses 4–5** |
| **INT-06** | **Unificación de Consejo Asesor:** Fusionar las 8 funciones duplicadas en `ConsejoAsesorService`. | H2-11, H2-07 | 3 sem | **Meses 5–6** |
| **INT-07** | **Erradicación de código muerto:** Retirar 1 385 líneas comentadas y activar linter `flake8` en CI. | H2-14, H2-16 | 2 sem | **Meses 2–3** |

---

## 10. Modernización de dependencias: Por qué Django 4.2 LTS primero

La consulta oficial a metadatos de PyPI (`E-091`) reveló el techo de compatibilidad:

- **Librerías que soportan Django 6.x:** `django-polymorphic`, `martor`, `sorl-thumbnail`, `django-select2`, `django-countries`, `django-mptt`.
- **El cuello de botella:** `django-sekizai` y `django-classy-tags` (usadas por `django-wiki`) **solo soportan hasta Django 4.2**.
- **Librerías abandonadas que deben eliminarse:**
  - `django-instagram` (abandonada en Django 3.0; el muro de Instagram ya fallaba en silencio).
  - `django-datetime-widget2` (abandonada en 2015; debe pasar a widgets nativos HTML5).
  - `PyPDF2` (no se usa en ningún import del sistema, `E-080`).
- **Conclusión de ingeniería:**  
  La migración debe fijar como hito intermedio **Django 4.2 LTS**, garantizando estabilidad antes de desacoplar el wiki o evaluar Django 5.x.

---

## 11. Gobierno Técnico: Las Reglas del Juego

¿Cómo evitar que el sistema vuelva a degradarse tras el refactor?

1. **Gestión de Secretos:** Cero credenciales en Git. Hooks de pre-commit obligatorios con `gitleaks`.
2. **Definition of Done (DoD):**
   - Cada PR debe incluir pruebas unitarias autosuficientes (sin `dumpdata`).
   - Linter `flake8` pasando sin nuevos comentarios `# noqa`.
   - Cobertura de pruebas no decreciente en CI.
   - Migraciones reversibles y probadas.
3. **Pirámide de Pruebas:**
   - 70 % pruebas unitarias puras en la capa de servicios (`services/`).
   - 25 % integración con base de datos en memoria y factories (`factory_boy`).
   - 5 % pruebas de humo de endpoints en CI.
4. **Revisión Técnica y Trazabilidad:**
   - Revisión por pares (Peer Review) obligatoria para romper silos de conocimiento (`H2-15`).
   - Archivo `.mailmap` para normalizar las 34 identidades de autores.
5. **Documentación:** Adopción de Registros de Decisiones de Arquitectura (ADRs) en `docs/adr/`.

---

## 12. Respuestas a las Preguntas Orientadoras del Curso

1. **¿Qué hacer el primer mes si un equipo nuevo hereda el sistema?**  
   Ejecutar la Fase 1: rotar secretos, fijar baseline de migraciones, unificar settings y hacer que los tests corran localmente.
2. **¿Qué riesgos mitigar de inmediato?**  
   Corrupción de base de datos (`H2-02`), filtración de secretos/contraseñas (`H2-01`) y el riesgo en Pillow por subida de imágenes (`H2-05`, `E-093`).
3. **¿Qué preservar y qué reestructurar?**  
   *Preservar:* La suite y aislamiento de `firma_digital`, el pipeline de Drone y las entidades académicas base.  
   *Reestructurar:* El núcleo de `administrativos` (extrayendo `core`) y las vistas duplicadas de `consejo_asesor`.
4. **¿Cómo evolucionar sin interrumpir la operación?**  
   Mantener el monolito, refactorizar con pruebas de caracterización y usar *Branch by Abstraction* fijando `db_table` en el ORM.
5. **¿Qué gobernanza falta hoy?**  
   Revisión de código formal, linter obligatorio en CI, Definition of Done y trazabilidad de decisiones con ADRs.

---

## 13. Conclusiones y Aprendizajes de Ingeniería

1. **El rigor de la evidencia:** 93 evidencias maestras (`E-001` a `E-093`) permitieron desmontar mitos, dimensionar el código muerto real (4 524 líneas) y verificar vectores de ataque concretos.
2. **Ingeniería evolutiva vs. fantasías de reescritura:** Los sistemas institucionales de 10 años no se rehacen en un fin de semana con microservicios. Se estabilizan primero en la operación y se refactorizan por capas mediante un **Monolito Modular con Capa de Servicios**.
3. **El software es una disciplina socio-técnica:** La deuda técnica de EIEInfo no surgió por incapacidad técnica, sino por falta de gobernanza (linters silenciados, autoría concentrada y ausencia de revisiones). Adoptar reglas claras es la única garantía de futuro.
