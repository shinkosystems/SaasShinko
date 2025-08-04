#!/bin/bash

# Define a versão do Flutter que você quer usar
FLUTTER_VERSION="3.22.4" # Use a versão exata que você tem localmente ou uma versão estável
FLUTTER_CHANNEL="stable"

# Define o diretório onde o Flutter será instalado
FLUTTER_HOME="/opt/flutter"

echo "--- Installing Flutter SDK ---"

# Criar o diretório de instalação se não existir
mkdir -p "$FLUTTER_HOME"
cd "$FLUTTER_HOME"

# Clonar o repositório do Flutter
git clone https://github.com/flutter/flutter.git .

# Fazer checkout da versão e branch desejados
git checkout $FLUTTER_CHANNEL
git pull
git checkout $FLUTTER_VERSION

# Adicionar o Flutter ao PATH para a sessão atual
export PATH="$PATH:$FLUTTER_HOME/bin"

# Rodar flutter doctor --android-licenses se necessário (para mobile, geralmente não para web)
# flutter doctor --android-licenses

# Habilitar suporte web
flutter config --enable--web

echo "--- Flutter SDK installation complete ---"
flutter doctor