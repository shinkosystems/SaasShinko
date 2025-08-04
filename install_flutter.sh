#!/bin/bash

# Define a versão do Flutter que você quer usar (OPCIONAL: se quiser uma versão muito específica)
# FLUTTER_VERSION="3.22.4" # Removendo esta linha ou comentando para focar no canal stable

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

# Se você REALMENTE precisa da versão exata 3.22.4, use git reset --hard <tag_ou_commit_hash>
# Mas para a maioria dos casos, o branch stable já é suficiente para web builds.
# Exemplo para uma tag:
# git reset --hard v$FLUTTER_VERSION # Usaria "v3.22.4" se FLUTTER_VERSION="3.22.4"

# Adicionar o Flutter ao PATH para a sessão atual
export PATH="$PATH:$FLUTTER_HOME/bin"

# Rodar flutter precache para garantir que os binários necessários estão prontos
flutter precache --web

# Habilitar suporte web (CORREÇÃO AQUI: --enable-web)
flutter config --enable-web

echo "--- Flutter SDK installation complete ---"
flutter doctor