#!/usr/bin/env bash
# modulo.sh · Datos de un módulo Django para la ficha de auditoría modular (Entrega 2, 7.2)
# Solo lectura: no escribe en el repo y no imprime valores de credenciales.
# Uso, desde la raíz del repo de EIEInfo y con ~/audit-venv activado:
#   bash modulo.sh <app> | cut -c1-160
APP="$1"; SRC=src/server; D="$SRC/$APP"
[ -n "$APP" ] || { echo "Uso: bash modulo.sh <app>   (ejecutar desde la raíz del repo)"; exit 1; }
[ -d "$D" ] || { echo "No existe $D (¿estás en la raíz del repo?)"; exit 1; }

PY=$(find "$D" -name '*.py' -not -path '*/migrations/*')
NOTEST=$(echo "$PY" | grep -vE '/tests?(/|\.py|_)')
VIEWS=$(echo "$PY" | grep -E '/views(/|\.py)')
c() { echo "$NOTEST" | xargs -r grep -hE "$1" 2>/dev/null | grep -vE '^[[:space:]]*#' | wc -l; }  # ignora líneas comentadas

echo "=== $APP ==="
echo "-- Tamaño: $(echo "$PY" | wc -l) archivos .py, $(echo "$PY" | xargs -r cat | wc -l) líneas"
echo "-- Plantillas .html: $(find "$D" -name '*.html' | wc -l) | JS propio: $(find "$D" -name '*.js' | wc -l)"
echo "-- Archivos más grandes:"; echo "$PY" | xargs -r wc -l | sort -rn | sed -n '2,6p'

echo "-- Historial: primer commit $(git log --reverse --format=%ad --date=short -- "$D" | head -1), último $(git log -1 --format=%ad --date=short -- "$D")"
echo "   commits en 12 meses: $(git log --since='12 months ago' --oneline -- "$D" | wc -l) | autores distintos: $(git log --format=%an -- "$D" | sort -u | wc -l)"

echo "-- Modelos: $(echo "$PY" | xargs -r grep -hE '^class \w+\((models\.Model|PolymorphicModel|[A-Za-z_]*Model)\)' | wc -l)"
echo "-- Vistas (def/clase View): $(echo "$VIEWS" | xargs -r grep -hE '^(def [a-z]|class \w+\(.*View)' | wc -l)"
echo "$VIEWS" | xargs -r cat | awk '/^@/{d=1;next} /^def [a-z]/{t++; if(!d)s++; d=0; next} /^(class|def _)/{d=0} END{printf "   vistas-función: %d, sin decorador: %d (heurística, a verificar)\n",t,s}'
echo "-- Decoradores de acceso usados:"
echo "$VIEWS" | xargs -r grep -hE '^[[:space:]]*@\w*login_required' | grep -oE '@\w*login_required\w*' | sort | uniq -c | sort -rn | head -8

echo "-- Imports hacia otras apps (salida):"
for o in $(ls "$SRC"); do
  [ -d "$SRC/$o" ] && [ "$o" != "$APP" ] || continue
  n=$(grep -rhE "^(from|import) $o(\.| )" "$D" --include='*.py' --exclude-dir=migrations | wc -l)
  [ "$n" -gt 0 ] && echo "   -> $o: $n"
done | sort -t: -k2 -rn
echo "-- Apps que importan este módulo (entrada):"
for o in $(ls "$SRC"); do
  [ -d "$SRC/$o" ] && [ "$o" != "$APP" ] || continue
  n=$(grep -rhE "^(from|import) $APP(\.| )" "$SRC/$o" --include='*.py' --exclude-dir=migrations | wc -l)
  [ "$n" -gt 0 ] && echo "   <- $o: $n"
done | sort -t: -k2 -rn

echo "-- Señales de mezcla de responsabilidades (fuera de pruebas):"
echo "   consultas ORM (.objects.)    $(c '\.objects\.')"
echo "   ORM dentro de vistas         $(echo "$VIEWS" | grep -vE '/tests?(/|\.py|_)' | xargs -r grep -hE '\.objects\.' | grep -vE '^[[:space:]]*#' | wc -l)"
echo "   comentarios noqa             $(echo "$PY" | xargs -r grep -hE 'noqa' | wc -l)"
echo "   correo                       $(c 'send_mail|EnviarEmail|enviar_email|EmailMessage')"
echo "   LaTeX, PDF, procesos, disco  $(c 'GenerarLaTeX|pypandoc|subprocess|PyPDF2|open\(')"
echo "   HTTP externo                 $(c 'requests\.|urllib')"
echo "   Excel y reportes             $(c 'openpyxl|xlsxwriter|XlsxWriter|pyexcel|Reporte')"
echo "   respuestas HTTP y render     $(c 'render\(|HttpResponse|JsonResponse')"
echo "   señales (signals)            $(c '@receiver|post_save|pre_save')"
echo "   SQL crudo                    $(c '\.raw\(|cursor\(\)|\.execute\(')"
echo "   csrf_exempt / mark_safe      $(c 'csrf_exempt|mark_safe')"
echo "   except desnudo               $(c 'except\s*:')"
echo "   TODO / FIXME / HACK          $(echo "$NOTEST" | xargs -r grep -hE 'TODO|FIXME|HACK' | wc -l)"
echo "   líneas comentadas (#)        $(echo "$PY" | xargs -r grep -hE '^[[:space:]]*#' | wc -l) de $(echo "$PY" | xargs -r cat | wc -l)"

echo "-- Pruebas: $(echo "$PY" | grep -E '/tests?(/|\.py|_)' | xargs -r grep -hE 'def test_' | wc -l) test_ | saltadas: $(echo "$PY" | xargs -r grep -hE '@skip|skipIf|expectedFailure' | wc -l) | usos de fixtures: $(echo "$PY" | xargs -r grep -hE 'fixtures *=' | wc -l)"

if command -v radon >/dev/null; then
  echo "-- Complejidad (radon, C o peor):"
  radon cc "$D" -s -a -nC -e '*/migrations/*' 2>/dev/null | tail -12
fi
if command -v flake8 >/dev/null; then
  echo "-- flake8 (solo F y E722): $(flake8 "$D" --select=F,E722 -q --count 2>/dev/null | tail -1)"
fi
