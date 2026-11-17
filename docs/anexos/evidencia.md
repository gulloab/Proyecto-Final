# Registro maestro de evidencia (E-001 a E-089)

> Cada afirmación de los informes cita uno o más de estos identificadores. Las salidas crudas están en `docs/anexos/recon2/`. No se reproducen valores de credenciales. Cuando dos entradas tratan lo mismo, la más reciente aclara o reemplaza a la anterior (por ejemplo, E-043 por E-085).

## Entrega 1 (E-001 a E-028)

| ID | Observación |
|---|---|
| E-001 | git HEAD | Commit base `d7c8c1b…` |
| E-002 | `requirements.txt` | Django 4.1.3; dependencias de 2016-2017; forks desde rama; `django-tagging` duplicado |
| E-003 | `docker/django/requirements.txt` | Difiere del de la raíz: `django-wiki` 0.10.1, sin fork de tagging, `pytest` fijado, `django-countries>=7.0` |
| E-004 | `.python-version` | 3.10 (la imagen usa 3.11) |
| E-005 | `recon/03-apps.txt`, `recon/04-py-grandes.txt` | Tamaños por app y archivos grandes |
| E-006 | `recon/03-apps.txt` | Apps sin pruebas o con 34 líneas |
| E-007 | `docker/django/migraciones.sh` | `find … -delete` de migraciones + `makemigrations` + `migrate` |
| E-008 | `.gitignore`; `git ls-files \| grep migrations` | Migraciones ignoradas; 18 archivos `__init__.py` rastreados |
| E-009 | `.drone.yml` | Etapas del pipeline; `deployment` solo ejecuta `git status`; cobertura sobre 11 apps |
| E-010 | `.drone.yml`, paso `notify` | Token de Telegram en texto plano (valor no reproducido) |
| E-011 | `src/server/eieinfo/settings.py:345, 428-429` | Contraseña SMTP y claves de Imgur en texto plano (valores no reproducidos); marcadores de posición en la versión Docker |
| E-012 | `src/server/eieinfo/settings.py:478-493` | Producción solo si `hostname == 'faraday'`; si no, `DEBUG = True` y `ALLOWED_HOSTS = ['*']` |
| E-013 | `git ls-files` | Rastreados: `docker/django/.env`, `docker/django/secret_credentials.py`, dos CSV |
| E-014 | `docker-compose.yml` | Credenciales triviales de BD, puerto 3307, puertos 8000/8001 publicados |
| E-015 | `docker/django/Dockerfile` | `python:buster`, `apt` hacia `archive.debian.org`, reemplazo de `settings.py`, copia de `secret_credentials.py`, `sed` sobre `site-packages` |
| E-016 | `docker/django/run-ut.sh`, `start.sh` | Script local desactualizado (2 apps, `profesores` «Fallan»); `runserver` |
| E-017 | `recon/10-git.txt` | 2567 commits; autor con 1160; archivos con más cambios; último commit por carpeta |
| E-018 | `ls src/server`; `eieinfo/urls.py` | 21 apps; 3 sin montar; `eieinfo_uwsgi.ini`; prefijos de URL |
| E-019 | Matriz de imports entre apps | Fan-in/fan-out; más de 25 pares con dependencia mutua |
| E-020 | `recon/08-auth.txt` | 5 decoradores de rol en `administrativos/misc.py` |
| E-021 | `src/server/eieinfo/settings.py` (CRONJOBS) | Dos tareas horarias de limpieza |
| E-022 | `.drone.yml` | Socket de Docker montado, `sleep 200`, seis URL desactivadas |
| E-023 | `docker/django/.env`, `secret_credentials.py` (nombres de variables, valores redactados) | BD, superusuario, `SECRET_KEY`, correo, claves de Google, token de Facebook, reCAPTCHA |
| E-024 | `diff src/server/eieinfo/settings.py docker/django/settings.py` | 16 bloques de diferencias; faltan ajustes de `firma_digital`; `DEBUG = True` y cookies no seguras en la versión Docker |
| E-025 | `docker/nginx/default.conf` | Sin TLS, 20 MB, no fija `X-Forwarded-Proto`; `/media/tfg/` denegado, `/media/` público |
| E-026 | `grep "def .*login_required"` | `profesores` 11, `estudiantes` 1, `alumni` 1, `inventario` 1, `trabajos_finales` 1 decoradores propios |
| E-027 | `grep` de imports de `eieinfo` y `webpage` | Utilidades compartidas en `webpage.misc` y `eieinfo.misc`; import directo de `eieinfo.settings` |
| E-028 | `head -1 src/server/OwncloudProfesores.csv` | Cabecera con columnas Nombre, Apellidos, Usuario, Contraseña |

