# Python Autocomplete Package [![Build Status](https://travis-ci.org/sadovnychyi/autocomplete-python.svg?branch=master)](https://travis-ci.org/sadovnychyi/autocomplete-python)

Python packages, variables, methods and functions with their arguments autocompletion in [Atom](http://atom.io) powered by [Jedi](https://github.com/davidhalter/jedi).

See [releases](https://github.com/sadovnychyi/autocomplete-python/releases) for release notes.

![Demo](https://cloud.githubusercontent.com/assets/193864/12288427/61fe2114-ba0f-11e5-9832-98869180d87f.gif)

# Features

* Works with :apple: Mac OSX, :penguin: Linux and :checkered_flag: Windows
* Works with both :snake: Python 2 and 3
* Automatic lookup of virtual environments inside of your projects
* Configurable additional packages to include for completions
* Prints first N characters of statement value while completing variables
* Prints function arguments while completing functions
* Go-to-definition functionality, by default on `Alt+Cmd+G`/`Ctrl+Alt+G`. Thanks to [@patrys](https://github.com/patrys) for idea and implementation.
* Method override functionality. Available as `override-method` command. Thanks to [@pchomik](https://github.com/pchomik) for idea and help.
* If you have [Hyperclick](https://atom.io/packages/hyperclick) installed – you can click on anything to go-to-definition
  ![sample](https://cloud.githubusercontent.com/assets/193864/10814177/17fb8bce-7e5f-11e5-8285-6b0100b3a0f8.gif)

* Show usages of selected object
  ![sample](https://cloud.githubusercontent.com/assets/193864/12263525/aff07ad4-b96a-11e5-949e-598e943b0190.gif)

* Rename across multiple files. It will not touch files outside of your project, but it will change VCS ignored files. I'm not responsible for any broken projects without VCS because of this.
  ![sample](https://cloud.githubusercontent.com/assets/193864/12288191/f448b55a-ba0c-11e5-81d7-31289ef5dbba.gif)

# Configuration

* If using a [virtualenv](https://virtualenv.pypa.io/en/latest/) with third-party packages, everything should "just work", but if it's not – use the `Python Executable Paths` and/or `Extra Paths For Packages` configuration options to specify the virtualenv's site-packages. Or launch Atom from the [activated virtualenv](https://virtualenv.pypa.io/en/latest/userguide.html#activate-script) to get completion for your third-party packages
* Be sure to check package settings and adjust them. Please read them carefully before creating any new issues
  * Set path to python executable if package cannot find it automatically
  * Set extra path if package cannot autocomplete external python libraries
  * Select one of autocomplete function parameters if you want function arguments to be completed

  ![image](https://cloud.githubusercontent.com/assets/193864/11631369/aafb34b4-9d3c-11e5-9a06-e8712a21474e.png)


# Common problems

* "Error: spawn UNKNOWN" on Windows
  * Solution: Find your python executable and uncheck the "Run this program as an administrator". See issue [#22](https://github.com/sadovnychyi/autocomplete-python/issues/22)
* You have a separated folder for virtualenvs (e.g. by using `virtualenvwrapper`) and all your virtualenvs are stored in e.g. `~/.virtualenvs/`
  * Create symlink to venv from your project root
    * OR
  * Add virtualenv folder as additional project root
    * OR
  * Use a virtualenv with the same name as the folder name of your project and use $PROJECT_NAME variable to set path to python executable.
  You can use same variable to set extra paths as well. For example:
  ```
  /Users/name/.virtualenvs/$PROJECT_NAME/bin/python3.4
  ```
  * See issue [#143](https://github.com/sadovnychyi/autocomplete-python/issues/143)
* No argument completion after I type left parenthesis character
  * Likely this is because you have non standard keyboard layout.
  Try to install the keyboard-localization package from: https://atom.io/packages/keyboard-localization
  and use keymap generator to check what unicode character being generated after you type `(`.
  Currently we trigger argument completion only on `U+0028`, `U+0038` and `U+0039`.
