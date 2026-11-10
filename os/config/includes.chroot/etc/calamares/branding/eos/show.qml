/* E OS: slides mostrados enquanto o Calamares copia o sistema para o disco.
   As fotos são telas reais da interface Fusão. */
import QtQuick 2.15
import calamares.slideshow 1.0

Presentation {
    id: apresentacao

    Timer {
        id: troca
        interval: 8000
        repeat: true
        running: false
        onTriggered: apresentacao.goToNextSlide()
    }

    // API 2 do Calamares: o slide começa a andar quando a cópia começa.
    function onActivate() { apresentacao.currentSlide = 0; troca.running = true; }
    function onLeave() { troca.running = false; }

    component SlideEOS: Slide {
        property alias imagem: foto.source
        property alias texto: legenda.text

        Rectangle { anchors.fill: parent; color: "#0d1117" }

        Image {
            id: foto
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 18
            width: parent.width * 0.80
            height: parent.height * 0.70
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
        }

        Text {
            id: legenda
            anchors.top: foto.bottom
            anchors.topMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.86
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            textFormat: Text.StyledText
            color: "#e6edf3"
            font.pixelSize: 17
        }
    }

    SlideEOS {
        imagem: "slide-area.png"
        texto: "<b>Bem-vindo ao E OS.</b> A instalação continua sozinha e leva poucos minutos."
    }
    SlideEOS {
        imagem: "slide-busca.png"
        texto: "<b>Super + Espaço</b> abre a busca: digite o nome de qualquer app."
    }
    SlideEOS {
        imagem: "slide-painel.png"
        texto: "<b>Super + A</b> abre o painel rápido: Wi-Fi, volume, captura de tela e notificações."
    }
    SlideEOS {
        imagem: "slide-janelas.png"
        texto: "<b>Leve de verdade:</b> o E OS roda bem com 1 GB de memória e não coleta nenhum dado seu."
    }
}
