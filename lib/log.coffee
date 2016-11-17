module.exports =
  prefix: 'pluggy-mcpluginface:'
  debug: (msg...) ->
    if atom.config.get('pluggy-mcpluginface.outputDebug')
      return console.debug @prefix, msg...

  warning: (msg...) ->
    return console.warn @prefix, msg...
