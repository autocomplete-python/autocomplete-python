{$$, SelectListView} = require 'atom-space-pen-views'
path = require 'path'

module.exports =
class InterpretersView extends SelectListView
  initialize: (matches) ->
    super
    @addClass('symbols-view')
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @setLoading('Looking for interpreters')
    @focusFilterEditor()

  destroy: ->
    @cancel()
    @panel.destroy()

  viewForItem: (fileName) ->
    return $$ ->
      @li "#{fileName}"

  confirmed: (fileName) ->
    @cancelPosition = null
    @cancel()
    console.log(fileName)

  cancelled: ->
    @panel.hide()
