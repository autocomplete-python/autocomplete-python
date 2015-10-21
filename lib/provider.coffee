path = require 'path'
DefinitionsView = require './definitions-view'

module.exports =
  selector: '.source.python'
  disableForSelector: '.source.python .comment, .source.python .string'
  inclusionPriority: 1
  suggestionPriority: 2
  excludeLowerPriority: true

  _issueReportLink: ['If issue persists please report it at https://github.com',
                     '/sadovnychyi/autocomplete-python/issues/new'].join('')

  constructor: ->
    @requests = {}
    @definitionsView = null

    env = process.env
    pythonPath = atom.config.get('autocomplete-python.pythonPath')
    pythonExecutable = atom.config.get('autocomplete-python.pythonExecutable')

    if /^win/.test process.platform
      paths = ['C:\\Python2.7',
               'C:\\Python3.4',
               'C:\\Python3.5',
               'C:\\Program Files (x86)\\Python 2.7',
               'C:\\Program Files (x86)\\Python 3.4',
               'C:\\Program Files (x86)\\Python 3.5',
               'C:\\Program Files (x64)\\Python 2.7',
               'C:\\Program Files (x64)\\Python 3.4',
               'C:\\Program Files (x64)\\Python 3.5',
               'C:\\Program Files\\Python 2.7',
               'C:\\Program Files\\Python 3.4',
               'C:\\Program Files\\Python 3.5']
    else:
      paths = ['/usr/local/bin', '/usr/bin', '/bin', '/usr/sbin', '/sbin']
    path_env = (env.PATH or '').split path.delimiter
    path_env.unshift pythonPath if pythonPath and pythonPath not in path_env
    for p in paths
      if p not in path_env
        path_env.push p
    env.PATH = path_env.join path.delimiter

    pythonEx = if pythonExecutable then pythonExecutable else 'python'

    @provider = require('child_process').spawn(
      pythonEx, [__dirname + '/completion.py'], env: env)

    @provider.on 'error', (err) =>
      if err.code == 'ENOENT'
        atom.notifications.addWarning(
          "autocomplete-python unable to find python executable: please set " +
          "the path to python directory manually in the package settings and " +
          "restart your editor. #{@_issueReportLink}", {
            detail: err,
            dismissable: true})
      else
        atom.notifications.addError(
          "autocomplete-python error. #{@_issueReportLink}", {
            detail: err,
            dismissable: true})
    @provider.on 'exit', (code, signal) =>
      if signal != 'SIGTERM'
        atom.notifications.addError(
          "autocomplete-python provider exit. #{@_issueReportLink}", {
            detail: "exit with code #{code}, signal #{signal}",
            dismissable: true})
    @provider.stderr.on 'data', (err) ->
      if atom.config.get('autocomplete-python.outputProviderErrors')
        atom.notifications.addError(
          'autocomplete-python traceback output:', {
            detail: "#{err}",
            dismissable: true})

    @readline = require('readline').createInterface(input: @provider.stdout)
    @readline.on 'line', (response) => @_deserialize(response)

    atom.commands.add 'atom-text-editor[data-grammar~=python]', 'autocomplete-python:go-to-definition', =>
      if @definitionsView
        @definitionsView.destroy()
      @definitionsView = new DefinitionsView()
      editor = atom.workspace.getActiveTextEditor()
      bufferPosition = editor.getCursorBufferPosition()
      @getDefinitions({editor, bufferPosition}).then (results) =>
        @definitionsView.setItems(results)
        if results.length == 1
          @definitionsView.confirmed(results[0])

  _serialize: (request) ->
    return JSON.stringify(request)

  _deserialize: (response) ->
    response = JSON.parse(response)
    [resolve, reject] = @requests[response['id']]
    resolve(response['results'])

  _generateRequestId: (editor, bufferPosition) ->
    return require('crypto').createHash('md5').update([
      editor.getPath(), editor.getText(), bufferPosition.row,
      bufferPosition.column].join()).digest('hex')

  _generateRequestConfig: () ->
    extraPaths = []

    for path in atom.config.get('autocomplete-python.extraPaths').split(';')
      for project in atom.project.getPaths()
        modified = path.replace('$PROJECT', project)
        if modified not in extraPaths
          extraPaths.push(modified)
    args =
      'extraPaths': extraPaths
      'useSnippets': atom.config.get(
        'autocomplete-python.useSnippets')
      'caseInsensitiveCompletion': atom.config.get(
        'autocomplete-python.caseInsensitiveCompletion')
      'showDescriptions': atom.config.get(
        'autocomplete-python.showDescriptions')
    return args

  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
    if prefix not in ['.', ' '] and (prefix.length < 1 or /\W/.test(prefix))
      return []
    payload =
      id: @_generateRequestId(editor, bufferPosition)
      lookup: 'completions'
      path: editor.getPath()
      source: editor.getText()
      line: bufferPosition.row
      column: bufferPosition.column
      config: @_generateRequestConfig()

    @provider.stdin.write(@_serialize(payload) + '\n')

    return new Promise (resolve, reject) =>
      @requests[payload.id] = [resolve, reject]

  getDefinitions: ({editor, bufferPosition}) ->
    payload =
      id: @_generateRequestId(editor, bufferPosition)
      lookup: 'definitions'
      path: editor.getPath()
      source: editor.getText()
      line: bufferPosition.row
      column: bufferPosition.column
      config: @_generateRequestConfig()

    @provider.stdin.write(@_serialize(payload) + '\n')

    return new Promise (resolve, reject) =>
      @requests[payload.id] = [resolve, reject]

  dispose: ->
    @readline.close()
    @provider.kill()
