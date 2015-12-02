provider = require './provider'
hyperclickProvider = require './hyperclickProvider'

module.exports =
  config:
    showDescriptions:
      type: 'boolean'
      default: true
      order: 1
      title: 'Show descriptions'
      description: 'Show doc strings from functions, classes, etc.'
    useSnippets:
      type: 'string'
      default: 'none'
      order: 2
      enum: ['none', 'all', 'required']
      title: 'Autocomplete Function Parameters'
      description: '''Automatically complete function arguments after typing
      left parenthesis character. Use completion key to jump between
      arguments.'''
    pythonPaths:
      type: 'string'
      default: ''
      order: 3
      title: 'Python executable paths'
      description: '''Optional semicolon separated list of paths to python
      executables (including executable names), where the first one will take
      higher priority over the last one. By default autocomplete-python will
      automatically look for venvs inside of your project and try to use them
      as well as try to find global python executable.
      Use $PROJECT variable for project specific paths to point on executables
      in virtual environments.
      For example: `$PROJECT/env/bin/python3;/usr/bin/python`.
      Such config will fall back on `/usr/bin/python` for projects without venv.
      If you are using python3 executable while coding for python2 you will get
      python2 completions for some built-ins.'''
    extraPaths:
      type: 'string'
      default: ''
      order: 4
      title: 'Extra PATH'
      description: '''Semicolon separated list of modules to additionally
      include for autocomplete. You can use $PROJECT variable here to include
      project specific folders like virtual environment.
      Note that it still should be valid python package.
      For example: $PROJECT/env/lib/python2.7/site-packages.
      You don't need to specify extra paths for libraries installed with python
      executable you use.'''
    caseInsensitiveCompletion:
      type: 'boolean'
      default: true
      order: 5
      title: 'Case Insensitive Completion'
      description: 'The completion is by default case insensitive.'
    fuzzyMatcher:
      type: 'boolean'
      default: false
      order: 6
      title: 'Use fuzzy matcher for completions'
      description: '''Typing `stdr` will match `stderr`. May significantly slow
      down completions on slow machines.'''
    outputProviderErrors:
      type: 'boolean'
      default: false
      order: 6
      title: 'Output Provider Errors'
      description: '''Select if you would like to see the provider errors when
      they happen. By default they are hidden. Note that critical errors are
      always shown.'''
    outputDebug:
      type: 'boolean'
      default: false
      order: 7
      title: 'Output Debug Logs'
      description: '''Select if you would like to see debug information in
      developer tools logs. May slow down your editor.'''

  activate: (state) -> provider.constructor()

  deactivate: -> provider.dispose()

  getProvider: -> provider

  getHyperclickProvider: -> hyperclickProvider

  consumeSnippets: (snippetsManager) ->
    provider.setSnippetsManager snippetsManager
