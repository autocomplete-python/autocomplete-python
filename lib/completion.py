import os
import sys
import json
sys.path.append(os.path.join(os.path.dirname(__file__), 'jedi'))
import jedi


class JediCompletion(object):
  types = {
    'module': 'import',
    'class': 'class',
    'instance': 'variable',
    'function': 'function',
    'statement': 'value',
    'keyword': 'keyword',
  }

  def __init__(self):
    for path in sys.argv[1:]:
      if path not in sys.path:
        sys.path.insert(0, path)

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
    if not hasattr(completion, 'params'):
      return
    arguments = []
    for i, param in enumerate(completion.params, start=1):
      arguments.append('${%s:%s}' % (i, param.description))
    return '%s(%s)$0' % (completion.name, ', '.join(arguments))

  def _serialize(self, completions, identifier):
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
        'type': self.types.get(completion.type),
        # TODO: try to understand return value
        # 'leftLabel': '',
        'rightLabel': completion.description,
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
