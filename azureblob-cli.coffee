azure    = require 'azure'
opts     = require 'opts'
readline = require 'readline'

# Parse command-line options
options = [
  { short       : 'n'
  , long        : 'name'
  , description : 'Azure account name'
  , value       : true
  },
  { short       : 'k'
  , long        : 'key'
  , description : 'Azure account key'
  , value       : true
  },
]
opts.parse options, true

# need parameter
if not opts.get('n') or not opts.get('k')
  console.log '-n <Account name> -k <Account key>'
  process.exit()

# Azure account
process.env['AZURE_STORAGE_ACCOUNT']    = opts.get('n')
process.env['AZURE_STORAGE_ACCESS_KEY'] = opts.get('k')

try
  bs = azure.createBlobService()
catch e
  console.log "#{e.name}: #{e.message}"
  process.exit 1

# REPL
rl = readline.createInterface
  input : process.stdin
  output: process.stdout

pwd = []
getCurrentDirectory = () ->
  '/' + pwd.join('/')

repl = () ->
  dir = getCurrentDirectory()
  rl.setPrompt "blob [#{dir}] > "
  rl.prompt()
repl()

rl.on 'line', (cmd) ->
  switch cmd.trim()
    when 'cd'
      # TODO:
      rl.prompt()
    when 'cp'
      # TODO:
      rl.prompt()
    when 'quit', 'exit'
      rl.close()
    when 'get'
      # TODO:
      rl.prompt()
    when 'ls'
      bs.listContainers (err, containers) ->
        for c in containers
          console.log c.name
        rl.prompt()

    when 'mv'
      # TODO:
      rl.prompt()
    when 'put'
      # TODO:
      rl.prompt()
    when 'pwd'
      console.log getCurrentDirectory()
      rl.prompt()
    when 'rm'
      # TODO:
      rl.prompt()
    else
      console.log "#{cmd}: command not found"
      rl.prompt()

rl.on 'close', () ->
  process.exit 0
