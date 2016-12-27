{CompositeDisposable, Emitter} = require 'atom'

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
      StateController
    } = require 'kite-installer'
    AccountManager.initClient 'alpha.kite.com', -1, true
    atom.views.addViewProvider Installation, (m) -> m.element
    editorCfg =
      UUID: localStorage.getItem('metrics.userId')
      name: 'atom'
    pluginCfg =
      name: 'autocomplete-python'
    dm = new DecisionMaker editorCfg, pluginCfg

    checkKiteInstallation = () =>
      if not atom.config.get 'autocomplete-python.useKite'
        return
      canInstall = StateController.canInstallKite()
      throttle = dm.shouldOfferKite(event)
      Promise.all([throttle, canInstall]).then((values) =>
        atom.config.set 'autocomplete-python.useKite', true
        variant = values[0]
        Metrics.Tracker.name = "atom autocomplete-python install"
        Metrics.Tracker.props = variant
        Metrics.Tracker.props.lastEvent = event
        title = "Choose a autocomplete-python engine"
        @installation = new Installation variant, title
        @installation.accountCreated(() =>
          Metrics.Tracker.trackEvent "account created"
          atom.config.set 'autocomplete-python.useKite', true
        )
        @installation.flowSkipped(() =>
          Metrics.Tracker.trackEvent "flow aborted"
          atom.config.set 'autocomplete-python.useKite', false
        )
        installer = new Installer()
        installer.init @installation.flow
        pane = atom.workspace.getActivePane()
        @installation.flow.onSkipInstall () =>
          atom.config.set 'autocomplete-python.useKite', false
          Metrics.Tracker.trackEvent "skipped kite"
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
