provider = require './provider'

module.exports =
  priority: 1

  providerName: 'autocomplete-python'

  _getScopes: (editor, range) ->
    return editor.scopeDescriptorForBufferPosition(range).scopes

  getSuggestionForWord: (editor, text, range) ->
    if editor.getGrammar().scopeName == 'source.python'
      if atom.config.get('autocomplete-python.outputDebug')
        provider._log range.start, @_getScopes(editor, range.start)
        provider._log range.end, @_getScopes(editor, range.end)
      callback = ->
        provider.goToDefinition()
      return {range, callback}
