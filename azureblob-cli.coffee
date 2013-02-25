azure    = require 'azure'
opts     = require 'opts'
readline = require 'readline'
path     = require 'path'

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

rl.on 'line', (line) ->
  cmd = line.trim().split(' ')
  args = cmd[1..] if cmd.length > 1
  cmd  = cmd[0]

  switch cmd
    when 'cd'
      if args?
        to_dir = path.resolve(getCurrentDirectory(), args[0])[1..]
        to_dir = if to_dir.length > 0 then to_dir.split('/') else []
      else
        to_dir = []
      # TODO: 存在しない階層への移動を不許可
      pwd = to_dir
      repl()

    when 'cat'
      if args?
        target = path.resolve(getCurrentDirectory(), args[0])[1..]
        target = if target.length > 0 then target.split('/') else []
        container = target[0]
        blob = target[1..].join('/')
        if container? and blob.length > 0
          bs.getBlobToText container, blob, (error, text, blobResult, response) ->
            if error?
              console.log error.message.split('\n')[0]
            else
              console.log text
            rl.prompt()
        else
          console.log 'The specified blob does not exist.'
          rl.prompt()
      else
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
      if pwd.length == 0
        # root ディレクトリでは、コンテナの一覧
        bs.listContainers (err, containers) ->
          for c in containers
            console.log c.name
          rl.prompt()
      else
        # TODO: パラメータが指定された際の処理
        # コンテナ内では、直下のリスト
        prefix = pwd[1..].join('/')
        prefix = "#{prefix}/" if prefix.length > 0
        bs.listBlobs pwd[0],
          'delimiter' : '/'
          'prefix'    : prefix
        , (error, blobs, continuation, response) ->
          # sub directories
          prefixes = []
          if response.body.Blobs.BlobPrefix?
            prefixes = response.body.Blobs.BlobPrefix
            prefixes = [prefixes] if not Array.isArray(prefixes)
          for subdir in prefixes
            console.log subdir.Name[prefix.length..]

          # blobs
          for b in blobs
            console.log b.name[prefix.length..]
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

    when ''
      rl.prompt()

    else
      console.log "#{cmd}: command not found"
      rl.prompt()

rl.on 'close', () ->
  process.exit 0
