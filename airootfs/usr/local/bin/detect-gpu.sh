#!/usr/bin/env bash

# Report hardware only.  Installing a kernel module while Calamares is
# running can break the live session, so package selection remains explicit.
set -u

strict=0
if [[ "${1:-}" == "--strict" ]]; then
    strict=1
fi

printf '%s\n' '=== satrOS: wykrywanie GPU ==='

if ! command -v lspci >/dev/null 2>&1; then
    printf '%s\n' 'Nie znaleziono lspci (pakiet pciutils); GPU nieznane.'
    (( strict )) && exit 2
    exit 0
fi

mapfile -t gpu_lines < <(lspci -D 2>/dev/null | grep -Ei 'VGA compatible controller|3D controller|Display controller' || true)

if ((${#gpu_lines[@]} == 0)); then
    printf '%s\n' 'Nie wykryto kontrolera grafiki PCI (GPU nieznane lub niedostępne).'
    (( strict )) && exit 2
    exit 0
fi

detected=0
for line in "${gpu_lines[@]}"; do
    ((detected += 1))
    printf 'GPU: %s\n' "$line"
    case "$line" in
        *NVIDIA*|*nvidia*) printf '%s\n' 'Producent: NVIDIA (sterownik do wyboru podczas instalacji)' ;;
        *AMD*|*ATI*|*Radeon*|*AMD/ATI*) printf '%s\n' 'Producent: AMD (sterownik otwarty)' ;;
        *Intel*|*INTEL*) printf '%s\n' 'Producent: Intel (sterownik otwarty)' ;;
        *VirtualBox*|*VMware*|*Virtio*|*QXL*|*Bochs*|*Red\ Hat*|*Microsoft*) printf '%s\n' 'Typ: wirtualne GPU' ;;
        *) printf '%s\n' 'Producent: nieznany (użyj bezpiecznego fallbacku kernela)' ;;
    esac
done

printf 'Liczba kontrolerów GPU: %d\n' "$detected"
printf '%s\n' '=== zakończono wykrywanie GPU (bez instalacji sterowników) ==='
exit 0
