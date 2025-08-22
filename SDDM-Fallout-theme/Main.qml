import QtQuick 2.15
import QtQuick.Controls 2.15
import QtMultimedia 5.15

Item {
    id: root
    width: 1920; height: 1080
    focus: true

    MediaPlayer {
        id: bgm
        source: "file:///" + theme.dir + "/background.mp4"
        autoPlay: true
        loops: MediaPlayer.Infinite
        muted: true
    }

    VideoOutput {
        id: videoOut
        anchors.fill: parent
        source: bgm
        fillMode: VideoOutput.PreserveAspectCrop
        visible: bgm.status === MediaPlayer.Loaded || bgm.status === MediaPlayer.Buffering
    }

    Rectangle { anchors.fill: parent; color: "#000000"; opacity: 0.35 }

    Rectangle {
        id: panel
        width: 520; height: 360
        radius: 16
        color: "#1b1b1d"; opacity: 0.92
        anchors.centerIn: parent

        Column {
            anchors.fill: parent; anchors.margins: 28; spacing: 16
            Label { text: "Bienvenue"; font.pixelSize: 28; color: "#ffffff"; anchors.horizontalCenter: parent.horizontalCenter }

            TextField {
                id: userField
                placeholderText: "Nom d’utilisateur"
                text: (typeof config !== "undefined" && config.PreFillUser) ? String(config.PreFillUser) : ""
                selectByMouse: true; focus: true
            }

            TextField {
                id: passwordField
                placeholderText: "Mot de passe"
                echoMode: TextInput.Password
                selectByMouse: true
                onAccepted: loginButton.clicked()
            }

            ComboBox {
                id: sessionCombo
                model: sessionModel
                textRole: "name"
                visible: sessionModel && sessionModel.count > 1
            }

            Label {
                id: errorLabel
                text: sddm.lastError
                color: "red"
                visible: !!sddm.lastError
                wrapMode: Text.WordWrap
            }

            Button {
                id: loginButton
                text: "Connexion"
                onClicked: {
                    var sessionName = sessionModel && sessionModel.count > 0 ? sessionModel.get(0).key : ""
                    if (sessionCombo.visible && sessionCombo.currentIndex >= 0)
                        sessionName = sessionModel.get(sessionCombo.currentIndex).key
                    sddm.login(userField.text, passwordField.text, sessionName)
                }
            }
        }
    }

    Keys.onReturnPressed: loginButton.clicked()
    Keys.onEnterPressed: loginButton.clicked()
}
