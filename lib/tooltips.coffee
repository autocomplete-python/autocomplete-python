log = require './log'
if atom.config.get('autocomplete-python.enableTouchBar')
  touchbar = require './touchbar'

module.exports =
_showSignatureOverlay: (event) ->
  if @markers
    for marker in @markers
      log.debug 'destroying old marker', marker
      marker.destroy()
  else
    @markers = []

  cursor = event.cursor
  editor = event.cursor.editor
  wordBufferRange = cursor.getCurrentWordBufferRange()
  scopeDescriptor = editor.scopeDescriptorForBufferPosition(
    event.newBufferPosition)
  scopeChain = scopeDescriptor.getScopeChain()

  disableForSelector = "#{@disableForSelector}, .source.python .numeric, .source.python .integer, .source.python .decimal, .source.python .punctuation, .source.python .keyword, .source.python .storage, .source.python .variable.parameter, .source.python .entity.name"
  disableForSelector = @Selector.create(disableForSelector)

  if @selectorsMatchScopeChain(disableForSelector, scopeChain)
    log.debug 'do nothing for this selector'
    return

  marker = editor.markBufferRange(wordBufferRange, {invalidate: 'never'})

  @markers.push(marker)

  getTooltip = (editor, bufferPosition) =>
    payload =
      id: @_generateRequestId('tooltip', editor, bufferPosition)
      lookup: 'tooltip'
      path: editor.getPath()
      source: editor.getText()
      line: bufferPosition.row
      column: bufferPosition.column
      config: @_generateRequestConfig()
    @_sendRequest(@_serialize(payload))
    return new Promise (resolve) =>
      @requests[payload.id] = resolve

  getTooltip(editor, event.newBufferPosition).then (results) =>
    if marker.isDestroyed()
      return
    if results.length > 0
      {text, fileName, line, column, type, description} = results[0]

      description = description.trim()
      if not description
        return
      view = document.createElement('autocomplete-python-suggestion')
      view.appendChild(document.createTextNode(description))
      decoration = editor.decorateMarker(marker, {
        type: 'overlay',
        item: view,
        position: 'head'
      })
      if atom.config.get('autocomplete-python.enableTouchBar')
        touchbar.update(results[0])
