# Especificação do E OS

Versão do documento: 0.2 · Atualizado em 09/11/2026

## 1. Visão

O E OS é um sistema operacional baseado em Linux, no modelo do ChromeOS: simples de usar, rápido, seguro e leve o bastante para dar vida nova a máquinas com pouca memória.

A diferença é rodar apps de três origens no mesmo sistema:

- **Linux:** apps nativos;
- **Android:** num contêiner que só liga quando um app Android é aberto;
- **Windows:** pela camada de compatibilidade Wine/Proton.

Para quem usa, a origem não importa: todo app aparece no mesmo menu, no mesmo dock e na mesma loja, a E Store.

## 2. Princípios

1. **Leve por projeto.** Cada serviço precisa justificar a memória que usa. Toda versão é medida no QEMU e, a partir da Fase 3, em hardware real.
2. **Integrar em vez de reinventar.** Linux, Debian, Wine, Waydroid e Qt já são maduros. O trabalho próprio do E OS está na integração e na interface.
3. **Uma experiência só.** Apps Linux, Android e Windows se instalam, abrem e se comportam do mesmo jeito.
4. **Base estável.** Debian estável, com atualizações previsíveis.
5. **Seguro por padrão.** Apps isolados (Flatpak e contêiner Android) e nenhuma telemetria.

## 3. Edições

| Edição | Para quê | Memória recomendada |
|---|---|---|
| **Core** | Sem interface gráfica: base das outras edições, servidores, embarcados | 512 MB |
| **Lite** | Interface completa e apps Windows, sem Android | 1 GB |
| **Desktop** | Tudo incluso: Linux, Android e Windows | 2 GB (4 GB para usar Android e Windows juntos) |
| **Mobile** | Celulares e tablets, interface de toque | depende do aparelho |

A primeira entrega foi o **E OS 0.1 Core** (modo texto). A versão atual, **E OS 0.2**, já traz a interface gráfica Fusão e é a base da edição Lite.

## 4. Decisões técnicas

| Tema | Escolha | Situação |
|---|---|---|
| Base | Debian 13 "trixie" (estável) | Decidido |
| Processadores | x86-64 primeiro, ARM64 na Fase 4 | Decidido |
| Build | live-build dentro de um container Docker, igual no Windows e no Linux | Decidido |
| Inicialização | systemd | Decidido |
| Memória | zram (swap comprimida na própria RAM) e ajustes do kernel para pouca memória | Decidido |
| Rede | NetworkManager (Wi-Fi e cabo, com ícone na barra) e systemd-resolved para DNS | Decidido (0.2) |
| Instalador | Debian Installer no modo live (gráfico e texto), com padrões do E OS; instalador gráfico próprio (Calamares) na Fase 3 | Decidido |
| Particionamento | Esquema próprio: partição EFI (no UEFI), raiz a partir de 4 GB e nenhuma partição de swap, porque o E OS usa zram | Decidido (0.2) |
| Gráficos | Wayland com o compositor labwc; desenho por software quando não há aceleração de vídeo | Decidido (0.2) |
| Interface | Fusão: Waybar (barra e dock), SwayNC (painel rápido e notificações) e Fuzzel (busca), com tema, ícones e scripts do E OS. Peças próprias em Qt/QML entram onde fizerem diferença | Decidido (0.2) |
| Estilo visual | Fusão: mistura de macOS, Windows 11, Android, ChromeOS e Linux Mint, moderna e minimalista, em tema escuro | Decidido (0.2) |
| Logo | Tesserato (o hipercubo de 4 dimensões) | Decidido (0.2) |
| Apps Linux | apt para o sistema; Flatpak para apps, com isolamento e permissões | Proposto |
| Apps Android | Waydroid: Android num contêiner que liga sob demanda | Proposto |
| Apps Windows | Wine para programas, Proton para jogos | Proposto |
| Áudio | PipeWire | Decidido (0.2) |
| Licença | Modelo híbrido: código aberto, marca e serviços próprios | Pendente |

**A interface Fusão.** Cada peça vem de um sistema:

- do **macOS**, o dock flutuante no centro, o menu do sistema no logo (canto superior esquerdo), a busca no estilo do Spotlight e os botões redondos coloridos das janelas;
- do **Windows 11**, o botão Início no dock, os cantos arredondados, a transparência e os botões das janelas do lado direito;
- do **Android**, o painel rápido com blocos (Wi-Fi, captura, bloquear, desligar...) e controle de volume, e as notificações em cartões;
- do **ChromeOS**, o status (rede, som, bateria) numa "pílula" que abre o painel rápido, e a busca como jeito principal de abrir apps;
- do **Linux Mint**, a familiaridade: gerenciador de arquivos, menu no botão direito da área de trabalho, atalhos de teclado.

