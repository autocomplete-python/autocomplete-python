module.exports =
  config:
    useSnippets:
      type: 'boolean'
      default: false
      title: 'Complete with snippets'
      description: 'Allows to complete functions with their arguments. Use completion key to jump between arguments.'
    extraPaths:
      type: 'string'
      default: ''
      title: 'Extra PATH'
      description: 'Comma separated list of modules to additionally include for autocomplete.'

  provider: null

  activate: (state) ->

  deactivate: ->
    @provider = null

  getProvider: ->
    return @provider if @provider?
    PythonProvider = require('./python-provider')
    @provider = new PythonProvider()
    return @provider

  provide: ->
    return @getProvider()
