#!/usr/bin/env bash
# recon.sh — Reconocimiento inicial de un repo Django para la Entrega 1 (IE0417)
# Uso: desde la raíz del repo auditado:  bash recon.sh
# Genera docs/anexos/recon/*.txt con datos crudos que luego citas como evidencia.

set -u
OUT="docs/anexos/recon"
mkdir -p "$OUT"

echo "== Commit auditado ==" | tee "$OUT/00-commit.txt"
git rev-parse HEAD 2>/dev/null | tee -a "$OUT/00-commit.txt"
git log -1 --format='%ad | %an | %s' 2>/dev/null | tee -a "$OUT/00-commit.txt"

# 1. Estructura
{ echo "== Árbol (3 niveles) =="; 
  find . -maxdepth 3 -not -path './.git*' -not -path '*/node_modules*' -not -path '*/__pycache__*' | sort
} > "$OUT/01-arbol.txt"

# 2. Tamaño por lenguaje
if command -v cloc >/dev/null; then
  cloc . --exclude-dir=.git,node_modules,venv,.venv,staticfiles > "$OUT/02-cloc.txt"
else
  { echo "(cloc no instalado; conteo básico)";
    for ext in py html js css sql yml yaml sh; do
      n=$(find . -name "*.$ext" -not -path './.git/*' -not -path '*/node_modules/*' -print0 | xargs -0 cat 2>/dev/null | wc -l)
      echo "$ext: $n líneas"
    done
  } > "$OUT/02-cloc.txt"
fi

# 3. Apps Django: tamaño de views/models/forms/tests y migraciones
{
  echo "== Por app: líneas de models/views/forms/tests y nº de migraciones =="
  printf "%-28s %8s %8s %8s %8s %6s\n" APP models views forms tests migr
  for d in $(find . -name apps.py -not -path './.git/*' -not -path '*/node_modules/*' -exec dirname {} \; | sort); do
    cnt() { f=0; for p in "$@"; do [ -e "$d/$p" ] && f=$((f + $(find "$d/$p" -name '*.py' -print0 2>/dev/null | xargs -0 cat 2>/dev/null | wc -l))); done; echo $f; }
    mig=$(find "$d/migrations" -name '0*.py' 2>/dev/null | wc -l)
    printf "%-28s %8s %8s %8s %8s %6s\n" "$d" "$(cnt models.py models)" "$(cnt views.py views)" "$(cnt forms.py forms)" "$(cnt tests.py tests)" "$mig"
  done
} > "$OUT/03-apps.txt"

# 4. Archivos .py más grandes
{ echo "== 25 archivos .py más grandes =="; 
  find . -name '*.py' -not -path '*/migrations/*' -not -path './.git/*' -not -path '*/venv/*' -not -path '*/.venv/*' -print0 | xargs -0 wc -l | sort -rn | head -26
} > "$OUT/04-py-grandes.txt"

# 5. Settings y URLs
{ echo "== INSTALLED_APPS / DATABASES / settings =="; 
  grep -rn "INSTALLED_APPS\|DATABASES\|ENGINE\|ALLOWED_HOSTS\|DEBUG\|SECRET_KEY\|MIDDLEWARE\|LOGGING\|EMAIL_" --include='*.py' . 2>/dev/null | grep -i "settings" | head -80
  echo; echo "== include() de URLs =="; 
  grep -rn "include(" --include='urls.py' . 2>/dev/null
} > "$OUT/05-settings-urls.txt"

