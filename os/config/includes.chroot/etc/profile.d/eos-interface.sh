# E OS: abre a interface gráfica Fusão ao entrar no primeiro terminal (tty1).
# Nos outros terminais (Ctrl+Alt+F2 a F6) e no acesso remoto fica o modo texto.
if [ -z "${WAYLAND_DISPLAY}${DISPLAY}" ] && [ "$(tty)" = "/dev/tty1" ] && command -v labwc >/dev/null 2>&1; then
  exec /bin/sh /usr/lib/eos/iniciar-interface
fi
