#!/usr/bin/env bash

set -u

printf '%s\n' '=== satrOS: wykrywanie CPU ==='

vendor=""
if [[ -r /proc/cpuinfo ]]; then
    vendor="$(awk -F: '/^[[:space:]]*vendor_id[[:space:]]*:/{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit}' /proc/cpuinfo)"
fi

case "$vendor" in
    GenuineIntel)
        printf '%s\n' 'Producent CPU: Intel'
        printf '%s\n' 'Mikrokod: intel-ucode jest obecny w obrazie.'
        ;;
    AuthenticAMD)
        printf '%s\n' 'Producent CPU: AMD'
        printf '%s\n' 'Mikrokod: amd-ucode jest obecny w obrazie.'
        ;;
    "")
        printf '%s\n' 'Nie udało się odczytać producenta CPU; użyj bezpiecznego fallbacku.'
        ;;
    *)
        printf 'Producent CPU: %s (mikrokod nieznany)\n' "$vendor"
        ;;
esac

printf '%s\n' '=== zakończono wykrywanie CPU (bez dynamicznej instalacji mikrokodu) ==='
exit 0
