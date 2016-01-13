{View} = require 'space-pen'
{TextEditorView} = require 'atom-space-pen-views'

module.exports =
class RenameView extends View
  initialize: ->
    @panel ?= atom.workspace.addModalPanel(item: @, visible: true)
    atom.commands.add(@element, 'core:cancel', => @destroy())

  destroy: ->
    @panel.hide()
    @.focusout()
    @panel.destroy()

  @content: (usages) ->
    n = usages.length
    name = usages[0].name
    @div =>
      @div "Type new name to replace #{n} occurences of #{name} within project:"
      @subview 'miniEditor', new TextEditorView
        mini: true, placeholderText: name

  onInput: (callback) ->
    @miniEditor.focus()
    atom.commands.add @element, 'core:confirm': =>
      callback(@miniEditor.getText())
      @destroy()
