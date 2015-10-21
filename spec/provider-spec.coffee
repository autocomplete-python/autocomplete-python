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
    waitsForPromise -> atom.packages.activatePackage('autocomplete-python')

    runs ->
      provider = atom.packages.getActivePackage('autocomplete-python').mainModule.getProvider()

  Object.keys(packagesToTest).forEach (packageLabel) ->
    describe "#{packageLabel} files", ->
      beforeEach ->
        waitsForPromise -> atom.packages.activatePackage(packagesToTest[packageLabel].name)
        waitsForPromise -> atom.workspace.open(packagesToTest[packageLabel].file)
        runs -> editor = atom.workspace.getActiveTextEditor()

      it 'autocompletes builtins', ->
        editor.setText 'isinstanc'
        editor.setCursorBufferPosition([1, 0])
        completions = getCompletions()
        waitsForPromise ->
          getCompletions().then (completions) ->
            for completion in completions
              expect(completion.snippet.length).toBeGreaterThan 0
              expect(completion.snippet).toBe 'isinstance$0'
            expect(completions.length).toBe 1

      it 'autocompletes python keywords', ->
        editor.setText 'impo'
        editor.setCursorBufferPosition([1, 0])
        completions = getCompletions()
        waitsForPromise ->
          getCompletions().then (completions) ->
            for completion in completions
              if completion.type == 'keyword'
                expect(completion.snippet).toBe 'import$0'
              expect(completion.snippet.length).toBeGreaterThan 0
            expect(completions.length).toBe 3

      it 'autocompletes defined functions', ->
        editor.setText """
          def hello_world():
            return True
          hell
        """
        editor.setCursorBufferPosition([3, 0])
        completions = getCompletions()
        waitsForPromise ->
          getCompletions().then (completions) ->
            expect(completions[0].snippet).toBe 'hello_world$0'
            expect(completions.length).toBe 1
