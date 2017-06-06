module.exports =
  priority: 1
  providerName: 'autocomplete-python'
  disableForSelector: '.source.python .comment, .source.python .string, .source.python .numeric, .source.python .integer, .source.python .decimal, .source.python .punctuation, .source.python .keyword, .source.python .storage, .source.python .variable.parameter, .source.python .entity.name'
  constructed: false

  constructor: ->
    @provider = require './provider'
    @log = require './log'
    {@selectorsMatchScopeChain} = require './scope-helpers'
    {@Selector} = require 'selector-kit'
    @constructed = true
    @log.debug 'Loading python hyper-click provider...'

  _getScopes: (editor, range) ->
    return editor.scopeDescriptorForBufferPosition(range).scopes

  getSuggestionForWord: (editor, text, range) ->
    if not @constructed
      @constructor()
    if text in ['.', ':']
      return
    if editor.getGrammar().scopeName.indexOf('source.python') > -1
      bufferPosition = range.start
      scopeDescriptor = editor.scopeDescriptorForBufferPosition(
        bufferPosition)
      scopeChain = scopeDescriptor.getScopeChain()
      disableForSelector = @Selector.create(@disableForSelector)
      if @selectorsMatchScopeChain(disableForSelector, scopeChain)
        return

      if atom.config.get('autocomplete-python.outputDebug')
        @log.debug range.start, @_getScopes(editor, range.start)
        @log.debug range.end, @_getScopes(editor, range.end)
      callback = =>
        @provider.load().goToDefinition(editor, bufferPosition)
      return {range, callback}
