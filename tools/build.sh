#!/usr/bin/env bash
# Gera a ISO do E OS com o live-build. Roda dentro do container de build.
#
# A área de build fica no volume /work (sistema de arquivos Linux), e não na
# pasta montada do Windows: o debootstrap precisa de dono, permissões e
# arquivos de dispositivo, que o NTFS não oferece.
set -euo pipefail

SRC=/src
WORK=/work/eos
OUT=/src/out

mkdir -p "$WORK"
cd "$WORK"

# Limpa o build anterior. O cache de pacotes (cache/) é mantido.
if [ -d config ]; then lb clean; fi
rm -rf auto config

if [ "${1:-}" = "--clean" ]; then
  echo "Área de build limpa. O cache de pacotes foi mantido."
  exit 0
fi

# Copia a definição da imagem e desfaz o que o Windows pode ter mudado:
# fim de linha CRLF e permissões.
cp -r "$SRC/os/auto" "$SRC/os/config" .
{ grep -rlI $'\r' auto config || true; } | xargs -r sed -i 's/\r$//'
find auto config -type d -exec chmod 755 {} +
find auto config -type f -exec chmod 644 {} +
chmod 755 auto/*
find config/hooks -type f -name '*.hook.*' -exec chmod 755 {} +

# Scripts do E OS (/usr/lib/eos) precisam ser executáveis.
if [ -d config/includes.chroot/usr/lib/eos ]; then
  find config/includes.chroot/usr/lib/eos -type f -exec chmod 755 {} +
fi

# Faixa do instalador gráfico (800x75), gerada a partir do SVG. Substitui o
# logo do Debian nos temas claro e escuro do instalador.
graficos=config/includes.installer/usr/share/graphics
mkdir -p "$graficos"
rsvg-convert --width 800 --height 75 "$SRC/branding/instalador-banner.svg" -o "$graficos/logo_installer.png"
cp "$graficos/logo_installer.png" "$graficos/logo_installer_dark.png"

# Papel de parede da interface Fusão (1920x1080), gerado a partir do SVG.
fundos=config/includes.chroot/usr/share/backgrounds/eos
mkdir -p "$fundos"
rsvg-convert --width 1920 --height 1080 "$SRC/branding/papel-de-parede.svg" -o "$fundos/fusao.png"

# Instalador gráfico (Calamares): logo, imagem de boas-vindas e slides com
# fotos reais da interface.
calamares=config/includes.chroot/etc/calamares/branding/eos
mkdir -p "$calamares"
rsvg-convert --width 256 --height 256 "$SRC/branding/logo-tesseract.svg" -o "$calamares/logo.png"
rsvg-convert --width 800 --height 300 "$SRC/branding/instalador-boas-vindas.svg" -o "$calamares/boas-vindas.png"
cp "$SRC/docs/img/interface-area-de-trabalho.png" "$calamares/slide-area.png"
cp "$SRC/docs/img/interface-busca.png" "$calamares/slide-busca.png"
cp "$SRC/docs/img/interface-painel-rapido.png" "$calamares/slide-painel.png"
cp "$SRC/docs/img/interface-janelas.png" "$calamares/slide-janelas.png"

lb config
lb build 2>&1 | tee build.log

mkdir -p "$OUT"
rm -f "$OUT"/eos-*.iso "$OUT"/eos-*.iso.sha256 "$OUT"/eos-*.packages
iso=$(ls -1 ./*.iso | head -n 1)
nome=$(basename "$iso")
cp "$iso" "$OUT/$nome"
cp build.log "$OUT/build.log"
cp ./*.packages "$OUT/" 2>/dev/null || true
(cd "$OUT" && sha256sum "$nome" > "$nome.sha256")

echo
echo "ISO pronta: out/$nome ($(du -h "$OUT/$nome" | cut -f1))"