## Entrega 2 · pendientes y métricas globales (E-029 a E-045)

| ID | Observación |
|---|---|
| E-029 | `OwncloudProfesores.csv`: 15 líneas; las 14 filas tienen la columna de contraseña llena (refinado en E-037) |
| E-030 | `docker/django/.env`: longitudes de 4 a 9 caracteres en las credenciales de base de datos y de superusuario (valores no reproducidos) |
| E-031 | `docker/django/secret_credentials.py`: valores de ≈16 caracteres (clave de Django, Google, reCAPTCHA) y ≈26 (Facebook); parecen de desarrollo, no se validaron |
| E-032 | Imports de `administrativos`: modelos (`Ciclo`, `Roles`, `Funcionario`, `Comision`, `Lugar`…), utilidades y vistas |
| E-033 | `MAX_PDF_SIZE`, `FIRMA_DIGITAL_UPLOAD_PATH` y `FIRMADOR_LIBRE_PORT` no se leen fuera de `settings.py` |
| E-034 | `radon`: 55 bloques con complejidad ≥ 11, promedio 16,9; picos de 39, 33, 25 y 23 (ver E-038) |
| E-035 | `flake8`: 4403 avisos; sin paso de lint en `.drone.yml` (ver E-039) |
| E-036 | 22 advertencias de secuencias de escape inválidas (ver E-042) |
| E-037 | CSV de profesores: 14 filas, todas con contraseña de 8 caracteres y todas distintas (no es una clave por defecto repetida) |
| E-038 | `radon -nD`: 12 funciones de rango D o E (`enviar_email` 39, `editar_grupo` 33, `enviar_revision_propuesta_tfg` 29, `_emparejar_firmado` 28…); `resumen_ciclo` aparece en dos apps con complejidad 25 |
| E-039 | `flake8`: 4403 avisos (1648 E266, 1294 E501); F401 81, F811 26, F841 8, E722 7 |
| E-040 | `administrativos/templatetags/misc_tags.py:121-122`: `get_profile_media` sin definir dentro de un `try` con `except:` sin tipo |
| E-041 | `alumni/admin.py:5, 28`: clase `AlumnusAdmin` definida dos veces |
| E-042 | 22 escapes inválidos en 12 archivos (9 en `estudiantes/forms.py`); la regla W605 está ignorada en `.flake8` |
| E-043 | `pip-audit` (salida parcial): Pillow 9.4.0 con 26 avisos; gunicorn 20.1.0 y PyPDF2 1.26.0 con 2 cada uno (reemplazado por E-085) |
| E-044 | Puerto 3516 fijo en `firmador_autor.js:26` y `firma_digital/base.html:83`; `FIRMADOR_LIBRE_PORT` y `MAX_PDF_SIZE` sin uso |
| E-045 | `eieinfo/static/bootstrap/bower_components/flot/examples/`: bibliotecas de terceros y ejemplos versionados |

## Entrega 2 · línea base y auditoría modular (E-046 a E-060)

