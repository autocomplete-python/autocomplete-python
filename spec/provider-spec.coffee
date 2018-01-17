path = require 'path'

packagesToTest =
  Python:
    name: 'language-python'
    file: 'test.py'

describe 'Jedi autocompletions', ->
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
    return Promise.resolve(provider.getSuggestions(request))

  goToDefinition = ->
    bufferPosition = editor.getCursorBufferPosition()
    return Promise.resolve(provider.goToDefinition(editor, bufferPosition))

  getMethods = ->
    bufferPosition = editor.getCursorBufferPosition()
    return Promise.resolve(provider.getMethods(editor, bufferPosition))

  getUsages = ->
    bufferPosition = editor.getCursorBufferPosition()
    return Promise.resolve(provider.getUsages(editor, bufferPosition))

  beforeEach ->
    atom.config.set('autocomplete-python.useKite', false)
    waitsForPromise -> atom.packages.activatePackage('language-python')
    waitsForPromise -> atom.workspace.open('test.py')
    runs ->
      editor = atom.workspace.getActiveTextEditor()
      editor.setGrammar(atom.grammars.grammarForScopeName('test.py'))
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
    waitsForPromise ->
      getCompletions().then (completions) ->
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

  it 'goes to definition', ->
    editor.setText """
      def abc():
          return True
      x = abc()
    """
    editor.setCursorBufferPosition([2, 4])
    waitsForPromise ->
      goToDefinition().then ->
          result =
            row: 0
            column: 4
          expect(editor.getCursorBufferPosition()).toEqual result

  it 'autocompletes function argument', ->
    editor.setText """
      def abc(x, z: str):
        return True
      x = abc()
    """
    editor.setCursorBufferPosition([2, 8])
    waitsForPromise ->
      getCompletions().then (completions) ->
        expect(completions.length).toBeGreaterThan 1
        expect(completions[0].text).toBe 'x'
        expect(completions[1].text).toBe 'z: str'

  it 'gets methods', ->
    FilePath = path.join(__dirname, 'fixtures', 'test.py')
    waitsForPromise -> atom.workspace.open(FilePath)
    editor.setCursorBufferPosition([5, 4])

    waitsForPromise ->
      getMethods().then ({methods, indent, bufferPosition}) ->
        expect(indent).toBe 4

        expectedBuffer =
          row: 5
          column: 4
        expect(bufferPosition).toEqual expectedBuffer

        expect(methods.length).toBeGreaterThan 0

        expectedMethod =
          parent: 'Foo'
          instance: 'Bar'
          name: 'test'
          params: []
          moduleName: 'test'
          fileName: FilePath
          line: 2
          column: 8
        expect(methods[0]).toEqual expectedMethod

  it 'gets usages', ->
    FilePaths = [
      path.join(__dirname, 'fixtures', 'test.py')
      path.join(__dirname, 'fixtures', 'another.py')
    ]
    waitsForPromise -> atom.workspace.open({pathsToOpen: FilePaths})
    editor.setCursorBufferPosition([4, 13])
    waitsForPromise ->
      getUsages().then (usages) ->
        expect(usages.length).toBe 3

        expectedUsage =
          name: 'Foo'
          moduleName: 'test'
          fileName: FilePaths[0]
          line: 1
          column: 6
        expect(usages).toContain expectedUsage

        expectedUsage =
          name: 'Foo'
          moduleName: 'another'
          fileName: FilePaths[1]
          line: 3
          column: 9
        expect(usages).toContain expectedUsage

  it 'fuzzy matches', ->
    atom.config.set('autocomplete-python.fuzzyMatcher', true)

    editor.setText """
      def abcdef():
        return True
      abdf
    """
    editor.setCursorBufferPosition([3, 0])

    waitsForPromise ->
      getCompletions().then (completions) ->
        expect(completions[0].text).toBe 'abcdef'
        expect(completions.length).toBe 1

  it 'does not fuzzy match if disabled', ->
    atom.config.set('autocomplete-python.fuzzyMatcher', false)

    editor.setText """
      def abcdef():
        return True
      abdf
    """
    editor.setCursorBufferPosition([3, 0])

    waitsForPromise ->
      getCompletions().then (completions) ->
        expect(completions.length).toBe 0
