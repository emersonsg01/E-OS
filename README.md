# E OS

Sistema operacional leve baseado em Linux, no modelo do ChromeOS: simples, rápido e feito para máquinas com pouca memória. A meta é rodar apps Linux, Android e Windows no mesmo sistema.

> **Estado:** E OS 0.2, com a interface gráfica **Fusão**. A ISO para PCs x86-64 dá para experimentar sem instalar ou instalar no disco. Veja o [roteiro](docs/ESPECIFICACAO.md#8-roteiro).

![Área de trabalho do E OS 0.2](docs/img/interface-area-de-trabalho.png)

## A interface Fusão

Uma interface moderna e minimalista que junta o que cada sistema faz de melhor:

| Inspiração | O que entrou no E OS |
|---|---|
| macOS | Dock flutuante no centro, menu do sistema no logo, busca no estilo do Spotlight, botões redondos coloridos |
| Windows 11 | Botão Início no dock, cantos arredondados, transparência, botões das janelas à direita |
| Android | Painel rápido com blocos e controles, notificações em cartões |
| ChromeOS | Status (rede, som, bateria) numa "pílula" que abre o painel rápido, busca em primeiro lugar |
| Linux Mint | Familiaridade: gerenciador de arquivos, menu no botão direito, atalhos de teclado |

O logo do E OS é um **tesserato**, o hipercubo de 4 dimensões: um cubo dentro de outro, com os vértices ligados.

Com a interface aberta, a sessão live ocupa uns 180 MB de memória e deixa uns 630 MB livres para apps numa máquina de 1 GB (medido no QEMU).

### Atalhos

| Atalho | O que faz |
|---|---|
| Super + Espaço | Busca de apps |
| Super + A | Painel rápido e notificações |
| Super + E | Arquivos |
| Super + Enter | Terminal |
| Super + B | Navegador |
| Super + L | Bloqueia a tela |
| Super + setas | Maximiza, minimiza e encaixa a janela na metade da tela |
| Alt + Tab | Troca de janela |
| Print | Captura a tela para a pasta Imagens |

### Telas

| | |
|---|---|
| ![Busca de apps](docs/img/interface-busca.png) | ![Painel rápido](docs/img/interface-painel-rapido.png) |
| Busca (Super + Espaço) | Painel rápido (Super + A) |
| ![Janelas](docs/img/interface-janelas.png) | ![Menu de boot](docs/img/boot-uefi.png) |
| Janelas e dock com os apps abertos | Menu de boot |

## Gerar a ISO

Você precisa de:

- Windows 10/11 com [Docker Desktop](https://www.docker.com/products/docker-desktop/), ou Linux com Docker;
- uns 15 GB livres em disco;
- internet, porque o build baixa os pacotes e o instalador do Debian.

No Windows, abra o PowerShell na pasta do projeto e rode:

```powershell
.\eos.cmd build
```

No Linux:

```bash
./eos.sh build
```

A ISO sai em `out/eos-0.2-amd64.hybrid.iso` (uns 920 MB). O primeiro build leva uns 20 minutos. Os seguintes são mais rápidos, porque reaproveitam os pacotes já baixados.

## Experimentar ou instalar

Grave a ISO num pendrive com o [Rufus](https://rufus.ie) ou o [Ventoy](https://www.ventoy.net), ou abra no VirtualBox ou no VMware. O menu de boot tem:

| Opção | O que faz |
|---|---|
| Experimentar o E OS (sem instalar) | Liga o sistema direto do pendrive, já na interface Fusão, sem mexer no disco. Usuário `eos`, senha `live`. |
| Instalar o E OS | Instalador gráfico |
| Instalar o E OS (modo texto) | O mesmo instalador em modo texto, que precisa de menos memória |
| Mais opções | Modo seguro, reparo de um sistema instalado e, no UEFI, configurações do firmware |

O instalador pergunta, nesta ordem:

1. idioma (Português do Brasil já vem selecionado);
2. região;
3. teclado;
4. nome da máquina;
5. seu nome, usuário e senha (esse usuário administra o sistema com `sudo`);
6. fuso horário;
7. onde instalar: disco inteiro, disco inteiro com LVM, disco inteiro com LVM criptografado, ou particionamento manual;
8. só em PCs com BIOS: em qual disco gravar o carregador de boot (GRUB).

> **Atenção:** as opções de "disco inteiro" apagam tudo o que estiver no disco escolhido.

No particionamento assistido, o E OS cria a partição EFI quando o PC é UEFI e não cria partição de swap: ele usa zram, uma swap comprimida na própria memória. Precisa de um disco de pelo menos 8 GB.

No fim, tire o pendrive e reinicie. No sistema instalado, entre com seu usuário no primeiro terminal e a interface abre sozinha. O instalador é o do Debian, no modo que copia o próprio E OS da ISO para o disco, então funciona sem internet.

| | |
|---|---|
| ![Escolha do idioma](docs/img/instalador-1-idioma.png) | ![Escolha do teclado](docs/img/instalador-3-teclado.png) |
| Idioma | Teclado |
| ![Escolha do fuso horário](docs/img/instalador-4-fuso-horario.png) | ![Método de particionamento](docs/img/instalador-5-particionamento.png) |
| Fuso horário | Onde instalar |

## Testar

```powershell
.\eos.cmd test
.\eos.cmd install-test
```

- `test` liga a ISO no QEMU, sem janela e com 1 GB de RAM, em modo BIOS e em modo UEFI. Ele entra no sistema, confere a interface, a memória, a rede e os serviços, e desliga. Os relatórios ficam em `out/teste-bios.log` e `out/teste-uefi.log`.
- `install-test` instala o E OS num disco virtual de 8 GB, com respostas automáticas e 1 GB de RAM, e depois liga o sistema instalado para conferir se ele funciona. A última tela do instalador fica em `out/instalacao-*.png` (se ele parar numa pergunta, é ali que dá para ver qual) e o relatório do sistema instalado em `out/teste-instalado-*.log`.

O Docker Desktop no Windows não oferece aceleração de virtualização (KVM) para o QEMU, então os testes rodam em emulação e demoram: alguns minutos o `test` e uns 20 minutos o `install-test`.

## Comandos

| Comando | O que faz |
|---|---|
| `build` | Gera a ISO em `out/` |
| `test` | Testa a ISO no QEMU (`test bios`, `test uefi` ou os dois) |
| `install-test` | Testa a instalação num disco virtual (`bios`, `uefi` ou os dois) |
| `shell` | Abre um terminal dentro do ambiente de build |
| `clean` | Apaga a área de build e mantém o cache de pacotes |

## Estrutura

| Pasta | Conteúdo |
|---|---|
| `os/` | Definição da imagem, no formato do live-build: pacotes, menus de boot, respostas do instalador e os arquivos do sistema |
| `os/config/includes.chroot/usr/share/eos/` | A interface Fusão: barra e dock, painel rápido, busca, ícones e tema |
| `branding/` | Logo (tesserato), papel de parede e faixa do instalador, que o build converte em imagem |
| `tools/` | Ambiente de build (Docker) e scripts de build e teste |
| `docs/` | Especificação, decisões e roteiro |
| `out/` | ISOs e relatórios gerados (fica fora do git) |

## Documentação

- [Especificação do E OS](docs/ESPECIFICACAO.md): visão, decisões técnicas, metas de memória, compatibilidade de apps e roteiro.
