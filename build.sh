#!/bin/bash

# Define o canal do Flutter
FLUTTER_CHANNEL="stable"

# Define o diretório onde o Flutter será instalado
FLUTTER_HOME="/opt/flutter"

echo "--- Installing Flutter SDK ---"
mkdir -p "$FLUTTER_HOME"
cd "$FLUTTER_HOME"

if [ ! -d ".git" ]; then
  git clone https://github.com/flutter/flutter.git .
fi

git checkout $FLUTTER_CHANNEL
git pull

# Adicionar o Flutter ao PATH para a sessão atual
export PATH="$PATH:$FLUTTER_HOME/bin"

# Habilitar suporte web
flutter config --enable-web

echo "--- Flutter SDK installation complete ---"
flutter doctor

echo "--- Running pub get ---"
cd /vercel/path0 # Volta para a raiz do seu projeto
flutter pub get

echo "--- Running Flutter Web build ---"
flutter build web --release