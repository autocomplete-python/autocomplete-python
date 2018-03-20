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
    # fix deprecation warning when value is undefined
    atom.config.getUserConfigPath = () => ''

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

  it 'uses provided regex for triggering completions', ->
    # Set triggerCompletionRegex without restarting
    provider.triggerCompletionRegex = RegExp 'a'

    editor.setText """
      a = [1, 3, 2]
      a.
    """
    editor.setCursorBufferPosition([2, 0])

    waitsForPromise ->
      getCompletions().then (completions) ->
        expect(completions.length).toBe 0
        # Un-set triggerCompletionRegex
        provider.triggerCompletionRegex = RegExp atom.config.get('autocomplete-python.triggerCompletionRegex')

  it 'uses extra paths for packages', ->
    filePath = path.join(__dirname, 'fixtures', 'packages')
    atom.config.set('autocomplete-python.extraPaths', filePath)

    editor.setText """
      import test_pkg
      test_pkg.
    """
    editor.setCursorBufferPosition([2, 0])

    waitsForPromise ->
      getCompletions().then (completions) ->
        expect(completions.length).toBe 5
        expect(completions[0].text).toBe 'FooBar'

xdescribe 'Argument completions', ->
  [editor, provider, editorElement] = []

  getArgumentcompletions = ->
    return Promise.resolve(atom.commands.dispatch(editorElement, 'autocomplete-python:complete-arguments'))

  beforeEach ->
    atom.config.set('autocomplete-python.useKite', false)
    filePath = path.join(__dirname, 'fixtures', 'argument-test.py')
    waitsForPromise -> atom.packages.activatePackage('language-python')
    waitsForPromise -> atom.workspace.open(filePath)
    runs ->
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(atom.workspace)
      jasmine.attachToDOM(editorElement)
      editor.setGrammar(atom.grammars.grammarForScopeName('test.py'))
      atom.packages.loadPackage('autocomplete-python').activationHooks = []
    waitsForPromise -> atom.packages.activatePackage('autocomplete-python')
    runs ->
      atom.packages.getActivePackage('autocomplete-python').mainModule.load()
    runs -> provider = atom.packages.getActivePackage(
      'autocomplete-python').mainModule.getProvider()


  it 'completes all function parameters', ->
    atom.config.set('autocomplete-python.useSnippets', 'all')
    editor.setCursorBufferPosition([2, 4])
    waitsForPromise ->
      getArgumentcompletions().then ->
        process.stdout.write(editor.getCursorBufferPosition().toString())
        process.stdout.write(editor.getText().toString())

  it 'completes all function parameters', ->
    atom.config.set('autocomplete-python.useSnippets', 'required')
    editor.setCursorBufferPosition([2, 4])
    waitsForPromise ->
      getArgumentcompletions().then ->
        process.stdout.write(editor.getCursorBufferPosition().toString())
        process.stdout.write(editor.getText().toString())

xdescribe 'Displays views', ->
  [editor, provider, editorElement] = []

  showUsages = ->
    jasmine.attachToDOM(editorElement)
    atom.commands.dispatch(editorElement, 'autocomplete-python:show-usages')

  beforeEach ->
    atom.config.set('autocomplete-python.useKite', false)
    waitsForPromise -> atom.packages.activatePackage('language-python')
    waitsForPromise -> atom.workspace.open('test.py')
    runs ->
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)
      editor.setGrammar(atom.grammars.grammarForScopeName('test.py'))
      atom.packages.loadPackage('autocomplete-python').activationHooks = []
    waitsForPromise -> atom.packages.activatePackage('autocomplete-python')
    runs ->
      atom.packages.getActivePackage('autocomplete-python').mainModule.load()
    runs -> provider = atom.packages.getActivePackage(
                'autocomplete-python').mainModule.getProvider()

  it 'shows usage view', ->
    FilePaths = [
      path.join(__dirname, 'fixtures', 'test.py')
      path.join(__dirname, 'fixtures', 'another.py')
    ]
    waitsForPromise -> atom.workspace.open({pathsToOpen: FilePaths})
    editor.setCursorBufferPosition([4, 13])
    showUsages()

    waitsFor "view to show", ->
      provider.usagesView?.isVisible()

    waitsFor "view to populate", ->
      provider.usagesView.items?.length > 0

    runs ->
      expect(provider.usagesView).toHaveFocus()
      expect(provider.usagesView.items.length).toBe 3
