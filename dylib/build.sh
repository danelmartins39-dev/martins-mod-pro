#!/bin/bash

# Script de compilação da Dylib LicenseManager
# Requer: Theos, ldid, iOS SDK

set -e

echo "🔨 Compilando LicenseManager Dylib..."

# Verificar se Theos está instalado
if [ -z "$THEOS" ]; then
    echo "❌ THEOS não está definido"
    echo "Configure com: export THEOS=~/theos"
    exit 1
fi

# Ir para o diretório da dylib
cd "$(dirname "$0")"

# Limpar builds anteriores
echo "🧹 Limpando builds anteriores..."
make clean 2>/dev/null || true

# Compilar
echo "⚙️ Compilando..."
make FINALPACKAGE=1

# Verificar se foi compilado com sucesso
if [ -f ".theos/obj/LicenseManager.dylib" ]; then
    echo "✅ Dylib compilada com sucesso!"
    echo "📦 Localização: $(pwd)/.theos/obj/LicenseManager.dylib"
    
    # Copiar para um local mais acessível
    mkdir -p ../build
    cp .theos/obj/LicenseManager.dylib ../build/
    echo "📁 Cópia salva em: $(pwd)/../build/LicenseManager.dylib"
else
    echo "❌ Falha na compilação"
    exit 1
fi

echo ""
echo "🎉 Compilação concluída!"
