{$$, SelectListView} = require 'atom-space-pen-views'

module.exports =
class DefinitionsView extends SelectListView
  initialize: (matches) ->
    super
    @addClass('symbols-view')
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @setLoading('Looking for definitions')
    @focusFilterEditor()

  destroy: ->
    @cancel()
    @panel.destroy()

  viewForItem: ({text, path, line, column, type}) ->
    return $$ ->
      @li class: 'two-lines', =>
        @div "#{type} #{text}", class: 'primary-line'
        @div "#{path}, line #{line}", class: 'secondary-line'

  getFilterKey: -> 'path'

  getEmptyMessage: (itemCount) ->
    if itemCount is 0
      'No definition found'
    else
      super

  confirmed: ({path, line, column}) ->
    @cancelPosition = null
    @cancel()
    promise = atom.workspace.open(path)
    promise.then (editor) ->
      editor.setCursorBufferPosition([line, column])
      editor.scrollToCursorPosition()

  cancelled: ->
    @panel.hide()
