#!/bin/bash

# Define o canal do Flutter
FLUTTER_CHANNEL="stable"
FLUTTER_VERSION="3.22.4" # Versão exata que você está usando localmente

# Define o diretório onde o Flutter será instalado
FLUTTER_HOME="/opt/flutter"

echo "--- Installing Flutter SDK ---"

# Baixar e extrair o Flutter SDK
git clone --depth 1 -b $FLUTTER_CHANNEL https://github.com/flutter/flutter.git "$FLUTTER_HOME"

# Adicionar o Flutter ao PATH para a sessão atual
export PATH="$PATH:$FLUTTER_HOME/bin"

# Fazer o checkout da versão específica
cd "$FLUTTER_HOME"
git checkout tags/v$FLUTTER_VERSION

# Habilitar suporte web
flutter config --enable-web

echo "--- Flutter SDK installation complete ---"
flutter doctor --web

echo "--- Running pub get ---"
cd /vercel/path0
flutter pub get

echo "--- Running Flutter Web build with Environment Variables ---"
flutter build web --release \
  --dart-define=SUPABASE_URL="https://rquhueanhjdozuhielag.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJxdWh1ZWFuaGpkb3p1aGllbGFnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3MjQ2MzMsImV4cCI6MjA2OTMwMDYzM30.kXkdpa6I7KnknyyAvdu1up2DEHyBC1-hy9BaYgKag4k"