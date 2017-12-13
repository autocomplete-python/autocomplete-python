'use babel'

import fs from 'fs'
import os from 'os'
import path from 'path'
import log from './log'


let POSSIBLE_PYTHON_PATHS
if (/^win/.test(process.platform)) {
  let POSSIBLE_PYTHON_PATHS = [
    'C:\\Python2.7',
    'C:\\Python3.4',
    'C:\\Python3.5',
    'C:\\Program Files (x86)\\Python 2.7',
    'C:\\Program Files (x86)\\Python 3.4',
    'C:\\Program Files (x86)\\Python 3.5',
    'C:\\Program Files (x64)\\Python 2.7',
    'C:\\Program Files (x64)\\Python 3.4',
    'C:\\Program Files (x64)\\Python 3.5',
    'C:\\Program Files\\Python 2.7',
    'C:\\Program Files\\Python 3.4',
    'C:\\Program Files\\Python 3.5',
    `${os.homedir()}\\AppData\\Local\\Programs\\Python\\Python35-32`
  ]
} else {
  let POSSIBLE_PYTHON_PATHS = [
    '/usr/local/bin', '/usr/bin', '/bin', '/usr/sbin', '/sbin']
}

const pythonExecutableRe = () => {
  if (/^win/.test(process.platform)) {
    return /^python(\d+(.\d+)?)?\.exe$/
  } else {
    return /^python(\d+(.\d+)?)?$/
  }
}

const readDir = (dirPath) => {
  try {
    return fs.readdirSync(dirPath)
  } catch (error) {
    return []
  }
}

const isBinary = (filePath) => {
  try {
    const stats = fs.statSync(filePath)
    // X_OK won't work on windows so at least ignore directories
    if (stats.isDirectory()) {
      return false
    }
  } catch (error) {
    return false
  }

  try {
    fs.accessSync(filePath, fs.X_OK)
    return true
  } catch (error1) {
    return false
  }
}

const lookupInterpreters = (dirPath) => {
  const interpreters = new Set()
  const files = readDir(dirPath)
  const matches = () => {
    const result = []
    for (let f of files) {
      if (pythonExecutableRe().test(f)) {
        result.push(f)
      }
    }
    return result
  }
  for (let fileName of matches()) {
    const potentialInterpreter = path.join(dirPath, fileName)
    if (isBinary(potentialInterpreter)) {
      interpreters.add(potentialInterpreter)
    }
  }
  return interpreters
}

export default {
  applySubstitutions(paths) {
    const modPaths = []
    for (let p of paths) {
      if (/\$PROJECT/.test(p)) {
        for (let project of atom.project.getPaths()) {
          const array = project.split(path.sep), projectName = array[array.length - 1]
          p = p.replace(/\$PROJECT_NAME/i, projectName)
          p = p.replace(/\$PROJECT/i, project)
          if (!modPaths.includes(p)) {
            modPaths.push(p)
          }
        }
      } else {
        modPaths.push(p)
      }
    }
    return modPaths
  },

  getInterpreter() {
    const userDefinedPythonPaths = this.applySubstitutions(
      atom.config.get('autocomplete-python.pythonPaths').split(''))
    let interpreters = new Set((() => {
      const result = []
      for (let p of userDefinedPythonPaths) {
        if (isBinary(p)) {
          result.push(p)
        }
      }
      return result
    })())
    if (interpreters.size > 0) {
      log.debug('User defined interpreters found', interpreters)
      return interpreters.keys().next().value
    }

    log.debug('No user defined interpreter found, trying automatic lookup')
    interpreters = new Set()

    for (let project of atom.project.getPaths()) {
      for (let f of readDir(project)) {
        lookupInterpreters(path.join(project, f, 'bin')).forEach(i => interpreters.add(i))
      }
    }
    log.debug('Project level interpreters found', interpreters)
    let envPath = (process.env.PATH || '').split(path.delimiter)
    envPath = new Set(envPath.concat(POSSIBLE_PYTHON_PATHS))
    envPath.forEach(potentialPath => {
      return lookupInterpreters(potentialPath).forEach(i => interpreters.add(i))
    })
    log.debug('Total automatically found interpreters', interpreters)

    if (interpreters.size > 0) {
      return interpreters.keys().next().value
    }
  }
}
