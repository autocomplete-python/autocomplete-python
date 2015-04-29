import os
import sys
import json
sys.path.append(os.path.dirname(__file__))
import jedi


class JediCompletion(object):
  basic_types = {
    'module': 'import',
    'class': 'class',
    'instance': 'variable',
    'function': 'function',
    'statement': 'value',
    'keyword': 'keyword',
  }

  def __init__(self):
    kwargs = self._deserialize(sys.argv[1])
    self.use_snippets = kwargs.get('useSnippets', False)
    for path in kwargs.get('extraPaths').split(','):
      if path and path not in sys.path:
        sys.path.insert(0, path)

  def _get_completion_type(self, completion):
    is_built_in = completion.in_builtin_module
    if completion.type not in ['import', 'keyword'] and is_built_in():
      return 'builtin'
    if completion.type in ['statement'] and completion.name.isupper():
      return 'constant'
    if completion.type in self.basic_types:
      return self.basic_types.get(completion.type)

  def _description(self, completion):
    """Provide a description of the completion object."""
    if completion._definition is None:
      return ''
    t = completion.type
    if t == 'statement':
      desc = ''.join(
        c.get_code() for c in completion._definition.children
        if type(c).__name__ in ['InstanceElement', 'String']).replace('\n', '')
    elif t == 'keyword':
      desc = ''
    elif t == 'import':
      desc = completion._definition.get_code()
    else:
      desc = '.'.join(unicode(p) for p in completion._path())
    line = '' if completion.in_builtin_module else '@%s' % completion.line
    return ('%s: %s%s' % (t, desc, line))[:50]

  @classmethod
  def _get_top_level_module(cls, path):
    """Recursively walk through directories looking for top level module.
    """
    _path, _ = os.path.split(path)
    if os.path.isfile(os.path.join(_path, '__init__.py')):
      return cls._get_top_level_module(_path)
    return path

  def _generate_snippet(self, completion):
    """
    """
    if not self.use_snippets or not hasattr(completion, 'params'):
      return
    arguments = []
    for i, param in enumerate(completion.params, start=1):
      arguments.append('${%s:%s}' % (i, param.description))
    return '%s(%s)$0' % (completion.name, ', '.join(arguments))

  def _serialize(self, completions, identifier=None):
    """Serialize response to be read from Atom.

    Args:
      completions: List of jedi.api.classes.Completion objects.
      identifier: Unique completion identifier to pass back to Atom.

    Returns:
      Serialized string to send to Atom.
    """
    _completions = []
    for completion in completions:
      _completions.append({
        'text': '%s%s' % (completion.name[:completion._like_name_length],
                          completion.complete),
        'snippet': self._generate_snippet(completion),
        'displayText': completion.name,
        # 'replacementPrefix': completion.name[:completion._like_name_length],
        'type': self._get_completion_type(completion),
        # TODO: try to understand return value
        # 'leftLabel': '',
        'rightLabel': self._description(completion),
        'description': completion.docstring(),
        # 'descriptionMoreURL': completion.module_name
      })
    return json.dumps({'id': identifier, 'completions': _completions})

  def _deserialize(self, request):
    """Deserialize request from Atom.

    Args:
      request: String with raw request from Atom.

    Returns:
      Python dictionary with request data.
    """
    return json.loads(request)

  def _process_request(self, request):
    """
    Jedi will use filepath to look for another modules at same path,
    but it will not be able to see modules **above**, so our goal
    is to find the higher python module available from filepath.
    """
    request = self._deserialize(request)
    path = self._get_top_level_module(request.get('path', ''))
    if path not in sys.path:
      sys.path.insert(0, path)
    script = jedi.api.Script(
      source=request['source'], line=request['line'] + 1,
      column=request['column'], path=request.get('path', ''))
    completions = script.completions()
    self._write_response(self._serialize(completions, request['id']))

  def _write_response(self, response):
    sys.stdout.write(response + '\n')
    sys.stdout.flush()

  def watch(self):
    while True:
      self._process_request(sys.stdin.readline())

if __name__ == '__main__':
  JediCompletion().watch()
