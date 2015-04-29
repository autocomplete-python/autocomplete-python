module.exports =
  config:
    completeArguments:
      type: 'boolean'
      default: true
      title: "Complete Arguments for Functions"
      description: "This will cause the suggestions for functions to include their arguments."
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
    PythonProvider = require('./pythonprovider')
    @provider = new PythonProvider()
    return @provider

  provide: ->
    return @getProvider()
