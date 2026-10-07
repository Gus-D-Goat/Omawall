import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.GustavoDGoat.omawall"

  readonly property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  readonly property var intervalValues: [1, 5, 10, 15, 30, 60, 120]

  readonly property string nextScript: {
    var u = Qt.resolvedUrl("scripts/next.sh").toString()
    return u.replace(/^file:\/\//, "")
  }

  property bool rotationEnabled: true
  property int intervalMinutes: 10
  property double nextRotationAt: 0
  property string lastError: ""
  property bool initialized: false
  property bool rotationActive: false
  property bool processActive: false

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function normalizeInterval(value) {
    var candidate = Math.round(Number(value))
    if (root.intervalValues.indexOf(candidate) === -1) return 10
    return candidate
  }

  function parseEnabled(value) {
    if (value === true || value === false) return value
    var text = String(value || "").toLowerCase()
    if (text === "true" || text === "1" || text === "yes") return true
    if (text === "false" || text === "0" || text === "no") return false
    return true
  }

  function applySettings() {
    var nextEnabled = root.parseEnabled(root.setting("enabled", true))
    var nextInterval = root.normalizeInterval(root.setting("intervalMinutes", 10))
    var enabledChanged = nextEnabled !== root.rotationEnabled
    var intervalChanged = nextInterval !== root.intervalMinutes

    root.rotationEnabled = nextEnabled
    root.intervalMinutes = nextInterval

    if (!root.initialized) return
    if (!root.rotationEnabled) root.stopRotation()
    else if (enabledChanged || intervalChanged) root.restartRotation()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    target.bar = root.bar
    target.settings = root.settings
    target.anchorItem = button
    target.hostWidget = root
  }

  function persistSettings() {
    var entry = { id: root.moduleName }
    for (var key in root.settings) if (key !== "id") entry[key] = root.settings[key]
    entry.enabled = root.rotationEnabled
    entry.intervalMinutes = root.intervalMinutes

    root.settings = entry
    root.injectPanel()
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  function setRotationEnabled(value) {
    var next = !!value
    if (next === root.rotationEnabled) return

    root.rotationEnabled = next
    root.persistSettings()
    if (next) root.restartRotation()
    else root.stopRotation()
  }

  function toggleRotation() {
    root.setRotationEnabled(!root.rotationEnabled)
  }

  function setIntervalMinutes(value) {
    var next = root.normalizeInterval(value)
    if (next === root.intervalMinutes) return

    root.intervalMinutes = next
    root.persistSettings()
    if (root.rotationEnabled) root.restartRotation()
  }

  function restartRotation() {
    if (!root.rotationEnabled) {
      root.stopRotation()
      return
    }

    root.nextRotationAt = Date.now() + root.intervalMinutes * 60 * 1000
    root.rotationActive = true
  }

  function stopRotation() {
    root.rotationActive = false
    root.nextRotationAt = 0
  }

  function nextWallpaper() {
    if (root.processActive) return

    root.rotationActive = false
    root.nextRotationAt = 0
    root.processActive = true
  }

  function notifyFailure() {
    root.lastError = "Wallpaper change failed"
    Quickshell.execDetached([
      root.omarchyPath + "/bin/omarchy-notification-send",
      "-a", "Omawall",
      "-u", "normal",
      "-t", "6000",
      "Wallpaper rotation failed",
      "Omawall could not change the wallpaper."
    ])
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function toggle() {
    if (!panelLoader.item) return
    if (root.opened) root.close()
    else root.open()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: root.injectPanel()
  onSettingsChanged: {
    root.injectPanel()
    root.applySettings()
  }

  Component.onCompleted: {
    root.initialized = true
    root.applySettings()
    if (root.rotationEnabled) root.restartRotation()
  }

  Timer {
    id: rotationTimerObject
    interval: root.intervalMinutes * 60 * 1000
    running: root.rotationActive
    onTriggered: root.nextWallpaper()
  }

  Process {
    id: nextWallpaperProcessObject
    command: ["bash", root.nextScript]
    running: root.processActive

    onExited: function(exitCode) {
      root.processActive = false
      if (exitCode !== 0) root.notifyFailure()
      else root.lastError = ""
      if (root.rotationEnabled) root.restartRotation()
    }
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  IpcHandler {
    target: "io.github.GustavoDGoat.omawall"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function next(): void { root.nextWallpaper() }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰸉"
    active: root.rotationEnabled
    tooltipText: root.rotationEnabled
      ? "Omawall: automatic rotation"
      : "Omawall: rotation paused"

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
    }
  }
}
