#!/usr/bin/env bash
# Gera e testa o E OS num Linux com Docker.
# Uso: ./eos.sh [build|test|install-test|shell|clean|builder] [bios|uefi|ambos]
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")" && pwd)"
IMAGEM=eos-builder:trixie
VOLUME=eos-build   # área de build e cache

comando=${1:-build}
modo=${2:-ambos}

docker version --format '{{.Server.Version}}' >/dev/null

container() { docker run --rm --privileged -v "$RAIZ:/src" -v "$VOLUME:/work" "$@"; }
construir_builder() { docker build --tag "$IMAGEM" "$RAIZ/tools/builder"; }

case "$comando" in
  builder) construir_builder ;;
  build)   construir_builder; container "$IMAGEM" bash /src/tools/build.sh ;;
  test)    container "$IMAGEM" bash /src/tools/test.sh "$modo" ;;
  install-test) container "$IMAGEM" bash /src/tools/test-instalacao.sh "$modo" ;;
  shell)   container -it "$IMAGEM" bash ;;
  clean)   container "$IMAGEM" bash /src/tools/build.sh --clean ;;
  *) echo "Uso: $0 [build|test|install-test|shell|clean|builder] [bios|uefi|ambos]" >&2; exit 2 ;;
esac
