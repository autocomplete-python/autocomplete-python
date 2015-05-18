module.exports =
  selector: '.source.python'
  disableForSelector: '.source.python .comment, .source.python .string'
  inclusionPriority: 1
  suggestionPriority: 2
  excludeLowerPriority: true

  constructor: ->
    console.debug 'Preparing python completions...'
    @requests = {}

    @provider = require('child_process').spawn(
      'python', [__dirname + '/completion.py'])

    @provider.on 'error', (err) =>
      console.error "Python Provider error: #{err}"
      if err.code == 'ENOENT'
        throw "Cannot run python command: check that python is available in the system (path: #{process.env.PATH}): #{err}"
      else
        throw "Python Provider error: #{err}"
    @provider.on 'exit', (code, signal) =>
      console.error "Python Provider exit with code #{code}, signal #{signal}"
      throw "Python Provider exit with code #{code}, signal #{signal}"
    @provider.stderr.on 'data', (err) ->
      console.error "Python Provider error: #{err}"

    @readline = require('readline').createInterface(input: @provider.stdout)
    @readline.on 'line', (response) => @_deserialize(response)

  _serialize: (request) ->
    return JSON.stringify(request)

  _deserialize: (response) ->
    response = JSON.parse(response)
    [resolve, reject] = @requests[response['id']]
    resolve(response['completions'])

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
      'addDotAfterModule': atom.config.get(
        'autocomplete-python.addDotAfterModule')
      'addBracketAfterFunction': atom.config.get(
        'autocomplete-python.addBracketAfterFunction')
    return args

  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
    payload =
      id: @_generateRequestId(editor, bufferPosition)
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
