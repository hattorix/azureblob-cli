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
environment = { name: opts.get('n'), key: opts.get('k') }
process.env['AZURE_STORAGE_ACCOUNT']    = environment.name
process.env['AZURE_STORAGE_ACCESS_KEY'] = environment.key

try
  bs = azure.createBlobService()
catch e
  console.log "#{e.name}: #{e.message}"
  process.exit 1

# REPL
rl = readline.createInterface
  input : process.stdin
  output: process.stdout

environment.pwd = []
getCurrentDirectory = () ->
  '/' + environment.pwd.join('/')

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
  rl.setPrompt("#{environment.name} [#{dir}] > ")
  rl.prompt()
repl()

rl.on 'line', (line) ->
  cmd = line.trim().split(/\s+/)
  args = cmd[1..]
  cmd  = cmd[0]

  switch cmd
    when 'cd'
      todir = if args[0]? then createPathArray getCurrentDirectory(), args[0] else []
      # TODO: 存在しない階層への移動を不許可
      environment.pwd = todir
      repl()
      return

    when 'cat'
      if args.length < 1
        break

      [container, blob] =
        splitContainerAndBlob createPathArray(getCurrentDirectory(), args[0])
      if not container? or blob.length == 0
        console.log 'The specified blob does not exist.'
        break

      bs.getBlobToText container, blob, (error, text, blobResult, response) ->
        if error?
          printServiceError error
        else
          console.log text
        rl.prompt()
      return

    when 'cp'
      # TODO:
      break

    when 'quit', 'exit'
      rl.close()
      return

    when 'get'
      if args.length != 1 and args.length != 2
        break

      [container, blob] =
        splitContainerAndBlob createPathArray(getCurrentDirectory(), args[0])
      if not container? or blob.length == 0
        console.log 'The specified blob does not exist.'
        break

      fname = args[1] ? path.basename(blob)
      bs.getBlobToFile container, blob, fname, (error, responseBlob, response) ->
        if error?
          printServiceError error
        rl.prompt()
      return

    when 'ls'
      [container, prefix] =
        splitContainerAndBlob createPathArray(getCurrentDirectory(), args[0])

      if not container?
        # root ディレクトリでは、コンテナの一覧
        bs.listContainers (err, containers) ->
          for c in containers
            console.log "#{c.name}/"
          rl.prompt()
      else
        # TODO: パラメータが指定された際の処理
        # コンテナ内では、直下のリスト
        [container, prefix] = splitContainerAndBlob environment.pwd
        prefix = "#{prefix}/" if prefix.length > 0
        bs.listBlobs container,
          'delimiter' : '/'
          'prefix'    : prefix
        , (error, blobs, continuation, response) ->
          # error handling
          if error?
            printServiceError error

          else
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
      return

    when 'mv'
      # TODO:
      break

    when 'put'
      # TODO:
      break

    when 'pwd'
      console.log getCurrentDirectory()

    when 'rm'
      # TODO:
      break

    when ''
      break

    else
      console.log "#{cmd}: command not found"

  # finish command
  rl.prompt()

rl.on 'close', () ->
  process.exit 0
