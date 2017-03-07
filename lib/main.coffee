os = require 'os'
path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'

[Metrics, Logger] = []

window.DEBUG = false
module.exports =
  config:
    useKite:
      type: 'boolean'
      default: true
      order: 0
      title: 'Use Kite-powered Completions (macOS only)'
      description: '''Kite is a cloud powered autocomplete engine. It provides
      significantly more autocomplete suggestions than the local Jedi engine.'''
    showDescriptions:
      type: 'boolean'
      default: true
      order: 1
      title: 'Show Descriptions'
      description: 'Show doc strings from functions, classes, etc.'
    useSnippets:
      type: 'string'
      default: 'none'
      order: 2
      enum: ['none', 'all', 'required']
      title: 'Autocomplete Function Parameters'
      description: '''Automatically complete function arguments after typing
      left parenthesis character. Use completion key to jump between
      arguments. See `autocomplete-python:complete-arguments` command if you
      want to trigger argument completions manually. See README if it does not
      work for you.'''
    pythonPaths:
      type: 'string'
      default: ''
      order: 3
      title: 'Python Executable Paths'
      description: '''Optional semicolon separated list of paths to python
      executables (including executable names), where the first one will take
      higher priority over the last one. By default autocomplete-python will
      automatically look for virtual environments inside of your project and
      try to use them as well as try to find global python executable. If you
      use this config, automatic lookup will have lowest priority.
      Use `$PROJECT` or `$PROJECT_NAME` substitution for project-specific
      paths to point on executables in virtual environments.
      For example:
      `/Users/name/.virtualenvs/$PROJECT_NAME/bin/python;$PROJECT/venv/bin/python3;/usr/bin/python`.
      Such config will fall back on `/usr/bin/python` for projects not presented
      with same name in `.virtualenvs` and without `venv` folder inside of one
      of project folders.
      If you are using python3 executable while coding for python2 you will get
      python2 completions for some built-ins.'''
    extraPaths:
      type: 'string'
      default: ''
      order: 4
      title: 'Extra Paths For Packages'
      description: '''Semicolon separated list of modules to additionally
      include for autocomplete. You can use same substitutions as in
      `Python Executable Paths`.
      Note that it still should be valid python package.
      For example:
      `$PROJECT/env/lib/python2.7/site-packages`
      or
      `/User/name/.virtualenvs/$PROJECT_NAME/lib/python2.7/site-packages`.
      You don't need to specify extra paths for libraries installed with python
      executable you use.'''
    caseInsensitiveCompletion:
      type: 'boolean'
      default: true
      order: 5
      title: 'Case Insensitive Completion'
      description: 'The completion is by default case insensitive.'
    triggerCompletionRegex:
      type: 'string'
      default: '([\.\ (]|[a-zA-Z_][a-zA-Z0-9_]*)'
      order: 6
      title: 'Regex To Trigger Autocompletions'
      description: '''By default completions triggered after words, dots, spaces
      and left parenthesis. You will need to restart your editor after changing
      this.'''
    fuzzyMatcher:
      type: 'boolean'
      default: true
      order: 7
      title: 'Use Fuzzy Matcher For Completions.'
      description: '''Typing `stdr` will match `stderr`.
      First character should always match. Uses additional caching thus
      completions should be faster. Note that this setting does not affect
      built-in autocomplete-plus provider.'''
    outputProviderErrors:
      type: 'boolean'
      default: false
      order: 8
      title: 'Output Provider Errors'
      description: '''Select if you would like to see the provider errors when
      they happen. By default they are hidden. Note that critical errors are
      always shown.'''
    outputDebug:
      type: 'boolean'
      default: false
      order: 9
      title: 'Output Debug Logs'
      description: '''Select if you would like to see debug information in
      developer tools logs. May slow down your editor.'''
    showTooltips:
      type: 'boolean'
      default: false
      order: 10
      title: 'Show Tooltips with information about the object under the cursor'
      description: '''EXPERIMENTAL FEATURE WHICH IS NOT FINISHED YET.
      Feedback and ideas are welcome on github.'''
    suggestionPriority:
      type: 'integer'
      default: 3
      minimum: 0
      maximum: 99
      order: 11
      title: 'Suggestion Priority'
      description: '''You can use this to set the priority for autocomplete-python
      suggestions. For example, you can use lower value to give higher priority
      for snippets completions which has priority of 2.'''

  installation: null

  _handleGrammarChangeEvent: (grammar) ->
    # this should be same with activationHooks names
    if grammar.packageName in ['language-python', 'MagicPython', 'atom-django']
      @provider.load()
      @emitter.emit 'did-load-provider'
      @disposables.dispose()

  _loadKite: ->
    firstInstall = localStorage.getItem('autocomplete-python.installed') == null
    localStorage.setItem('autocomplete-python.installed', true)
    longRunning = require('process').uptime() > 10
    if firstInstall and longRunning
      event = "installed"
    else if firstInstall
      event = "upgraded"
    else
      event = "restarted"

    {
      AccountManager,
      AtomHelper,
      DecisionMaker,
      Installation,
      Installer,
      Metrics,
      Logger,
      StateController
    } = require 'kite-installer'

    if atom.config.get('kite.loggingLevel')
      Logger.LEVEL = Logger.LEVELS[atom.config.get('kite.loggingLevel').toUpperCase()]

    AccountManager.initClient 'alpha.kite.com', -1, true
    atom.views.addViewProvider Installation, (m) -> m.element
    editorCfg =
      UUID: localStorage.getItem('metrics.userId')
      name: 'atom'
    pluginCfg =
      name: 'autocomplete-python'
    dm = new DecisionMaker editorCfg, pluginCfg

    Metrics.Tracker.name = "atom acp"

    atom.packages.onDidActivatePackage (pkg) =>
      if pkg.name is 'kite'
        @patchKiteCompletions(pkg)
        Metrics.Tracker.name = "atom kite+acp"

    checkKiteInstallation = () =>
      if not atom.config.get 'autocomplete-python.useKite'
        return
      canInstall = StateController.canInstallKite()
      throttle = dm.shouldOfferKite(event)
      Promise.all([throttle, canInstall]).then((values) =>
        atom.config.set 'autocomplete-python.useKite', true
        variant = values[0]
        Metrics.Tracker.props = variant
        Metrics.Tracker.props.lastEvent = event
        title = "Choose a autocomplete-python engine"
        @installation = new Installation variant, title
        @installation.accountCreated(() =>
          @track "account created"
          atom.config.set 'autocomplete-python.useKite', true
        )
        @installation.flowSkipped(() =>
          @track "flow aborted"
          atom.config.set 'autocomplete-python.useKite', false
        )
        [projectPath] = atom.project.getPaths()
        root = if projectPath? and path.relative(os.homedir(), projectPath).indexOf('..') is 0
          path.parse(projectPath).root
        else
          os.homedir()

        installer = new Installer([root])
        installer.init @installation.flow, ->
          Logger.verbose('in onFinish')
          atom.packages.activatePackage('kite')

        pane = atom.workspace.getActivePane()
        @installation.flow.onSkipInstall () =>
          atom.config.set 'autocomplete-python.useKite', false
          @track "skipped kite"
          pane.destroyActiveItem()
        pane.addItem @installation, index: 0
        pane.activateItemAtIndex 0
      , (err) =>
        if err.type == 'denied'
          atom.config.set 'autocomplete-python.useKite', false
      ) if atom.config.get 'autocomplete-python.useKite'

    checkKiteInstallation()

    atom.config.onDidChange 'autocomplete-python.useKite', ({ newValue, oldValue }) ->
      if newValue
        checkKiteInstallation()
        AtomHelper.enablePackage()
      else
        AtomHelper.disablePackage()

  load: ->
    @disposables = new CompositeDisposable
    disposable = atom.workspace.observeTextEditors (editor) =>
      @_handleGrammarChangeEvent(editor.getGrammar())
      disposable = editor.onDidChangeGrammar (grammar) =>
        @_handleGrammarChangeEvent(grammar)
      @disposables.add disposable
    @disposables.add disposable
    @_loadKite()
    @trackCompletions()

  activate: (state) ->
    @emitter = new Emitter
    @provider = require('./provider')
    if typeof atom.packages.hasActivatedInitialPackages == 'function' and
        atom.packages.hasActivatedInitialPackages()
      @load()
    else
      disposable = atom.packages.onDidActivateInitialPackages =>
        @load()
        disposable.dispose()

  deactivate: ->
    @provider.dispose() if @provider
    @installation.destroy() if @installation

  getProvider: ->
    return @provider

  getHyperclickProvider: ->
    return require('./hyperclick-provider')

  consumeSnippets: (snippetsManager) ->
    disposable = @emitter.on 'did-load-provider', =>
      @provider.setSnippetsManager snippetsManager
      disposable.dispose()

  trackCompletions: ->
    promises = [atom.packages.activatePackage('autocomplete-plus')]

    if atom.packages.getLoadedPackage('kite')?

      @disposables.add atom.config.observe 'kite.loggingLevel', (level) ->
        Logger.LEVEL = Logger.LEVELS[(level ? 'info').toUpperCase()]

      promises.push(atom.packages.activatePackage('kite'))
      Metrics.Tracker.name = "atom kite+acp"

    Promise.all(promises).then ([autocompletePlus, kite]) =>
      if kite?
        @patchKiteCompletions(kite)

      autocompleteManager = autocompletePlus.mainModule.getAutocompleteManager()

      return unless autocompleteManager? and autocompleteManager.confirm? and autocompleteManager.displaySuggestions?

      safeConfirm = autocompleteManager.confirm
      safeDisplaySuggestions = autocompleteManager.displaySuggestions
      autocompleteManager.displaySuggestions = (suggestions, options) =>
        @trackSuggestions(suggestions, autocompleteManager.editor)
        safeDisplaySuggestions.call(autocompleteManager, suggestions, options)

      autocompleteManager.confirm = (suggestion) =>
        @trackUsedSuggestion(suggestion, autocompleteManager.editor)
        safeConfirm.call(autocompleteManager, suggestion)

  trackSuggestions: (suggestions, editor) ->
    if /\.py$/.test(editor.getPath()) and @kiteProvider?
      hasKiteSuggestions = suggestions.some (s) => s.provider is @kiteProvider
      hasJediSuggestions = suggestions.some (s) => s.provider is @provider

      if hasKiteSuggestions and hasJediSuggestions
        @track 'Atom shows both Kite and Jedi completions'
      else if hasKiteSuggestions
        @track 'Atom shows Kite but not Jedi completions'
      else if hasJediSuggestions
        @track 'Atom shows Jedi but not Kite completions'
      else
        @track 'Atom shows neither Kite nor Jedi completions'

  patchKiteCompletions: (kite) ->
    return if @kitePackage?

    @kitePackage = kite.mainModule
    @kiteProvider = @kitePackage.completions()
    getSuggestions = @kiteProvider.getSuggestions
    @kiteProvider.getSuggestions = (args...) =>
      getSuggestions?.apply(@kiteProvider, args)
      ?.then (suggestions) =>
        @lastKiteSuggestions = suggestions
        @kiteSuggested = suggestions?
        suggestions
      ?.catch (err) =>
        @lastKiteSuggestions = []
        @kiteSuggested = false
        throw err

  trackUsedSuggestion: (suggestion, editor) ->
    if /\.py$/.test(editor.getPath())
      if @kiteProvider?
        if @lastKiteSuggestions?
          if suggestion in @lastKiteSuggestions
            altSuggestion = @hasSameSuggestion(suggestion, @provider.lastSuggestions or [])
            if altSuggestion?
              @track 'used completion returned by Kite but also returned by Jedi', {
                kiteHasDocumentation: @hasDocumentation(suggestion)
                jediHasDocumentation: @hasDocumentation(altSuggestion)
              }
            else
              @track 'used completion returned by Kite but not Jedi', {
                kiteHasDocumentation: @hasDocumentation(suggestion)
              }
          else if @provider.lastSuggestions and  suggestion in @provider.lastSuggestions
            altSuggestion = @hasSameSuggestion(suggestion, @lastKiteSuggestions)
            if altSuggestion?
              @track 'used completion returned by Jedi but also returned by Kite', {
                kiteHasDocumentation: @hasDocumentation(altSuggestion)
                jediHasDocumentation: @hasDocumentation(suggestion)
              }
            else
              if @kitePackage.isEditorWhitelisted?
                if @kitePackage.isEditorWhitelisted(editor)
                  @track 'used completion returned by Jedi but not Kite (whitelisted filepath)', {
                    jediHasDocumentation: @hasDocumentation(suggestion)
                  }
                else
                  @track 'used completion returned by Jedi but not Kite (non-whitelisted filepath)', {
                    jediHasDocumentation: @hasDocumentation(suggestion)
                  }
              else
                @track 'used completion returned by Jedi but not Kite (whitelisted filepath)', {
                  jediHasDocumentation: @hasDocumentation(suggestion)
                }
          else
            @track 'used completion from neither Kite nor Jedi'
        else
          if @kitePackage.isEditorWhitelisted?
            if @kitePackage.isEditorWhitelisted(editor)
              @track 'used completion returned by Jedi but not Kite (whitelisted filepath)', {
                jediHasDocumentation: @hasDocumentation(suggestion)
              }
            else
              @track 'used completion returned by Jedi but not Kite (non-whitelisted filepath)', {
                jediHasDocumentation: @hasDocumentation(suggestion)
              }
          else
            @track 'used completion returned by Jedi but not Kite (not-whitelisted filepath)', {
              jediHasDocumentation: @hasDocumentation(suggestion)
            }
      else
        if @provider.lastSuggestions and suggestion in @provider.lastSuggestions
          @track 'used completion returned by Jedi', {
            jediHasDocumentation: @hasDocumentation(suggestion)
          }
        else
          @track 'used completion not returned by Jedi'

  hasSameSuggestion: (suggestion, suggestions) ->
    suggestions.filter((s) -> s.text is suggestion.text)[0]

  hasDocumentation: (suggestion) ->
    (suggestion.description? and suggestion.description isnt '') or
    (suggestion.descriptionMarkdown? and suggestion.descriptionMarkdown isnt '')

  track: (msg, data) ->
    try
      Metrics.Tracker.trackEvent msg, data
    catch e
      # TODO: this should be removed after kite-installer is fixed
      if e instanceof TypeError
        console.error(e)
      else
        throw e