A interface abre sozinha quando o usuário entra no primeiro terminal (tty1). Na sessão live o login é automático.

**Por que uma base só.** O plano original usava Buildroot no Core, Debian no Desktop e Yocto depois. Seriam três sistemas de build para manter. Com o Debian em todas as edições, o que se aprende e corrige numa vale para as outras.

**Por que Debian e não Alpine.** O Alpine é mais leve, mas usa musl em vez de glibc. Steam, Proton e muitos programas fechados para Linux foram feitos para glibc. Com Android e Windows no pacote, o Debian é a escolha mais segura. Ele também tem suporte oficial do Waydroid e serve de base para o Mobian e o Droidian, usados em celulares.

## 5. Metas de memória

Memória ocupada logo depois do boot, sem apps abertos, medida como total − livre − cache (com os números do `free -m`). Atenção: no Debian 13 a coluna "usada" do `free` é total − disponível, que também conta reservas do kernel e parte do cache, e por isso mostra mais. Os números são metas de engenharia; o que vale é a medição.

| Situação | Meta | Medido |
|---|---|---|
| Core 0.1, sessão live no QEMU com 1 GB | até 150 MB | 89 a 100 MB ("usada" no `free`: 233 a 244 MB) |
| 0.2 com a interface Fusão aberta, sessão live no QEMU com 1 GB | 300 a 500 MB | 175 a 187 MB ("usada" no `free`: 330 a 341 MB) |
| Desktop, com interface | até 700 MB | — |
| Contêiner Android ligado | +500 MB a 1 GB | — |
| Wine ligado | +50 a 150 MB, mais o programa | — |

Medições de 09/11/2026, em emulação (sem KVM), sessão live com 1 GB:

- **E OS 0.1 (modo texto):** sobram uns 720 MB disponíveis para programas. Os maiores consumidores são o systemd e os serviços de rede, com 8 a 15 MB cada. Boot de 36 a 39 s até os serviços subirem.
- **E OS 0.2 (interface Fusão aberta):** sobram uns 630 MB disponíveis. A interface toda custa uns 85 MB a mais que o modo texto. Os maiores consumidores são a barra/dock (Waybar, uns 57 MB), o painel rápido (SwayNC, uns 41 MB), o compositor (labwc, uns 38 MB) e o ícone de rede (nm-applet, uns 31 MB). Boot de 42 a 44 s até os serviços subirem.

- **E OS 0.2 instalado no disco** (teste automático, BIOS e UEFI, antes de abrir a interface): boot de 18 a 19 s, uns 125 MB ocupados e uns 725 MB disponíveis. A instalação completa levou 9 minutos.

Em hardware real, sem emulação, o boot deve ser bem mais rápido.

Como o E OS economiza memória:

- só os serviços essenciais ligam no boot; o resto liga sob demanda;
- o zram comprime a memória pouco usada em vez de gravá-la no disco;
- o Android só liga quando um app Android é aberto, e desliga depois;
- animações, efeitos e indexação de arquivos são opcionais;
- o diário do sistema (journal) tem tamanho limitado.

## 6. Compatibilidade de apps

### Android (Waydroid)

O Android roda num contêiner. Os apps aparecem no dock e no menu, cada um na sua janela, e a E Store instala APKs e apps do F-Droid.

Limites:

- o contêiner usa de 500 MB a 1 GB a mais enquanto está ligado;
- em PCs x86, apps que só têm código ARM (muitos jogos e apps de banco) precisam de uma camada de tradução proprietária, da Intel ou do Google, que nem sempre funciona; em ARM eles rodam direto;
- o Google Play não pode vir no sistema sem licença do Google; as alternativas são F-Droid, Aurora Store e microG;
- apps de banco e alguns jogos costumam bloquear por não ser um Android certificado;
- placas NVIDIA com driver proprietário não funcionam bem; Intel e AMD funcionam.

O kernel precisa do driver binder. O kernel padrão do Debian 13 já traz esse driver como módulo (`binder_linux`, sem binderfs), e o teste da Fase 1 confirmou que ele carrega. O Waydroid funciona assim, carregando o módulo com os três dispositivos que o Android usa, então o contêiner Android não vai precisar de um kernel próprio.

### Windows (Wine e Proton)

Dois cliques num `.exe` instalam e abrem o programa como qualquer app. Cada programa fica num compartimento separado (um prefixo do Wine). Jogos usam o Proton, como no SteamOS.

