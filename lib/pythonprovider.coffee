module.exports =
class PythonProvider
  selector: '.source.python'
  disableForSelector: '.source.python .comment, .source.python .string'
  inclusionPriority: 1
  excludeLowerPriority: true

  constructor: ->
    @requests = {}
    paths = atom.config.get('autocomplete-plus-python-jedi.extraPaths')
    paths = (p for p in paths.split(',') when p)

    @provider = require('child_process').spawn(
      'python', [__dirname + '/completion.py'].concat(paths))

    @provider.on 'error', (err) =>
      console.log "Python Provider error: #{err}"
    @provider.on 'exit', (code, signal) =>
      console.log "Python Provider exit with code #{code}, signal #{signal}"

    @provider.stderr.on('data', (data) ->
      console.log('Jedi.py Error: ' + data);
    )

    @readline = require('readline').createInterface({
      input: @provider.stdout
      })
    @readline.on('line', (response) => @deserialize(response))

  deserialize: (response) ->
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

    @provider.stdin.write(JSON.stringify(payload) + '\n')

    return new Promise (resolve, reject) =>
      @requests[payload.id] = [resolve, reject]

  dispose: ->
    @readline.close()
    @provider.kill()
