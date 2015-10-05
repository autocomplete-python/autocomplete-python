{$$, SelectListView} = require 'atom-space-pen-views'
path = require 'path'

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

  viewForItem: ({text, fileName, line, column, type}) ->
    for projectPath in atom.project.getPaths()
      relativePath = path.relative(projectPath, fileName)
      if relativePath.indexOf('..') != 0
        fileName = relativePath
        break
    return $$ ->
      @li class: 'two-lines', =>
        @div "#{type} #{text}", class: 'primary-line'
        @div "#{fileName}, line #{line + 1}", class: 'secondary-line'

  getFilterKey: -> 'fileName'

  getEmptyMessage: (itemCount) ->
    if itemCount is 0
      'No definition found'
    else
      super

  confirmed: ({fileName, line, column}) ->
    @cancelPosition = null
    @cancel()
    promise = atom.workspace.open(fileName)
    promise.then (editor) ->
      editor.setCursorBufferPosition([line, column])
      editor.scrollToCursorPosition()

  cancelled: ->
    @panel.hide()
