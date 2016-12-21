packagesToTest =
  Python:
    name: 'language-python'
    file: 'test.py'

describe 'Python autocompletions', ->
  [editor, provider] = []

  getCompletions = ->
    cursor = editor.getLastCursor()
    start = cursor.getBeginningOfCurrentWordBufferPosition()
    end = cursor.getBufferPosition()
    prefix = editor.getTextInRange([start, end])
    request =
      editor: editor
      bufferPosition: end
      scopeDescriptor: cursor.getScopeDescriptor()
      prefix: prefix
    provider.getSuggestions(request)

  beforeEach ->
    waitsForPromise -> atom.packages.activatePackage('language-python')
    waitsForPromise -> atom.workspace.open('test.py')
    runs ->
      editor = atom.workspace.getActiveTextEditor()
      editor.setGrammar(atom.grammars.grammarsByScopeName['source.python'])
      atom.packages.loadPackage('autocomplete-python').activationHooks = []
    waitsForPromise -> atom.packages.activatePackage('autocomplete-python')
    runs ->
      atom.packages.getActivePackage('autocomplete-python').mainModule.load()
    runs -> provider = atom.packages.getActivePackage(
      'autocomplete-python').mainModule.getProvider()

  it 'autocompletes builtins', ->
    editor.setText 'isinstanc'
    editor.setCursorBufferPosition([1, 0])
    waitsForPromise ->
      getCompletions().then (completions) ->
        for completion in completions
          expect(completion.text.length).toBeGreaterThan 0
          expect(completion.text).toBe 'isinstance'
        expect(completions.length).toBe 1

  it 'autocompletes python keywords', ->
    editor.setText 'impo'
    editor.setCursorBufferPosition([1, 0])
    completions = getCompletions()
    for completion in completions
      if completion.type == 'keyword'
        expect(completion.text).toBe 'import'
      expect(completion.text.length).toBeGreaterThan 0
    expect(completions.length).toBe 3

  it 'autocompletes defined functions', ->
    editor.setText """
      def hello_world():
        return True
      hell
    """
    editor.setCursorBufferPosition([3, 0])
    waitsForPromise ->
      getCompletions().then (completions) ->
        expect(completions[0].text).toBe 'hello_world'
        expect(completions.length).toBe 1
