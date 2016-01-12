provider = require './provider'
log = require './log'
{selectorsMatchScopeChain} = require './scope-helpers'
{Selector} = require 'selector-kit'

module.exports =
  priority: 1

  providerName: 'autocomplete-python'

  disableForSelector: "#{provider.disableForSelector}, .source.python .numeric, .source.python .integer, .source.python .decimal, .source.python .punctuation, .source.python .keyword, .source.python .storage, .source.python .variable.parameter, .source.python .entity.name"

  _getScopes: (editor, range) ->
    return editor.scopeDescriptorForBufferPosition(range).scopes

  getSuggestionForWord: (editor, text, range) ->
    if text in ['.', ':']
      return
    if editor.getGrammar().scopeName == 'source.python'
      bufferPosition = range.start
      scopeDescriptor = editor.scopeDescriptorForBufferPosition(
        bufferPosition)
      scopeChain = scopeDescriptor.getScopeChain()
      disableForSelector = Selector.create(@disableForSelector)
      if selectorsMatchScopeChain(disableForSelector, scopeChain)
        return

      if atom.config.get('autocomplete-python.outputDebug')
        log.debug range.start, @_getScopes(editor, range.start)
        log.debug range.end, @_getScopes(editor, range.end)
      callback = ->
        provider.goToDefinition(editor, bufferPosition)
      return {range, callback}