| ID | Observación |
|---|---|
| E-046 | Línea base de `src/server`: 260 archivos `.py`, 59 402 líneas; 735 `.html` y 1401 `.js` (incluye terceros); 102 modelos; 429 vistas; 1165 pruebas, 0 saltadas; 171 commits en 12 meses; 34 nombres de autor |
| E-047 | Decoradores de acceso en vistas: ≈207 usos (estudiante 45, admin 45, profesor 39, consejo asesor 34…); el conteo incluía líneas comentadas |
| E-048 | Heurística: 93 de 334 vistas-función sin decorador (por verificar; incluye vistas públicas y auxiliares) |
| E-049 | Mezcla de responsabilidades (todo el código sin pruebas): 859 consultas ORM, 502 respuestas HTTP, 102 de correo, 53 de reportes, 34 de LaTeX, PDF o procesos; conteo con la versión de `modulo.sh` que incluía líneas comentadas |
| E-050 | Imports relativos por app: `trabajo_final_de_graduacion` 15, `solicitud_documentos_externo` 14, `firma_digital` 8; las apps antiguas casi ninguno |
| E-051 | Referencias a apps (incluye internas y pruebas): `administrativos` 134, `profesores` 83, `estudiantes` 65, `cursos` 49 |
| E-052 | 52 `except:` sin tipo por búsqueda de texto frente a 7 reportados por flake8 (explicado en E-053) |
| E-053 | `.flake8` ignora D203, E731, W503, W504 y W605, y excluye `settings.py`, `static` y `scripts`. Los 52 `except:` sin tipo se descomponen en 42 con `# noqa`, 7 reportados y 3 en `scripts/` |
| E-054 | `recon2/mod-administrativos.txt` (salida de `modulo.sh`) |
| E-055 | `recon2/mod-profesores.txt` |
| E-056 | `recon2/mod-firma_digital.txt` |
| E-057 | `recon2/mod-estudiantes.txt` |
| E-058 | `recon2/mod-trabajo_final_de_graduacion.txt` |
| E-059 | `recon2/mod-trabajos_finales.txt` |
| E-060 | `administrativos/views/gestion_inventario.py:15-16`: el decorador del rol de inventario se importa con el alias `login_required` |

## Entrega 2 · dominio (E-061 a E-079)

| ID | Observación |
|---|---|
| E-061 | Jerarquías con `PolymorphicModel`: 6 raíces y 15 subclases; `Profesor(Funcionario)` cruza de `profesores` a `administrativos` |
| E-062 | `administrativos/templatetags/misc_tags.py:121-123`: `get_profile_media` sin definir dentro de un `try` con `except:` sin tipo; el muro de Instagram siempre devuelve una lista vacía |
| E-063 | `firma_digital/views.py`: `LoginRequiredMixin` en vistas de clase (líneas 497, 1379, 1618, 1663, 1719, 1789, 2060, 2112, 2590, 2634) y un mixin propio (línea 54). `csrf_exempt` solo aparece en un comentario (`views.py:1274`) y en una prueba que exige el token (`tests.py:4947`) |
| E-064 | Más de 120 relaciones entre siete módulos, contadas con líneas comentadas incluidas; recalculadas en E-078 (entrantes sin comentarios: `Profesor` 12, `Ciclo` 12, `Funcionario` 10, `Estudiante` 10) |
| E-065 | `Ciclo` definido en `administrativos` y en `cursos`; alias `admin_ciclo` en los imports |
| E-066 | `trabajos_finales` (6 modelos) y `trabajo_final_de_graduacion` (8) con estructura paralela |
| E-067 | `estudiantes/models.py`: `Asistencia` (línea 350) y 5 subtipos (454-613); `RequisitosGraduacion` (1184) y 2 subtipos |
| E-068 | Parejas de conceptos divididas: `CambioEnfasis`/`ConfirmarCambioEnfasis`; `CambioContraseñaFuncionario`/`RecuperacionContraseña`/`VerificacionEstudiante` |
| E-069 | `trabajos_finales/misc.py:34`: definición de `tfg_login_required` comentada (⏳ las 3 vistas de `profesores` que la usan) |
| E-070 | `estudiantes/models.py`: `Estudiante` con campo `contraseña` propio y `SetPassword` con `make_password` y sal propia (≈ líneas 122 y 172); sin relación con el `User` de Django |
| E-071 | `resumen_ciclo` en `administrativos/views/consejo_asesor.py` y `profesores/views/consejo_asesor.py`: 158 líneas cada una, similitud 1.0 |
| E-072 | `profesores/views/trabajos_finales.py:20, 677, 703, 795`: import y decorador `tfg_login_required` comentados; definición comentada en `trabajos_finales/misc.py:34` |
| E-073 | `flake8` en `trabajo_final_de_graduacion`: 35 F401, 16 F811, 4 F841 y 1 F541 |
| E-074 | `cursos/models.py`: `Ciclo` importado (línea 3), alias `AdminCiclo` (línea 12) y clase local `Ciclo` (línea 834); los demás módulos importan `Ciclo` de `administrativos` |
| E-075 | `trabajos_finales/models.py`: clase `TrabajoFinalGraduacion` y sus usos comentados (líneas 706, 824, 1188, 1272); las relaciones de esas líneas se contaron por error en E-064 |
| E-076 | Código comentado con `##`: `trabajos_finales/models.py` 596 (685 líneas con `#` de 1313), `trabajos_finales/forms.py` 486, `profesores/views/trabajos_finales.py` 461 (475 de 978), `estudiantes/views/trabajos_finales.py` 200, `trabajos_finales/reports.py` 59, `profesores/urlpatterns/tfg.py` 56, `trabajos_finales/views.py` 44, `estudiantes/urlpatterns/tfg.py` 40: ≈1942 líneas |
| E-077 | Funciones con el mismo nombre en los dos `consejo_asesor.py`: 8 con similitud de 0.95 a 1.0 (`resumen_ciclo` 158 líneas, `consolidacion_aulas` 65, `nombramientos_interinos` 42, `nombramientos_continuidad` 35, `grupos` 20, `proyectos` 12, `descargar_reporte_ciclo` 9, `ObtenerCiclo` 7): 348 de las 437 líneas del archivo de `administrativos` |
| E-078 | Relaciones salientes sin líneas comentadas: `ProyectoElectrico` 9, `Grupo` 6, `TFG` 5, `LugarCiclo` 5, `ComisionCiclo` 5, `ProyectoCiclo` 4, `DelegacionDirector` 4, `ConcursarAsistencia` 4, `Catedra` 4, `Asistencia` 4 |
| E-079 | `estudiantes/models.py` (`SetPassword`): sal con `uuid.uuid4().hex` y `make_password(..., 'pbkdf2_sha256')`; el docstring dice «para un Funcionario» (copiado). `trabajo_final_de_graduacion/forms.py`, líneas 3 a 7 y 426: imports repetidos (F811) |

