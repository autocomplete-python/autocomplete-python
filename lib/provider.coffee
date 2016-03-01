{Disposable, CompositeDisposable, BufferedProcess} = require 'atom'
{selectorsMatchScopeChain} = require './scope-helpers'
{Selector} = require 'selector-kit'
DefinitionsView = require './definitions-view'
UsagesView = require './usages-view'
OverrideView = require './override-view'
RenameView = require './rename-view'
InterpreterLookup = require './interpreters-lookup'
log = require './log'
_ = require 'underscore'
filter = undefined

module.exports =
  selector: '.source.python'
  disableForSelector: '.source.python .comment, .source.python .string'
  inclusionPriority: 2
  suggestionPriority: 3
  excludeLowerPriority: false
  cacheSize: 10

  _addEventListener: (editor, eventName, handler) ->
    editorView = atom.views.getView editor
    editorView.addEventListener eventName, handler
    disposable = new Disposable ->
      log.debug 'Unsubscribing from event listener ', eventName, handler
      editorView.removeEventListener eventName, handler
    return disposable

  _noExecutableError: (error) ->
    if @providerNoExecutable
      return
    log.warning 'No python executable found', error
    atom.notifications.addWarning(
      'autocomplete-python unable to find python binary.', {
      detail: """Please set path to python executable manually in package
      settings and restart your editor. Be sure to migrate on new settings
      if everything worked on previous version.
      Detailed error message: #{error}

      Current config: #{atom.config.get('autocomplete-python.pythonPaths')}"""
      dismissable: true})
    @providerNoExecutable = true

  _spawnDaemon: ->
    interpreter = InterpreterLookup.getInterpreter()
    log.debug 'Using interpreter', interpreter
    @provider = new BufferedProcess
      command: interpreter or 'python'
      args: [__dirname + '/completion.py']
      stdout: (data) =>
        @_deserialize(data)
      stderr: (data) =>
        if data.indexOf('is not recognized as an internal or external') > -1
          return @_noExecutableError(data)
        log.debug "autocomplete-python traceback output: #{data}"
        if data.indexOf('jedi') > -1
          if atom.config.get('autocomplete-python.outputProviderErrors')
            atom.notifications.addWarning(
              '''Looks like this error originated from Jedi. Please do not
              report such issues in autocomplete-python issue tracker. Report
              them directly to Jedi. Turn off `outputProviderErrors` setting
              to hide such errors in future. Traceback output:''', {
              detail: "#{data}",
              dismissable: true})
        else
          atom.notifications.addError(
            'autocomplete-python traceback output:', {
              detail: "#{data}",
              dismissable: true})
      exit: (code) =>
        log.warning 'Process exit with', code, @provider
    @provider.onWillThrowError ({error, handle}) =>
      if error.code is 'ENOENT' and error.syscall.indexOf('spawn') is 0
        @_noExecutableError(error)
        @dispose()
        handle()
      else
        throw error

    @provider.process?.stdin.on 'error', (err) ->
      log.debug 'stdin', err

    setTimeout =>
      log.debug 'Killing python process after timeout...'
      if @provider and @provider.process
        @provider.kill()
    , 60 * 10 * 1000

  constructor: ->
    @requests = {}
    @responses = {}
    @provider = null
    @disposables = new CompositeDisposable
    @subscriptions = {}
    @definitionsView = null
    @usagesView = null
    @renameView = null
    @snippetsManager = null

    try
      @triggerCompletionRegex = RegExp atom.config.get(
        'autocomplete-python.triggerCompletionRegex')
    catch err
      atom.notifications.addWarning(
        '''autocomplete-python invalid regexp to trigger autocompletions.
        Falling back to default value.''', {
        detail: "Original exception: #{err}"
        dismissable: true})
      atom.config.set('autocomplete-python.triggerCompletionRegex',
                      '([\.\ ]|[a-zA-Z_][a-zA-Z0-9_]*)')
      @triggerCompletionRegex = /([\.\ ]|[a-zA-Z_][a-zA-Z0-9_]*)/

    selector = 'atom-text-editor[data-grammar~=python]'
    atom.commands.add selector, 'autocomplete-python:go-to-definition', =>
      @goToDefinition()
    atom.commands.add selector, 'autocomplete-python:complete-arguments', =>
      editor = atom.workspace.getActiveTextEditor()
      @_completeArguments(editor, editor.getCursorBufferPosition(), true)

    atom.commands.add selector, 'autocomplete-python:show-usages', =>
      editor = atom.workspace.getActiveTextEditor()
      bufferPosition = editor.getCursorBufferPosition()
      if @usagesView
        @usagesView.destroy()
      @usagesView = new UsagesView()
      @getUsages(editor, bufferPosition).then (usages) =>
        @usagesView.setItems(usages)

    atom.commands.add selector, 'autocomplete-python:override-method', =>
      editor = atom.workspace.getActiveTextEditor()
      bufferPosition = editor.getCursorBufferPosition()
      if @overrideView
        @overrideView.destroy()
      @overrideView = new OverrideView()
      @getMethods(editor, bufferPosition).then ({methods, indent, bufferPosition}) =>
        @overrideView.indent = indent
        @overrideView.bufferPosition = bufferPosition
        @overrideView.setItems(methods)

    atom.commands.add selector, 'autocomplete-python:rename', =>
      editor = atom.workspace.getActiveTextEditor()
      bufferPosition = editor.getCursorBufferPosition()
      @getUsages(editor, bufferPosition).then (usages) =>
        if @renameView
          @renameView.destroy()
        if usages.length > 0
          @renameView = new RenameView(usages)
          @renameView.onInput (newName) =>
            for fileName, usages of _.groupBy(usages, 'fileName')
              [project, _relative] = atom.project.relativizePath(fileName)
              if project
                @_updateUsagesInFile(fileName, usages, newName)
              else
                log.debug 'Ignoring file outside of project', fileName
        else
          if @usagesView
            @usagesView.destroy()
          @usagesView = new UsagesView()
          @usagesView.setItems(usages)

    atom.workspace.observeTextEditors (editor) =>
      @_handleGrammarChangeEvent(editor, editor.getGrammar())
      editor.displayBuffer.onDidChangeGrammar (grammar) =>
        @_handleGrammarChangeEvent(editor, grammar)

    atom.config.onDidChange 'autocomplete-plus.enableAutoActivation', =>
      atom.workspace.observeTextEditors (editor) =>
        @_handleGrammarChangeEvent(editor, editor.getGrammar())

  _updateUsagesInFile: (fileName, usages, newName) ->
    columnOffset = {}
    atom.workspace.open(fileName, activateItem: false).then (editor) ->
      buffer = editor.getBuffer()
      for usage in usages
        {name, line, column} = usage
        columnOffset[line] ?= 0
        log.debug 'Replacing', usage, 'with', newName, 'in', editor.id
        log.debug 'Offset for line', line, 'is', columnOffset[line]
        buffer.setTextInRange([
          [line - 1, column + columnOffset[line]],
          [line - 1, column + name.length + columnOffset[line]],
          ], newName)
        columnOffset[line] += newName.length - name.length
      buffer.save()

  _handleGrammarChangeEvent: (editor, grammar) ->
    eventName = 'keyup'
    eventId = "#{editor.displayBuffer.id}.#{eventName}"
    if grammar.scopeName == 'source.python'
      if not atom.config.get('autocomplete-plus.enableAutoActivation')
        log.debug 'Ignoring keyup events due to autocomplete-plus settings.'
        return
      disposable = @_addEventListener editor, eventName, (e) =>
        bracketIdentifiers =
          'U+0028': 'qwerty'
          'U+0038': 'german'
          'U+0035': 'azerty'
          'U+0039': 'other'
        if e.keyIdentifier of bracketIdentifiers
          log.debug 'Trying to complete arguments on keyup event', e
          @_completeArguments(editor, editor.getCursorBufferPosition())
      @disposables.add disposable
      @subscriptions[eventId] = disposable
      log.debug 'Subscribed on event', eventId
    else
      if eventId of @subscriptions
        @subscriptions[eventId].dispose()
        log.debug 'Unsubscribed from event', eventId

  _serialize: (request) ->
    log.debug 'Serializing request to be sent to Jedi', request
    return JSON.stringify(request)

  _sendRequest: (data, respawned) ->
    log.debug 'Pending requests:', Object.keys(@requests).length, @requests
    if Object.keys(@requests).length > 10
      log.debug 'Cleaning up request queue to avoid overflow, ignoring request'
      @requests = {}
      if @provider and @provider.process
        log.debug 'Killing python process'
        @provider.kill()
        return

    if @provider and @provider.process
      process = @provider.process
      if process.exitCode == null and process.signalCode == null
        if @provider.process.pid
          return @provider.process.stdin.write(data + '\n')
        else
          log.debug 'Attempt to communicate with terminated process', @provider
      else if respawned
        atom.notifications.addWarning(
          ["Failed to spawn daemon for autocomplete-python."
           "Completions will not work anymore"
           "unless you restart your editor."].join(' '), {
          detail: ["exitCode: #{process.exitCode}"
                   "signalCode: #{process.signalCode}"].join('\n'),
          dismissable: true})
        @dispose()
      else
        @_spawnDaemon()
        @_sendRequest(data, respawned: true)
        log.debug 'Re-spawning python process...'
    else
      log.debug 'Spawning python process...'
      @_spawnDaemon()
      @_sendRequest(data)

  _deserialize: (response) ->
    log.debug 'Deserealizing response from Jedi', response
    log.debug "Got #{response.trim().split('\n').length} lines"
    for responseSource in response.trim().split('\n')
      response = JSON.parse(responseSource)
      if response['arguments']
        editor = @requests[response['id']]
        if typeof editor == 'object'
          bufferPosition = editor.getCursorBufferPosition()
          # Compare response ID with current state to avoid stale completions
          if response['id'] == @_generateRequestId(editor, bufferPosition)
            @snippetsManager?.insertSnippet(response['arguments'], editor)
      else
        resolve = @requests[response['id']]
        if typeof resolve == 'function'
          resolve(response['results'])
      cacheSizeDelta = Object.keys(@responses).length > @cacheSize
      if cacheSizeDelta > 0
        ids = Object.keys(@responses).sort (a, b) =>
          return @responses[a]['timestamp'] - @responses[b]['timestamp']
        for id in ids.slice(0, cacheSizeDelta)
          log.debug 'Removing old item from cache with ID', id
          delete @responses[id]
      @responses[response['id']] =
        source: responseSource
        timestamp: Date.now()
      log.debug 'Cached request with ID', response['id']
      delete @requests[response['id']]

  _generateRequestId: (editor, bufferPosition, text) ->
    if not text
      text = editor.getText()
    return require('crypto').createHash('md5').update([
      editor.getPath(), text, bufferPosition.row,
      bufferPosition.column].join()).digest('hex')

  _generateRequestConfig: ->
    extraPaths = InterpreterLookup.applySubstitutions(
      atom.config.get('autocomplete-python.extraPaths').split(';'))
    args =
      'extraPaths': extraPaths
      'useSnippets': atom.config.get('autocomplete-python.useSnippets')
      'caseInsensitiveCompletion': atom.config.get(
        'autocomplete-python.caseInsensitiveCompletion')
      'showDescriptions': atom.config.get(
        'autocomplete-python.showDescriptions')
      'fuzzyMatcher': atom.config.get('autocomplete-python.fuzzyMatcher')
    return args

  setSnippetsManager: (@snippetsManager) ->

  _completeArguments: (editor, bufferPosition, force) ->
    useSnippets = atom.config.get('autocomplete-python.useSnippets')
    if not force and useSnippets == 'none'
      atom.commands.dispatch(document.querySelector('atom-text-editor'),
                             'autocomplete-plus:activate')
      return
    scopeDescriptor = editor.scopeDescriptorForBufferPosition(bufferPosition)
    scopeChain = scopeDescriptor.getScopeChain()
    disableForSelector = Selector.create(@disableForSelector)
    if selectorsMatchScopeChain(disableForSelector, scopeChain)
      log.debug 'Ignoring argument completion inside of', scopeChain
      return

    # we don't want to complete arguments inside of existing code
    lines = editor.getBuffer().getLines()
    line = lines[bufferPosition.row]
    prefix = line.slice(bufferPosition.column - 1, bufferPosition.column)
    if prefix isnt '('
      log.debug 'Ignoring argument completion with prefix', prefix
      return
    suffix = line.slice bufferPosition.column, line.length
    if not /^(\)(?:$|\s)|\s|$)/.test(suffix)
      log.debug 'Ignoring argument completion with suffix', suffix
      return

    payload =
      id: @_generateRequestId(editor, bufferPosition)
      lookup: 'arguments'
      path: editor.getPath()
      source: editor.getText()
      line: bufferPosition.row
      column: bufferPosition.column
      config: @_generateRequestConfig()

    @_sendRequest(@_serialize(payload))
    return new Promise =>
      @requests[payload.id] = editor

  _fuzzyFilter: (candidates, query) ->
    if candidates.length isnt 0 and query not in [' ', '.', '(']
      filter ?= require('fuzzaldrin-plus').filter
      candidates = filter(candidates, query, key: 'text')
    return candidates

  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
    if not @triggerCompletionRegex.test(prefix)
      return []
    bufferPosition =
      row: bufferPosition.row
      column: bufferPosition.column
    lines = editor.getBuffer().getLines()
    if atom.config.get('autocomplete-python.fuzzyMatcher')
      # we want to do our own filtering, hide any existing suffix from Jedi
      line = lines[bufferPosition.row]
      lastIdentifier = /\.?[a-zA-Z_][a-zA-Z0-9_]*$/.exec(
        line.slice 0, bufferPosition.column)
      if lastIdentifier
        bufferPosition.column = lastIdentifier.index + 1
        lines[bufferPosition.row] = line.slice(0, bufferPosition.column)
    requestId = @_generateRequestId(editor, bufferPosition, lines.join('\n'))
    if requestId of @responses
      log.debug 'Using cached response with ID', requestId
      # We have to parse JSON on each request here to pass only a copy
      matches = JSON.parse(@responses[requestId]['source'])['results']
      if atom.config.get('autocomplete-python.fuzzyMatcher')
        return @_fuzzyFilter(matches, prefix)
      else
        return matches
    payload =
      id: requestId
      prefix: prefix
      lookup: 'completions'
      path: editor.getPath()
      source: editor.getText()
      line: bufferPosition.row
      column: bufferPosition.column
      config: @_generateRequestConfig()

    @_sendRequest(@_serialize(payload))
    return new Promise (resolve) =>
      if atom.config.get('autocomplete-python.fuzzyMatcher')
        @requests[payload.id] = (matches) =>
          resolve(@_fuzzyFilter(matches, prefix))
      else
        @requests[payload.id] = resolve

  getDefinitions: (editor, bufferPosition) ->
    payload =
      id: @_generateRequestId(editor, bufferPosition)
      lookup: 'definitions'
      path: editor.getPath()
      source: editor.getText()
      line: bufferPosition.row
      column: bufferPosition.column
      config: @_generateRequestConfig()

    @_sendRequest(@_serialize(payload))
    return new Promise (resolve) =>
      @requests[payload.id] = resolve

  getUsages: (editor, bufferPosition) ->
    payload =
      id: @_generateRequestId(editor, bufferPosition)
      lookup: 'usages'
      path: editor.getPath()
      source: editor.getText()
      line: bufferPosition.row
      column: bufferPosition.column
      config: @_generateRequestConfig()

    @_sendRequest(@_serialize(payload))
    return new Promise (resolve) =>
      @requests[payload.id] = resolve

  getMethods: (editor, bufferPosition) ->
    indent = bufferPosition.column
    lines = editor.getBuffer().getLines()
    lines.splice(bufferPosition.row + 1, 0, "  def __autocomplete_python(s):")
    lines.splice(bufferPosition.row + 2, 0, "    s.")
    payload =
      id: @_generateRequestId(editor, bufferPosition)
      lookup: 'methods'
      path: editor.getPath()
      source: lines.join('\n')
      line: bufferPosition.row + 2
      column: 6
      config: @_generateRequestConfig()

    @_sendRequest(@_serialize(payload))
    return new Promise (resolve) =>
      @requests[payload.id] = (methods) ->
        resolve({methods, indent, bufferPosition})

  goToDefinition: (editor, bufferPosition) ->
    if not editor
      editor = atom.workspace.getActiveTextEditor()
    if not bufferPosition
      bufferPosition = editor.getCursorBufferPosition()
    if @definitionsView
      @definitionsView.destroy()
    @definitionsView = new DefinitionsView()
    @getDefinitions(editor, bufferPosition).then (results) =>
      @definitionsView.setItems(results)
      if results.length == 1
        @definitionsView.confirmed(results[0])

  dispose: ->
    @disposables.dispose()
    if @provider
      @provider.kill()
