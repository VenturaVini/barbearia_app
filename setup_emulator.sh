#!/bin/bash

# Script para configurar port forwarding no emulador Android
# Permite que o emulador acesse o backend Django rodando no host

echo "🔧 Configurando port forwarding para emulador..."

# Caminho do ADB
ADB="$HOME/Library/Android/sdk/platform-tools/adb"

# Verificar se ADB existe
if [ ! -f "$ADB" ]; then
    echo "❌ ADB não encontrado em: $ADB"
    echo "   Instale o Android SDK ou ajuste o caminho"
    exit 1
fi

# Verificar se há dispositivo conectado
DEVICES=$($ADB devices | grep -v "List" | grep "device" | wc -l)
if [ $DEVICES -eq 0 ]; then
    echo "❌ Nenhum dispositivo/emulador conectado"
    echo "   Inicie o emulador primeiro"
    exit 1
fi

# Configurar reverse port forwarding
echo "📱 Configurando acesso ao backend (porta 7891)..."
$ADB reverse tcp:7891 tcp:7891

if [ $? -eq 0 ]; then
    echo "✅ Port forwarding configurado com sucesso!"
    echo ""
    echo "Agora o emulador pode acessar:"
    echo "  http://localhost:7891 → seu Mac na porta 7891"
    echo ""
    echo "Para testar, rode o app Flutter e faça login"
else
    echo "❌ Erro ao configurar port forwarding"
    exit 1
fi
