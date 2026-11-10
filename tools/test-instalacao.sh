#!/usr/bin/env bash
# Testa a instalação do E OS no QEMU: instala num disco virtual, com respostas
# automáticas, e depois liga o sistema instalado e confere se ele funciona.
# Roda dentro do container de build. Uso: test-instalacao.sh [bios|uefi|ambos]
set -euo pipefail

OUT=/src/out
modo=${1:-ambos}

iso=$(ls -1t "$OUT"/*.iso 2>/dev/null | head -n 1 || true)
if [ -z "$iso" ]; then
  echo "Nenhuma ISO em out/. Rode o build primeiro." >&2
  exit 1
fi

acel=tcg
if [ -w /dev/kvm ]; then acel=kvm; fi
echo "ISO: $(basename "$iso") | aceleração: $acel | RAM: 1 GB | disco: 8 GB"

dir=/tmp/instalacao
rm -rf "$dir"
mkdir -p "$dir/extra"

# Instalador em modo texto, com kernel e initrd tirados da ISO. As respostas
# do teste entram num preseed.cfg somado às respostas padrão do E OS.
xorriso -osirrox on -indev "$iso" \
  -extract /install/vmlinuz "$dir/vmlinuz" \
  -extract /install/initrd.gz "$dir/initrd.gz" 2>/dev/null
{ zcat "$dir/initrd.gz" | cpio -i --quiet --to-stdout preseed.cfg 2>/dev/null || true
  cat /src/tools/instalacao-teste.cfg; } > "$dir/extra/preseed.cfg"
(cd "$dir/extra" && echo preseed.cfg | cpio -o -H newc --quiet | gzip) > "$dir/extra.cpio.gz"
cat "$dir/initrd.gz" "$dir/extra.cpio.gz" > "$dir/initrd-teste.gz"

# Sem perguntas e com o instalador na tela, como numa instalação de verdade.
# Nada de console= aqui: com qualquer console serial na linha, o instalador
# vai para o serial e se comporta diferente. O console serial do sistema
# instalado (para o teste de boot) é ligado no fim, pelo late_command do
# instalacao-teste.cfg.
linha="priority=critical locale=pt_BR.UTF-8 keymap=br --- quiet"

testar() {
  local m=$1
  local disco="$dir/disco-$m.qcow2"
  local firmware=()
  qemu-img create -q -f qcow2 "$disco" 8G
  if [ "$m" = uefi ]; then
    # UEFI num chipset moderno (q35, com SATA/AHCI), como os PCs UEFI de
    # verdade. No chipset antigo (i440fx, IDE) o kernel do instalador não
    # enxerga o leitor de DVD quando o firmware é UEFI.
    cp /usr/share/OVMF/OVMF_VARS_4M.fd "$dir/vars-$m.fd"
    firmware=(-machine q35
              -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd
              -drive "if=pflash,format=raw,file=$dir/vars-$m.fd")
  fi

  echo
  echo "== Instalação $m (última tela em out/instalacao-$m.png) =="
  expect /src/tools/qemu-instalar.exp "$OUT/instalacao-$m.png" \
    qemu-system-x86_64 -accel "$acel" -m 1024 -smp 2 -no-reboot \
      -vga std -display none -serial "file:$OUT/instalacao-$m-serial.log" -monitor stdio \
      -cdrom "$iso" -drive "file=$disco,if=virtio,format=qcow2" \
      -kernel "$dir/vmlinuz" -initrd "$dir/initrd-teste.gz" -append "$linha" \
      -nic user,model=virtio-net-pci "${firmware[@]}" || return 1

  echo "== Sistema instalado $m (relatório em out/teste-instalado-$m.log) =="
  expect /src/tools/qemu-smoke.exp "$OUT/teste-instalado-$m.log" teste teste123 eos-teste \
    qemu-system-x86_64 -accel "$acel" -m 1024 -smp 2 -nographic -no-reboot \
      -drive "file=$disco,if=virtio,format=qcow2" \
      -nic user,model=virtio-net-pci "${firmware[@]}"
}

falhas=0
case "$modo" in
  bios|uefi) testar "$modo" || falhas=1 ;;
  ambos)     testar bios || falhas=1; testar uefi || falhas=1 ;;
  *) echo "Modo inválido: $modo (use bios, uefi ou ambos)" >&2; exit 2 ;;
esac

echo
if [ "$falhas" -eq 0 ]; then
  echo "Instalação testada com sucesso."
else
  echo "Algum teste de instalação falhou. Veja os logs em out/."
fi
exit "$falhas"
