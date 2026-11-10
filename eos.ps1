<#
.SYNOPSIS
  Gera e testa o E OS usando o Docker.

.DESCRIPTION
  Todo o trabalho acontece dentro de um container Debian com live-build e QEMU.

  .\eos.cmd build        gera a ISO em out\
  .\eos.cmd test         testa a ISO no QEMU (BIOS e UEFI)
  .\eos.cmd test uefi    testa só em modo UEFI
  .\eos.cmd install-test instala num disco virtual e testa o sistema instalado
  .\eos.cmd shell        abre um terminal no ambiente de build
  .\eos.cmd clean        apaga a área de build e mantém o cache de pacotes
#>
param(
  [Parameter(Position = 0)]
  [ValidateSet('build', 'test', 'install-test', 'shell', 'clean', 'builder')]
  [string]$Comando = 'build',

  [Parameter(Position = 1)]
  [ValidateSet('bios', 'uefi', 'ambos')]
  [string]$Modo = 'ambos'
)

$Raiz   = $PSScriptRoot
$Imagem = 'eos-builder:trixie'
$Volume = 'eos-build'   # área de build e cache, num sistema de arquivos Linux

# Acentos corretos na saída dos scripts que rodam no container.
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

function Invoke-Docker {
  & docker @args
  if ($LASTEXITCODE -ne 0) { throw "O comando 'docker $($args[0])' falhou (código $LASTEXITCODE)." }
}

function Invoke-Container([string[]]$Comandos, [switch]$Interativo) {
  $opcoes = @('run', '--rm', '--privileged', '-v', "${Raiz}:/src", '-v', "${Volume}:/work")
  if ($Interativo) { $opcoes += '-it' }
  Invoke-Docker @opcoes $Imagem @Comandos
}

& docker version --format '{{.Server.Version}}' | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'O Docker não respondeu. Abra o Docker Desktop, espere ele ligar e tente de novo.' }

switch ($Comando) {
  'builder' { Invoke-Docker build --tag $Imagem (Join-Path $Raiz 'tools\builder') }
  'build' {
    Invoke-Docker build --tag $Imagem (Join-Path $Raiz 'tools\builder')
    Invoke-Container @('bash', '/src/tools/build.sh')
  }
  'test'  { Invoke-Container @('bash', '/src/tools/test.sh', $Modo) }
  'install-test' { Invoke-Container @('bash', '/src/tools/test-instalacao.sh', $Modo) }
  'shell' { Invoke-Container @('bash') -Interativo }
  'clean' { Invoke-Container @('bash', '/src/tools/build.sh', '--clean') }
}
