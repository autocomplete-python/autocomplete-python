module.exports =
  prefix: 'autocomplete-python:'
  debug: (msg...) ->
    if atom.config.get('autocomplete-python.outputDebug')
      return console.debug @prefix, msg...

  warning: (msg...) ->
    return console.warn @prefix, msg...
