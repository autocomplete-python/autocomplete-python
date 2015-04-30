module.exports =
class PythonProvider
  selector: '.source.python'
  disableForSelector: '.source.python .comment, .source.python .string'
  inclusionPriority: 1
  excludeLowerPriority: true

  constructor: ->
    @requests = {}

    args =
      'extraPaths': atom.config.get(
        'autocomplete-python.extraPaths'),
      'useSnippets': atom.config.get(
        'autocomplete-python.useSnippets'),
      'caseInsensitiveCompletion': atom.config.get(
        'autocomplete-python.caseInsensitiveCompletion'),
      'addDotAfterModule': atom.config.get(
        'autocomplete-python.addDotAfterModule'),
      'addBracketAfterFunction': atom.config.get(
        'autocomplete-python.addBracketAfterFunction'),

    @provider = require('child_process').spawn(
      'python', [__dirname + '/completion.py', @_serialize(args)])

    @provider.on 'error', (err) =>
      console.error "Python Provider error: #{err}"
    @provider.on 'exit', (code, signal) =>
      console.error "Python Provider exit with code #{code}, signal #{signal}"
    @provider.stderr.on 'data', (err) ->
      throw "Python Provider error: #{err}"

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

  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
    payload =
      id: @_generateRequestId(editor, bufferPosition)
      path: editor.getPath()
      source: editor.getText()
      line: bufferPosition.row
      column: bufferPosition.column

    @provider.stdin.write(@_serialize(payload) + '\n')

    return new Promise (resolve, reject) =>
      @requests[payload.id] = [resolve, reject]

  dispose: ->
    @readline.close()
    @provider.kill()
