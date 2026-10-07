import QtQuick
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.GustavoDGoat.omawall"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property int remainingSeconds: 0

  readonly property var intervalOptions: [
    { value: "1", label: "1 minute" },
    { value: "5", label: "5 minutes" },
    { value: "10", label: "10 minutes" },
    { value: "15", label: "15 minutes" },
    { value: "30", label: "30 minutes" },
    { value: "60", label: "1 hour" },
    { value: "120", label: "2 hours" }
  ]

  function open() {
    root.refreshCountdown()
    root.controller.show()
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  function refreshCountdown() {
    if (!root.hostWidget || !root.hostWidget.rotationEnabled) {
      root.remainingSeconds = 0
      return
    }

    var remaining = Math.ceil((root.hostWidget.nextRotationAt - Date.now()) / 1000)
    root.remainingSeconds = Math.max(0, remaining)
  }

  function formatRemaining() {
    if (!root.hostWidget || !root.hostWidget.rotationEnabled) return "Rotation paused"
    if (root.remainingSeconds <= 0) return "Changing wallpaper..."

    var hours = Math.floor(root.remainingSeconds / 3600)
    var minutes = Math.floor((root.remainingSeconds % 3600) / 60)
    var seconds = root.remainingSeconds % 60
    if (hours > 0) return "Next wallpaper in " + hours + "h " + minutes + "m"
    if (minutes > 0) return "Next wallpaper in " + minutes + "m " + seconds + "s"
    return "Next wallpaper in " + seconds + "s"
  }

  onOpenedChanged: {
    if (root.opened) root.refreshCountdown()
  }

  Connections {
    target: root.hostWidget
    function onNextRotationAtChanged() { root.refreshCountdown() }
    function onRotationEnabledChanged() { root.refreshCountdown() }
  }

  Timer {
    id: countdownTimerObject
    interval: 1000
    repeat: true
    running: root.opened
    onTriggered: root.refreshCountdown()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(300))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Flickable {
        id: panelScroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height

        Column {
          id: content
          width: panelScroll.width
          spacing: Style.space(10)

        Column {
          width: parent.width
          spacing: Style.space(2)

          Text {
            text: "OMAWALL"
            color: root.barForeground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 2
          }

          Text {
            text: "Wallpaper rotation"
            color: Qt.darker(root.barForeground, 1.35)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.bodySmall
          }
        }

        Toggle {
          width: parent.width
          label: root.hostWidget && root.hostWidget.rotationEnabled ? "Active" : "Paused"
          description: root.hostWidget && root.hostWidget.rotationEnabled
            ? "Wallpaper changes automatically"
            : "Automatic rotation is paused"
          checked: root.hostWidget ? root.hostWidget.rotationEnabled : true
          foreground: root.barForeground
          onClicked: if (root.hostWidget) root.hostWidget.toggleRotation()
        }

        Dropdown {
          width: parent.width
          label: "INTERVAL"
          options: root.intervalOptions
          value: root.hostWidget ? String(root.hostWidget.intervalMinutes) : "10"
          foreground: root.barForeground
          onChanged: function(value) {
            if (root.hostWidget) root.hostWidget.setIntervalMinutes(Number(value))
          }
        }

        Text {
          width: parent.width
          text: root.formatRemaining()
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
          font.bold: true
        }

        Text {
          visible: root.hostWidget && root.hostWidget.lastError !== ""
          width: parent.width
          text: root.hostWidget ? root.hostWidget.lastError : ""
          color: Color.urgent
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        Button {
          width: parent.width
          text: root.hostWidget && root.hostWidget.rotationEnabled ? "Pause rotation" : "Resume rotation"
          iconText: root.hostWidget && root.hostWidget.rotationEnabled ? "󰏤" : "󰐊"
          foreground: root.barForeground
          onClicked: if (root.hostWidget) root.hostWidget.toggleRotation()
        }

        Button {
          width: parent.width
          text: "Next wallpaper"
          iconText: "󰒭"
          foreground: root.barForeground
          onClicked: if (root.hostWidget) root.hostWidget.nextWallpaper()
        }
        }
      }
    }
  }
}
