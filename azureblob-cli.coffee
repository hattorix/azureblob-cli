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

createPathArray = (from, to) ->
  newpath = path.resolve(from, to)
  pos = newpath.indexOf(path.sep)
  if pos != -1 and pos != newpath.length - 1
    newpath[pos+1..].split(path.sep)
  else
    []

splitContainerAndBlob = (pathArray) ->
  [pathArray[0], pathArray[1..].join('/')]

printServiceError = (error) ->
  console.log error.message.split('\n')[0]

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
      todir = if args? then createPathArray getCurrentDirectory(), args[0] else []
      # TODO: 存在しない階層への移動を不許可
      pwd = todir
      repl()

    when 'cat'
      if args?
        [container, blob] =
          splitContainerAndBlob createPathArray(getCurrentDirectory(), args[0])
        if container? and blob.length > 0
          bs.getBlobToText container, blob, (error, text, blobResult, response) ->
            if error?
              printServiceError error
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
        [container, prefix] = splitContainerAndBlob pwd
        prefix = "#{prefix}/" if prefix.length > 0
        bs.listBlobs container,
          'delimiter' : '/'
          'prefix'    : prefix
        , (error, blobs, continuation, response) ->
          # error handling
          if error?
            printServiceError error
            rl.prompt()
            return

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