## Entrega 2 · seguridad, pruebas y operación (E-080 a E-089)

| ID | Observación |
|---|---|
| E-080 | `grep` de `PyPDF2` y `pypdf` en `src/server` (sin pruebas): sin resultados; la dependencia no se importa |
| E-081 | `git ls-remote https://github.com/rodrigo-garcia-leon/django-wiki.git`: «Repository not found» (inexistente o privado) |
| E-082 | `{% autoescape off %}` en `administrativos/templates/…` (`home.html:257`, `publico/administrativo.html:56`, `publico/index.html:12`, `noticias/anuncio.html:56`, `noticias/evento.html:59`, `consejo_asesor/ciclo.html:102`, `emails/asistencias_pendientes.html:8`); `\|safe` en `profesores/.../asistencias_profesor.html:81` y `administrativos/.../modificar_reserva_especial.html:54` |
| E-083 | 4 plantillas `.tex` (`cursos/templates/cursos/latex/` ×3 y `estudiantes/templates/estudiantes/latex/CartaPracticaProfesional.tex`); `GenerarLaTeX` (`eieinfo/misc.py:139`) renderiza plantillas de Django y ejecuta `pdflatex` con lista de argumentos, sin shell; se usa desde `cursos/misc.py:24`, `cursos/models.py:412` y `estudiantes/models.py:1008` |
| E-084 | `webpage/models.py:7`: `Texto` almacena la información estática de la Escuela (nombre único, título y contenido) |
| E-085 | OSV sobre los paquetes instalados en Docker: 143 avisos en 9 paquetes (Pillow 87, Django 30, setuptools 9, gunicorn 4, PyPDF2 4, soupsieve 3, django-select2 2, Markdown 2, pytest 2) |
| E-086 | `bandit` (29 234 líneas): 0 altos, 7 medios (`mark_safe` en 3 ubicaciones, reportado por dos reglas, y `urlopen` en `eieinfo/GoogleAPI.py:52`) y 24 bajos |
| E-087 | Pruebas: Django detecta 530 (456 + 74); error 1044 para `test_info`; 12 archivos con `mock` o `patch`; 38 usos de `fixtures =` |
| E-088 | `settings.py:239` y `:502` (dos definiciones de `LOGGING`); 17 `print()` fuera de pruebas |
| E-089 | `firma_digital/views.py:45-52`: el mixin `ProfesorOAdminLoginRequired` verifica `prof_id` o `admn_id` en la sesión |
