{$$, SelectListView} = require 'atom-space-pen-views'
path = require 'path'

module.exports =
class OverrideView extends SelectListView
  initialize: (matches) ->
    super
    @storeFocusedElement()
    @addClass('symbols-view')
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @setLoading('Looking for methods')
    @focusFilterEditor()
    @indent = 0
    @bufferPosition = null

  destroy: ->
    @cancel()
    @panel.destroy()

  viewForItem: ({parent, name, params, moduleName, fileName, line, column}) ->
    if not line
      return $$ ->
        @li class: 'two-lines', =>
          @div "#{parent}.#{name}", class: 'primary-line'
          @div 'builtin', class: 'secondary-line'
    else
      [_, relativePath] = atom.project.relativizePath(fileName)
      return $$ ->
        @li class: 'two-lines', =>
          @div "#{parent}.#{name}", class: 'primary-line'
          @div "#{relativePath}, line #{line}", class: 'secondary-line'

  getFilterKey: -> 'name'

  getEmptyMessage: (itemCount) ->
    if itemCount is 0
      'No methods found'
    else
      super

  confirmed: ({parent, instance, name, params, line, column}) ->
    @cancelPosition = null
    @cancel()
    editor = atom.workspace.getActiveTextEditor()
    tabLength = editor.getTabLength()

    line1 = "def #{name}(#{['self'].concat(params).join(', ')}):"
    superCall = "super(#{instance}, self).#{name}(#{params.join(', ')})"
    if name in ['__init__']
      line2 = "#{superCall}"
    else
      line2 = "return #{superCall}"

    if @indent < 1
      tabText = editor.getTabText()
      editor.insertText("#{tabText}#{line1}")
      editor.insertNewlineBelow()
      editor.setTextInBufferRange [
          [@bufferPosition.row + 1, 0],
          [@bufferPosition.row + 1, tabLength * 2]
        ],
        "#{tabText}#{tabText}#{line2}"

    else
      userIndent = editor.getTextInRange([
        [@bufferPosition.row, 0],
        [@bufferPosition.row, @bufferPosition.column]
      ])
      editor.insertText("#{line1}")
      editor.insertNewlineBelow()
      editor.setTextInBufferRange [
          [@bufferPosition.row + 1, 0],
          [@bufferPosition.row + 1, tabLength * 2]
        ],
        "#{userIndent}#{userIndent}#{line2}"

  cancelled: ->
    @panel?.hide()