# 6. Dependencias, Docker, CI/CD
{ echo "== Archivos de dependencias =="; ls -la requirements* pyproject.toml Pipfile* setup.py package.json 2>/dev/null
  for f in requirements*.txt; do [ -f "$f" ] && { echo "--- $f"; cat "$f"; }; done
  echo; echo "== Docker / compose =="; find . -maxdepth 3 \( -iname 'Dockerfile*' -o -iname 'docker-compose*' -o -iname '*.dockerfile' \) -not -path './.git/*'
  echo; echo "== CI/CD =="; find . -path ./.git -prune -o \( -path './.github/workflows/*' -o -name '.gitlab-ci.yml' -o -name 'Jenkinsfile' \) -print
  echo; echo "== Scripts de despliegue =="; find . -maxdepth 3 \( -iname 'deploy*' -o -iname '*.sh' \) -not -path './.git/*'
} > "$OUT/06-deps-docker-ci.txt"

# 7. Integraciones externas visibles
{ echo "== Posibles integraciones externas =="; 
  grep -rniE "requests\.(get|post)|urllib|smtplib|EMAIL_HOST|ldap|oauth|saml|boto3|s3|redis|celery|sentry|http(s)?://[a-z0-9.-]+" --include='*.py' --include='*.yml' --include='*.yaml' --include='*.env*' . 2>/dev/null | grep -v "/migrations/" | head -120
} > "$OUT/07-integraciones.txt"

# 8. Roles y permisos
{ echo "== Autenticación y permisos =="; 
  grep -rnE "login_required|permission_required|user_passes_test|PermissionRequiredMixin|LoginRequiredMixin|is_staff|is_superuser|Group\b|has_perm|csrf_exempt" --include='*.py' . 2>/dev/null | grep -v "/migrations/" | head -150
} > "$OUT/08-auth.txt"

# 9. Olores rápidos de seguridad/calidad (puntos de partida, NO hallazgos aún)
{ echo "== Olores rápidos (verificar uno por uno) =="; 
  echo "-- Secretos / credenciales:"; grep -rnEi "(password|passwd|secret|token|api_key)\s*=\s*['\"][^'\"]+['\"]" --include='*.py' --include='*.yml' --include='*.env*' --include='*.sh' . 2>/dev/null | grep -v "/migrations/" | head -40
  echo "-- .env versionados:"; git ls-files | grep -E "(^|/)\.env" 
  echo "-- SQL crudo:"; grep -rnE "\.raw\(|cursor\(\)|\.execute\(" --include='*.py' . 2>/dev/null | grep -v "/migrations/" | head -30
  echo "-- TODO/FIXME/HACK:"; grep -rnE "TODO|FIXME|HACK|XXX" --include='*.py' . 2>/dev/null | wc -l
  echo "-- Bloques except genérico:"; grep -rnE "except\s*:|except Exception" --include='*.py' . 2>/dev/null | wc -l
} > "$OUT/09-olores.txt"

# 10. Actividad en git
if git rev-parse --git-dir >/dev/null 2>&1; then
  { echo "== Nº commits =="; git rev-list --count HEAD
    echo; echo "== Primer y último commit =="; git log --reverse --format='%ad %s' --date=short | head -1; git log -1 --format='%ad %s' --date=short
    echo; echo "== Autores =="; git shortlog -sn --no-merges | head -15
    echo; echo "== 25 archivos más modificados (churn) =="; git log --name-only --pretty=format: | grep -v '^$' | sort | uniq -c | sort -rn | head -25
    echo; echo "== Último commit por directorio de 1er nivel =="
    for d in $(find . -maxdepth 1 -mindepth 1 -type d -not -name '.git*' | sort); do
      printf "%-30s %s\n" "$d" "$(git log -1 --format='%ad' --date=short -- "$d" 2>/dev/null)"
    done
  } > "$OUT/10-git.txt"
fi

# 11. Pruebas
{ echo "== Archivos de prueba =="; find . \( -name 'test*.py' -o -name '*_test.py' -o -name 'tests' \) -not -path './.git/*' -not -path '*/venv/*' | sort
  echo; echo "== Nº de funciones test =="; grep -rE "def test_" --include='*.py' . 2>/dev/null | wc -l
} > "$OUT/11-pruebas.txt"

echo; echo "Listo. Revisa $OUT/ y registra lo relevante en docs/anexos/evidencia.md"
