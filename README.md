# Python Autocomplete Package

Python variables, methods, functions and modules autocompletions in Atom. Install
[autocomplete-plus](https://github.com/atom-community/autocomplete-plus) before
installing this package.

This is powered by [Jedi](https://github.com/davidhalter/jedi).

![Demo](https://cloud.githubusercontent.com/assets/193864/7394244/e6906980-eec4-11e4-9ee2-8749d16ff468.gif)

# Features

* Watches whole package of the file you're currently editing
* Configurable additional PATHs to include for completions (global for now)
* Highlights UPPERCASE_VARIABLES as constants according to PEP8.
* Highlights builtin functions and variables with special style.
* Prints first N characters of statement value while completing variables.
* Prints function arguments while completing functions.
* Additional caching so the same request will not be handled twice.


Inspired by [autocomplete-plus-python-jedi](https://github.com/tinloaf/autocomplete-plus-python-jedi).
