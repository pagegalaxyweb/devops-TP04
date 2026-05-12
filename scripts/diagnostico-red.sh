#!/bin/bash

# Entregable 2 - Versión 2: Script con parámetros y validación
HOSTS=$1

# Validación: Si no se pasan parámetros, muestra error y termina
if [ -z "$HOSTS" ]; then
    echo "Error: No se proporcionaron direcciones para probar."
    echo "Uso: ./diagnostico-red.sh \"google.com 8.8.8.8\""
    exit 1
fi

echo "--- Iniciando Diagnóstico de Red V2 ---"
FECHA=$(date +%Y%m%d_%H%M%S)
REPORTE="reports/red_$FECHA.txt"

{
    echo "Reporte generado el: $FECHA"
    echo "-----------------------------------"
    echo "1. Información de Interfaces:"
    ip addr show | grep "inet "
    
    echo -e "\n2. Pruebas de Conectividad (Ping):"
    for host in $HOSTS; do
        echo "Probando conexión con: $host"
        ping -c 2 $host | grep "transmitted"
    done
    
    echo -e "\n3. Puertos en escucha local:"
    ss -tlnp | head -n 5
} > "$REPORTE"

echo "Diagnóstico completado. Archivo generado: $REPORTE"
