#!/bin/bash

# ============================================
# diagnostico-red.sh — Reporte de conectividad
# TP04 — Operaciones1
# ============================================

set -uo pipefail

FECHA=$(date +"%Y-%m-%d_%H-%M-%S")
REPORTE_DIR="$(cd "$(dirname "$0")/.." && pwd)/reports"
REPORTE="$REPORTE_DIR/red_$FECHA.txt"
HOSTS_TEST="${1:-google.com 8.8.8.8 github.com}"

mkdir -p "$REPORTE_DIR"

log()  { echo "$1" | tee -a "$REPORTE"; }
ok()   { echo "  [OK]   $1" | tee -a "$REPORTE"; }
warn() { echo "  [WARN] $1" | tee -a "$REPORTE"; }
fail() { echo "  [FAIL] $1" | tee -a "$REPORTE"; }
sep()  { echo "------------------------------------------------" | tee -a "$REPORTE"; }

log "================================================"
log "  REPORTE DE DIAGNÓSTICO DE RED — $FECHA"
log "================================================"
log ""

# ── 1. Interfaces de red ──────────────────────────────────
log "--- 1. INTERFACES DE RED ---"
if command -v ip &>/dev/null; then
    ip addr show | grep -E "^[0-9]+:|inet " | tee -a "$REPORTE"
else
    ifconfig 2>/dev/null | tee -a "$REPORTE"
fi
log ""

# ── 2. Tabla de rutas ─────────────────────────────────────
log "--- 2. TABLA DE RUTAS ---"
ip route show | tee -a "$REPORTE"
log ""

# ── 3. DNS ────────────────────────────────────────────────
log "--- 3. CONFIGURACIÓN DNS ---"
cat /etc/resolv.conf | grep -v "^#" | tee -a "$REPORTE"
log ""

# ── 4. Ping a hosts de prueba ─────────────────────────────
log "--- 4. CONECTIVIDAD (PING) ---"
for host in $HOSTS_TEST; do
    if ping -c 2 -W 3 "$host" &>/dev/null; then
        latencia=$(ping -c 2 -W 3 "$host" | tail -1 | awk -F '/' '{print $5}' 2>/dev/null || echo "?")
        ok "$host — alcanzable (latencia avg: ${latencia}ms)"
    else
        fail "$host — no responde a ping"
    fi
done
log ""

# ── 5. Resolución DNS ─────────────────────────────────────
log "--- 5. RESOLUCIÓN DNS ---"
for host in $HOSTS_TEST; do
    if echo "$host" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
        ok "$host — es una IP, no requiere DNS"
        continue
    fi
    ip_resuelto=$(dig +short "$host" 2>/dev/null | head -1)
    if [ -n "$ip_resuelto" ]; then
        ok "$host → $ip_resuelto"
    else
        fail "$host — no se pudo resolver"
    fi
done
log ""

# ── 6. HTTP check ─────────────────────────────────────────
log "--- 6. SERVICIOS HTTP ---"
for host in $HOSTS_TEST; do
    if echo "$host" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
        continue
    fi
    codigo=$(curl -o /dev/null -s -w "%{http_code}" \
             --max-time 5 "https://$host" 2>/dev/null || echo "000")
    if [[ "$codigo" =~ ^[23] ]]; then
        ok "https://$host → HTTP $codigo"
    elif [ "$codigo" = "000" ]; then
        fail "https://$host → sin respuesta (timeout o sin HTTPS)"
    else
        warn "https://$host → HTTP $codigo"
    fi
done
log ""

# ── 7. Puertos locales abiertos ───────────────────────────
log "--- 7. PUERTOS LOCALES EN ESCUCHA ---"
ss -tlnp 2>/dev/null | grep LISTEN | tee -a "$REPORTE" || \
    netstat -tlnp 2>/dev/null | grep LISTEN | tee -a "$REPORTE" || \
    warn "ss y netstat no disponibles"
log ""

# ── 8. Resumen ────────────────────────────────────────────
sep
ok_count=$(grep -c "\[OK\]" "$REPORTE" 2>/dev/null || echo 0)
fail_count=$(grep -c "\[FAIL\]" "$REPORTE" 2>/dev/null || echo 0)
warn_count=$(grep -c "\[WARN\]" "$REPORTE" 2>/dev/null || echo 0)

log "RESUMEN: $ok_count OK  |  $warn_count WARN  |  $fail_count FAIL"
log "Reporte guardado en: $REPORTE"
sep

