# recon2 · Salidas crudas de la Entrega 2

Esta carpeta guarda los datos con los que se construyeron los hallazgos. **Todo es de solo lectura y no contiene valores de credenciales.**

## Cómo regenerarlos

Desde la raíz del clon de EIEInfo, con el entorno `~/audit-venv` activado (`radon`, `flake8`, `bandit`) y, para el último paso, Docker levantado:

```bash
bash docs/anexos/recon2/generar-recon2.sh docs/anexos/recon2/modulo.sh docs/anexos/recon2
```

> Ajusta las rutas si el repositorio del curso y el clon de EIEInfo están en carpetas distintas.

## Qué contiene cada archivo y qué evidencia respalda

| Archivo | Contenido | Evidencia |
|---|---|---|
| `modulo.sh` | Script de solo lectura que mide un módulo (versión que ignora las líneas comentadas) | método |
| `modulo-<app>.txt` (6 archivos) | Ficha de `administrativos`, `profesores`, `firma_digital`, `estudiantes`, `trabajo_final_de_graduacion` y `trabajos_finales` | E-054 a E-059 |
| `radon-rango-D-E.txt` | Funciones de complejidad D o E | E-034, E-038 |
| `flake8-estadisticas.txt`, `flake8-F821-E722.txt` | Avisos de estilo y errores graves | E-035, E-039, E-040 |
| `bandit.txt` | Hallazgos de seguridad estática | E-086 |
| `patrones-de-riesgo.txt`, `uso-de-pypdf2.txt` | `mark_safe`, `\|safe`, `autoescape off`, LaTeX; ausencia de imports de PyPDF2 | E-080, E-082, E-083 |
| `codigo-comentado.txt` | Líneas comentadas por archivo | E-075, E-076 |
| `relaciones-salientes.txt`, `relaciones-entrantes.txt`, `modelos-con-nombre-repetido.txt` | Relaciones entre modelos sin líneas comentadas y nombres repetidos (`Ciclo`) | E-065, E-078 |
| `similitud-consejo-asesor.txt` | Similitud textual entre funciones de los dos `consejo_asesor.py` | E-071, E-077 |
| `osv-avisos.txt` | Avisos de vulnerabilidad por paquete (API de OSV) | E-085 |

## Notas para quien revise

- Los archivos `modulo-<app>.txt` generados con la versión **nueva** de `modulo.sh` excluyen las líneas comentadas; las cifras de ORM en vistas y de `except:` de la sección 3 del informe deben actualizarse con ellos (las del informe salen de la versión anterior).
- El error de pruebas del contenedor (`1044 Access denied ... 'test_info'`, E-087) y la salida de `pip list` no se guardan aquí porque dependen del entorno local.
- Los conteos de OSV son identificadores de avisos (GHSA y PYSEC); un mismo problema puede aparecer con dos identificadores.
