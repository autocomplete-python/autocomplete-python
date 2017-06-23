{TouchBar} = require('remote')

spinning = false

module.exports =
  update: (data) ->
    if not TouchBar
      return
    {TouchBarLabel, TouchBarButton, TouchBarSpacer} = TouchBar
    button = new TouchBarButton({
      label: "#{data.text}: #{data.description.trim().split('\n')[0]}",
      backgroundColor: '#353232',
      click: () ->
        promise = atom.workspace.open(data.fileName)
        promise.then (editor) ->
          editor.setCursorBufferPosition([data.line, data.column])
          editor.scrollToCursorPosition()
    })
    touchBar = new TouchBar([
      button,
      new TouchBarSpacer({size: 'small'}),
    ])
    window = atom.getCurrentWindow()
    window.setTouchBar(touchBar)
