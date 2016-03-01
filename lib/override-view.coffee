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

  confirmed: ({parent, name, params, moduleName, fileName, line, column}) ->
    @cancelPosition = null
    @cancel()
    editor = atom.workspace.getActiveTextEditor()
    tabText = editor.getTabText()
    if @indent < 1
      @indent = editor.getTabLength()
    indent = (n) -> Array(n + 1).join(tabText)

    line1 = "#{indent(1)}def #{name}(#{params}):"
    if name in ['__init__']
      line2 = "#{indent(2)}super(#{parent}, self).#{name}(#{params})"
    else
      line2 = "#{indent(2)}return super(#{parent}, self).#{name}(#{params})"

    editor.setTextInBufferRange(
      [[@bufferPosition.row, 0], [@bufferPosition.row + 1, 0]],
      [line1, line2].join('\n')
    )

  cancelled: ->
    @panel?.hide()
