# <img src="https://camo.githubusercontent.com/93db48ccf6668e60c8c6c9579765d31b033d88f7/68747470733a2f2f7777772e69636f6e66696e6465722e636f6d2f69636f6e732f3231363936352f646f776e6c6f61642f7376672f313238" width="32" title="May the Force be with you"> Python Autocomplete Package [![Build Status](https://travis-ci.org/sadovnychyi/autocomplete-python.svg?branch=master)](https://travis-ci.org/sadovnychyi/autocomplete-python)

Python packages, variables, methods and functions with their arguments autocompletion in [Atom](http://atom.io) powered by [Jedi](https://github.com/davidhalter/jedi).

![Demo](https://cloud.githubusercontent.com/assets/193864/7394244/e6906980-eec4-11e4-9ee2-8749d16ff468.gif)

# Features

* Works with :apple: Mac OSX, :penguin: Linux and :checkered_flag: Windows
* Works with both :snake: Python 2 and 3
* Watches whole package of the file you're currently editing
* Configurable additional PATHs to include for completions (global for now)
* You can include project specific folders by using $PROJECT variable in PATH configuration
* Prints first N characters of statement value while completing variables
* Prints function arguments while completing functions
* Go-to-definition functionality, by default on `Alt+Cmd+G`/`Ctrl+Alt+G` (thanks to [@patrys](https://github.com/patrys))

# Configuration

* If using a [virtualenv](https://virtualenv.pypa.io/en/latest/) with third-party packages, be sure to launch Atom from the [activated virtualenv](https://virtualenv.pypa.io/en/latest/userguide.html#activate-script) to get completion for your third-party packages
* If you're on Windows:
  * Install [python](https://www.python.org/downloads/)
  * Make Sure that python is available in your PATH: `echo %PATH%`. If it's not, add it and restart your system: `set PATH=%PATH%;C:\Python27`
* Be sure to check package settings and adjust them. Please read them carefully before creating any new issues
  * Set path to python directory if package cannot find your python executable
  * Set extra path if package cannot autocomplete external python libraries
  * Select one of autocomplete function parameters if you want function arguments to be completed

  ![image](https://cloud.githubusercontent.com/assets/193864/10657279/540d39f4-78bb-11e5-9bbf-283fb67c9fd4.png)


# Common problems

* "Error: spawn UNKNOWN" on Windows
  * Solution: Find your python executable and uncheck the "Run this program as an administrator". See issue [#22](https://github.com/sadovnychyi/autocomplete-python/issues/22)