Limites:

- não rodam jogos com anti-cheat que bloqueia Linux (Valorant, Fortnite, League of Legends);
- não rodam drivers de Windows: impressoras e outros aparelhos precisam de driver Linux;
- não rodam antivírus nem programas que mexem no núcleo do Windows;
- Office e Photoshop recentes rodam mal ou não rodam;
- em ARM, programas Windows precisam de emulação de x86 (FEX-Emu ou Box64) e ficam lentos.

Para o que não roda, a saída é uma máquina virtual com Windows de verdade, que exige licença e uns 4 GB de RAM a mais. Fica como extra, fora do sistema.

### Linux

Apps do Debian pelo apt e apps do Flathub pelo Flatpak. O Flatpak isola cada app e pede permissões, como no Android.

## 7. Processadores e aparelhos

- **x86-64:** alvo principal. Cobre quase todo PC dos últimos 15 anos.
- **ARM64:** Fase 4, começando pelo Raspberry Pi 4 e 5.
- **x86 de 32 bits:** fora do escopo. O Debian 13 não tem mais kernel para essa arquitetura.
- **RISC-V e outras:** futuro. O Debian 13 já suporta RISC-V de 64 bits oficialmente.
- **Celulares:** começar por aparelhos que já rodam Linux, como PinePhone, OnePlus 6 e Pixel 3a. Depois, aparelhos Android usando os drivers do próprio Android (Halium, como faz o Droidian).

Suportar "todos os processadores já fabricados" não é possível: cada arquitetura e cada aparelho precisam de kernel, firmware e drivers próprios.

## 8. Roteiro

### Fase 1: fundação (E OS 0.1 Core)

- [x] Build reproduzível em Docker (testado no Windows; o `eos.sh` faz o mesmo no Linux)
- [x] ISO x86-64 que liga em BIOS e UEFI
- [x] Identidade do E OS: nome, versão, tela de login
- [x] Rede automática
- [x] zram e ajustes de memória
- [x] Teste automático no QEMU com medição de memória
- [x] Instalador: idioma, região, teclado, fuso horário e escolha do disco
- [x] Teste automático da instalação, em BIOS e UEFI
- [x] Verificar o driver binder (Android) no kernel

### Fase 2: Desktop (0.2), em andamento

- [x] Compositor Wayland leve (labwc)
- [x] Interface Fusão: barra, dock, busca, painel rápido e notificações
- [x] Arquivos, terminal, editor de texto e navegador
- [x] Rede com Wi-Fi (NetworkManager) e som (PipeWire)
- [x] Logo (tesserato), papel de parede e tema próprios
- [ ] Login gráfico no sistema instalado
- [ ] E Settings: central de configurações
- [ ] Flatpak
- [ ] Abrir `.exe` com o Wine
- [ ] Apps Android no menu e na loja, com o Waydroid

### Fase 3: otimização e edição Lite (0.3)

- Cortar serviços, medir boot e memória
- Instalador gráfico com a cara do E OS (Calamares)
- Testes em máquinas antigas com 1 GB
- Edição Lite

### Fase 4: hardware (0.4)

- Firmware, Wi-Fi e placas de vídeo
- Proton para jogos
- Imagens ARM64, começando pelo Raspberry Pi

### Fase 5: Mobile (0.5)

- Interface de toque e gestos
- Telefonia, sensores, câmera e energia
- Primeiros aparelhos com Linux já portado

### Fase 6: ecossistema (1.0)

- E Store com apps Linux, Android e Windows
- E Update e sistema de recuperação
- Documentação e SDK para desenvolvedores

## 9. Decisões pendentes

- **Licença** do código próprio.

## 10. Origem

Este documento parte do [plano inicial feito no ChatGPT](https://chatgpt.com/share/6af23136-da1c-83e9-915c-a310d3cf6e26), com estas mudanças:

- uma base só (Debian) em vez de Buildroot, Debian e Yocto;
- processadores realistas: x86-64 e ARM64 primeiro, 32 bits fora;
- compositor leve em vez do KWin, porque a memória depende mais da interface que da distribuição;
- apps Android e Windows como parte do sistema, no modelo do ChromeOS;
- instalador antecipado da Fase 6 para a Fase 1 (Debian Installer), com um instalador próprio (Calamares) na Fase 3;
- interface Fusão montada com peças prontas e leves (Waybar, SwayNC, Fuzzel) em vez de um shell escrito do zero em Qt/QML, para chegar mais rápido a um sistema usável; peças próprias entram onde fizerem diferença.
