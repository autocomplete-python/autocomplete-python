provider = require './provider'

module.exports =
  config:
    caseInsensitiveCompletion:
      type: 'boolean'
      default: true
      title: 'Case Insensitive Completion'
      description: 'The completion is by default case insensitive.'
    addDotAfterModule:
      type: 'boolean'
      default: false
      title: 'Add Dot After Module'
      description: 'Adds a dot after a module, because a module that is not accessed this way is definitely not the normal case.'
    addBracketAfterFunction:
      type: 'boolean'
      default: false
      title: 'Add Bracket After Function'
      description: 'Adds an opening bracket after a function, because that’s normal behaviour.'
    useSnippets:
      type: 'boolean'
      default: false
      title: 'Complete with snippets'
      description: 'Allows to complete functions with their arguments. Use completion key to jump between arguments. Will ignore some settings if used.'
    extraPaths:
      type: 'string'
      default: ''
      title: 'Extra PATH'
      description: 'Comma separated list of modules to additionally include for autocomplete.'

  provider: null

  activate: (state) -> provider.constructor()

  deactivate: -> provider.dispose()

  getProvider: -> provider
