# Python Autocomplete Package [![Build Status](https://travis-ci.org/sadovnychyi/autocomplete-python.svg?branch=master)](https://travis-ci.org/sadovnychyi/autocomplete-python)

Python packages, variables, methods and functions with their arguments autocompletion in [Atom](http://atom.io) powered by [Jedi](https://github.com/davidhalter/jedi).

![Demo](https://cloud.githubusercontent.com/assets/193864/7394244/e6906980-eec4-11e4-9ee2-8749d16ff468.gif)

# Features

* Works with :apple: Mac OSX, :penguin: Linux and :checkered_flag: Windows
* Works with both :snake: Python 2 and 3
* Automatic lookup of virtual environments inside of your projects
* Configurable additional packages to include for completions
* Prints first N characters of statement value while completing variables
* Prints function arguments while completing functions
* Go-to-definition functionality, by default on `Alt+Cmd+G`/`Ctrl+Alt+G` (thanks to [@patrys](https://github.com/patrys))
* If you have [Hyperclick](https://atom.io/packages/hyperclick) installed – you can click on anything to go-to-definition
![sample](https://cloud.githubusercontent.com/assets/193864/10814177/17fb8bce-7e5f-11e5-8285-6b0100b3a0f8.gif)

# Configuration

* If using a [virtualenv](https://virtualenv.pypa.io/en/latest/) with third-party packages, everything should "just work", but if it's not – use the `Python Executable Paths` and/or `Extra Paths For Packages` configuration options to specify the virtualenv's site-packages. Or launch Atom from the [activated virtualenv](https://virtualenv.pypa.io/en/latest/userguide.html#activate-script) to get completion for your third-party packages
* Be sure to check package settings and adjust them. Please read them carefully before creating any new issues
  * Set path to python executable if package cannot find it automatically
  * Set extra path if package cannot autocomplete external python libraries
  * Select one of autocomplete function parameters if you want function arguments to be completed

  ![image](https://cloud.githubusercontent.com/assets/193864/10657279/540d39f4-78bb-11e5-9bbf-283fb67c9fd4.png)


# Common problems

* "Error: spawn UNKNOWN" on Windows
  * Solution: Find your python executable and uncheck the "Run this program as an administrator". See issue [#22](https://github.com/sadovnychyi/autocomplete-python/issues/22)
