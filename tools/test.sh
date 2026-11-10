#!/usr/bin/env bash
# Testa a ISO do E OS no QEMU, sem janela, pelo console serial.
# Roda dentro do container de build. Uso: test.sh [bios|uefi|ambos]
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
echo "ISO: $(basename "$iso") | aceleração: $acel | RAM: 1 GB"

testar() {
  local m=$1
  local log="$OUT/teste-$m.log"
  local firmware=()
  if [ "$m" = uefi ]; then
    cp /usr/share/OVMF/OVMF_VARS_4M.fd /tmp/ovmf-vars.fd
    firmware=(-drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd
              -drive if=pflash,format=raw,file=/tmp/ovmf-vars.fd)
  fi
  echo
  echo "== Teste $m (relatório em out/teste-$m.log) =="
  expect /src/tools/qemu-smoke.exp "$log" eos live eos \
    qemu-system-x86_64 -accel "$acel" -m 1024 -smp 2 \
      -cdrom "$iso" -boot d -nographic -no-reboot \
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
  echo "Todos os testes passaram."
else
  echo "Algum teste falhou. Veja os relatórios em out/."
fi
exit "$falhas"
