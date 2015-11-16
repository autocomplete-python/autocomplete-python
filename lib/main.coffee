provider = require './provider'
hyperclickProvider = require './hyperclickProvider'

module.exports =
  config:
    caseInsensitiveCompletion:
      type: 'boolean'
      default: true
      title: 'Case Insensitive Completion'
      description: 'The completion is by default case insensitive.'
    showDescriptions:
      type: 'boolean'
      default: true
      title: 'Show descriptions'
      description: 'Show doc strings from functions, classes, etc.'
    outputProviderErrors:
      type: 'boolean'
      default: false
      title: 'Output Provider Errors'
      description: 'Select if you would like to see the provider errors when they happen. By default they are hidden. Note that critical errors are always shown.'
    outputDebug:
      type: 'boolean'
      default: false
      title: 'Output Debug Logs'
      description: 'Select if you would like to see debug information in developer tools logs. May slow down your editor.'
    useSnippets:
      type: 'string'
      default: 'none'
      enum: ['none', 'all', 'required']
      title: 'Autocomplete Function Parameters'
      description: 'Automatically complete function arguments after typing left parenthesis character. Use completion key to jump between arguments.'
    pythonPath:
      type: 'string'
      default: ''
      title: 'Path to python directory'
      description: 'Optional. Set it if default values are not working for you or you want to use specific python version. For example: `/usr/local/Cellar/python/2.7.3/bin` or `E:\\Python2.7`'
    pythonExecutable:
      type: 'string'
      default: 'python'
      enum: ['python', 'python2', 'python3']
      title: 'Python executable name'
      description: 'Set it if default values are not working for you or you want to use specific python version.'
    extraPaths:
      type: 'string'
      default: ''
      title: 'Extra PATH'
      description: '''Semicolon separated list of modules to additionally include for autocomplete.
      You can use $PROJECT variable here to include project specific folders like virtual environment.
      Note that it still should be valid python package.
      For example: $PROJECT/env/lib/python2.7/site-packages.
      '''
    fuzzyMatcher:
      type: 'boolean'
      default: false
      title: 'Use fuzzy matcher for completions'
      description: 'Typing `stdr` will match `stderr`. May significantly slow down completions on slow machines.'

  activate: (state) -> provider.constructor()

  deactivate: -> provider.dispose()

  getProvider: -> provider

  getHyperclickProvider: -> hyperclickProvider

  consumeSnippets: (snippetsManager) ->
    provider.setSnippetsManager snippetsManager
