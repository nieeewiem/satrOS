#!/bin/bash
set -e

echo "=== OrionOS: Wykrywanie sprzętu GPU ==="

GPU_INFO=$(lspci | grep -E "VGA|3D|Display")
PACKAGES=()

if echo "$GPU_INFO" | grep -iq "nvidia"; then
    echo "-> Wykryto kartę NVIDIA"
    PACKAGES+=(nvidia-open nvidia-utils lib32-nvidia-utils vulkan-icd-loader lib32-vulkan-icd-loader)
fi

if echo "$GPU_INFO" | grep -iq "amd\|radeon"; then
    echo "-> Wykryto układ AMD"
    PACKAGES+=(xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon)
fi

if echo "$GPU_INFO" | grep -iq "intel"; then
    echo "-> Wykryto układ Intel"
    PACKAGES+=(vulkan-intel lib32-vulkan-intel)
fi

if [ ${#PACKAGES[@]} -gt 0 ]; then
    echo "Instalacja pakietów: ${PACKAGES[*]}"
    pacman -S --noconfirm --needed "${PACKAGES[@]}"
else
    echo "Nie wykryto wspieranych układów GPU."
fi

echo "=== Konfiguracja GPU zakończona ==="
