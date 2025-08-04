#!/bin/bash

# Define o canal do Flutter
FLUTTER_CHANNEL="stable"

# Define o diretório onde o Flutter será instalado
FLUTTER_HOME="/opt/flutter"

echo "--- Installing Flutter SDK ---"

# Criar o diretório de instalação se não existir
mkdir -p "$FLUTTER_HOME"
cd "$FLUTTER_HOME"

# Clonar o repositório do Flutter (se ainda não estiver lá, o Vercel não cacheia /opt)
# Certifique-se de que o diretório está vazio antes de clonar para evitar erros
if [ ! -d ".git" ]; then
  git clone https://github.com/flutter/flutter.git .
fi

# Fazer checkout do branch desejado
git checkout $FLUTTER_CHANNEL
git pull

# Adicionar o Flutter ao PATH para a sessão atual
export PATH="$PATH:$FLUTTER_HOME/bin"

# Rodar flutter precache para garantir que os binários necessários estão prontos
flutter precache --web

# Habilitar suporte web (CORREÇÃO AQUI: --enable-web)
flutter config --enable-web

echo "--- Flutter SDK installation complete ---"
flutter doctor