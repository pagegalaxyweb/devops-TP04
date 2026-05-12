#!/bin/bash

# Lee el YAML y verifica que los hosts de cada entorno sean alcanzables

CONFIG="$(cd "$(dirname "$0")/.." && pwd)/config/app-config.yml"

echo "=== Verificación de configuración app-config.yml ==="
echo ""

python3 - << PYEOF
import yaml

with open("$CONFIG") as f:
    cfg = yaml.safe_load(f)

print("Entornos configurados:")
for env, data in cfg['environments'].items():
    host   = data['server']['host']
    port   = data['server']['port']
    debug  = data['debug']
    reps   = data['replicas']
    cache  = data.get('cache', {}).get('enabled', False)
    print(f"  {env:12} → host={host:25} port={port}  replicas={reps}  debug={str(debug):5}  cache={cache}")

print()
print("Scripts programados:")
for s in cfg['scripts']:
    print(f"  {s['name']:25} cron: {s['schedule']:15} timeout: {s['timeout_seconds']}s")
PYEOF
