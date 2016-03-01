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

  destroy: ->
    @cancel()
    @panel.destroy()

  viewForItem: ({parent, name, params, moduleName, fileName, line, column}) ->
    [_, relativePath] = atom.project.relativizePath(fileName)
    return $$ ->
      @li class: 'two-lines', =>
        @div "#{parent}.#{name}", class: 'primary-line'
        @div "#{relativePath}, line #{line}", class: 'secondary-line'

  getFilterKey: -> 'fileName'

  # scrollToItemView: ->
  #   super
  #   {name, moduleName, fileName, line, column} = @getSelectedItem()
  #   editor = atom.workspace.getActiveTextEditor()
  #   if editor.getBuffer().file.path is fileName
  #     editor.setSelectedBufferRange([
  #       [line - 1, column], [line - 1, column + name.length]])
  #     editor.scrollToBufferPosition([line - 1, column], center: true)

  getEmptyMessage: (itemCount) ->
    if itemCount is 0
      'No methods found'
    else
      super

  confirmed: ({parent, name, params, moduleName, fileName, line, column}) ->
    @cancelPosition = null
    @cancel()
    editor = atom.workspace.getActiveTextEditor()
    # def test(self):
    # return super(Bar, self).test()
    editor.insertText("def #{name}(#{params}):\n    return super(#{parent}, self).#{name}.(#{params})")
    # promise = atom.workspace.open(fileName)
    # promise.then (editor) ->
    #   editor.setCursorBufferPosition([line - 1, column])
    #   editor.setSelectedBufferRange([
    #     [line - 1, column], [line - 1, column + name.length]])
    #   editor.scrollToCursorPosition()

  cancelled: ->
    @panel?.hide()
