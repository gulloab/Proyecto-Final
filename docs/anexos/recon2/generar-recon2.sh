#!/usr/bin/env bash
# generar-recon2.sh · Regenera las salidas crudas de la Entrega 2 (solo lectura; sin credenciales)
# Uso, desde la raíz del clon de EIEInfo y con ~/audit-venv activado:
#   bash generar-recon2.sh RUTA/A/modulo.sh RUTA/DESTINO
# Ejemplo:
#   bash ~/Proyecto-Final/docs/anexos/recon2/generar-recon2.sh ~/Proyecto-Final/docs/anexos/recon2/modulo.sh ~/Proyecto-Final/docs/anexos/recon2
MOD="${1:?Falta la ruta a modulo.sh (versión nueva)}"; OUT="${2:?Falta la carpeta de destino}"
SRC=src/server
[ -d "$SRC" ] || { echo "Ejecuta este script desde la raíz del clon de EIEInfo"; exit 1; }
mkdir -p "$OUT"

# 1) Ficha de cada módulo (E-054 a E-059)
for a in administrativos profesores firma_digital estudiantes trabajo_final_de_graduacion trabajos_finales; do
  bash "$MOD" "$a" 2>&1 | cut -c1-160 > "$OUT/modulo-$a.txt"
done

# 2) Complejidad y estilo (E-034, E-038, E-039)
radon cc "$SRC" -s -nD -e "*/migrations/*" 2>/dev/null > "$OUT/radon-rango-D-E.txt"
flake8 "$SRC" --statistics -qq --count > "$OUT/flake8-estadisticas.txt" 2>&1
flake8 "$SRC" --select=F821,E722 > "$OUT/flake8-F821-E722.txt" 2>/dev/null

# 3) Seguridad estática (E-086) y patrones de riesgo (E-082, E-083)
bandit -r "$SRC" -x "*/migrations/*,*/tests*" -ll -q > "$OUT/bandit.txt" 2>&1
grep -rnE "subprocess|GenerarLaTeX|mark_safe|\|safe|autoescape off|\.raw\(|cursor\(\)|verify=False|pickle|eval\(" "$SRC" \
  --include="*.py" --include="*.html" --exclude-dir=migrations --exclude-dir=static | grep -vE ':[[:space:]]*#' | cut -c1-160 > "$OUT/patrones-de-riesgo.txt"
grep -rn "PyPDF2\|pypdf" "$SRC" --include=*.py | grep -v tests | cut -c1-120 > "$OUT/uso-de-pypdf2.txt"

# 4) Código comentado (E-075, E-076)
{ for f in "$SRC/trabajos_finales/models.py" "$SRC/profesores/views/trabajos_finales.py"; do
    echo "$f: $(grep -cE '^[[:space:]]*#' "$f") líneas comentadas de $(wc -l < "$f")"; done
  grep -rcE "^##" "$SRC" --include=*.py | awk -F: '$2>25' | sort -t: -k2 -rn | head -8
} > "$OUT/codigo-comentado.txt"

# 5) Relaciones entre modelos sin líneas comentadas (E-078)
MODELS="$SRC/administrativos/models.py $SRC/estudiantes/models.py $SRC/profesores/models.py $SRC/cursos/models.py $SRC/trabajo_final_de_graduacion/models.py $SRC/trabajos_finales/models.py $SRC/proyectos/models.py"
awk '/^[[:space:]]*#/{next} /^class /{c=$2; sub(/\(.*/,"",c)} /(ForeignKey|OneToOneField|ManyToManyField)\(/{n[c]++} END{for(k in n) print n[k], k}' $MODELS | sort -rn | head -12 > "$OUT/relaciones-salientes.txt"
awk '/^[[:space:]]*#/{next} /(ForeignKey|OneToOneField|ManyToManyField)\(/{print}' $MODELS | grep -oE '\([A-Za-z_]+' | tr -d '(' | sort | uniq -c | sort -rn | head -12 > "$OUT/relaciones-entrantes.txt"
grep -rhoE "^class \w+" "$SRC"/*/models.py | awk '{print $2}' | sort | uniq -d > "$OUT/modelos-con-nombre-repetido.txt"

# 6) Similitud entre los dos consejo_asesor.py (E-071, E-077)
python3 - > "$OUT/similitud-consejo-asesor.txt" <<'PYEOF'
import ast, difflib
def fns(p):
    s = open(p, encoding="utf-8").read()
    return {n.name: ast.get_source_segment(s, n) for n in ast.parse(s).body if isinstance(n, ast.FunctionDef)}
a = fns("src/server/administrativos/views/consejo_asesor.py"); b = fns("src/server/profesores/views/consejo_asesor.py")
print("funcion lineas_administrativos lineas_profesores similitud")
for k in sorted(set(a) & set(b)):
    print(k, len(a[k].splitlines()), len(b[k].splitlines()), round(difflib.SequenceMatcher(None, a[k], b[k]).ratio(), 2))
PYEOF

# 7) Vulnerabilidades de los paquetes instalados en el contenedor (E-085); requiere Docker levantado
if docker compose exec -T eieinfo_app bash -lc "/home/eieinfo/venv/bin/pip list --format=freeze" > /tmp/docker-reqs.txt 2>/dev/null; then
python3 - > "$OUT/osv-avisos.txt" <<'PYEOF'
import json, urllib.request
pkgs = []
for line in open('/tmp/docker-reqs.txt'):
    if '==' in line:
        name, ver = line.strip().split('==', 1)
        pkgs.append({'package': {'name': name, 'ecosystem': 'PyPI'}, 'version': ver})
req = urllib.request.Request('https://api.osv.dev/v1/querybatch',
    data=json.dumps({'queries': pkgs}).encode(), headers={'Content-Type': 'application/json'})
res = json.loads(urllib.request.urlopen(req).read())
total = 0
for p, r in zip(pkgs, res.get('results', [])):
    v = r.get('vulns') or []
    if v:
        total += len(v)
        print(f"{p['package']['name']}=={p['version']}: {len(v)} avisos: {[x['id'] for x in v]}")
print("TOTAL de identificadores de avisos:", total)
PYEOF
else
  echo "Docker no está levantado: se omite la consulta a OSV (docker compose up -d)" > "$OUT/osv-avisos.txt"
fi

echo "Listo. Revisa $OUT y confirma que ningún archivo contenga credenciales antes de subirlo."
