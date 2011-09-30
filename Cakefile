#
# CoffeeScript Project Utils
#
# Author: Alisue (lambdalisue@hashnote.net - http://hashnote.net)
# License: MIT License
#
# Required:
#   - node.js
#   - coffee-script: npm install coffee-script
#   - docco: npm install docco
#   - vows: npm install vows
#   - gcc (Google Closure Compiler) - http://code.google.com/closure/compiler/
#     extract downloaded files to $HOME/.app/compiler-latest
#
fs              = require 'fs'
path            = require 'path'
{spawn, exec}   = require 'child_process'

product = 'person'
gcc = '$HOME/.app/compiler-latest/compiler.jar'
srcdir = 'src'
dstdir = 'lib'
testdir = 'test'
sources = null
tests = null

class logger
  @reset: '\033[0m'
  @bold: '\033[0;1m'
  @red: '\033[0;31m'
  @green: '\033[0;32m'
  @magenta: '\033[0;35m'
  @tick: '\u2713'
  @cross: '\u2613'
  @log: (message='', color='', explanation='') ->
    console.log "#{color}#{message}#{logger.reset} #{explanation}"
  @info: (message) ->
    logger.log message, logger.green
  @warn: (message, explanation='') ->
    logger.log message, logger.magenta, explanation
  @error: (message, explanation='') ->
    match = explanation.match /.*: (.*)/
    explanation = if match? then "- #{match[1]}" else explanation
    logger.log message, logger.red, explanation
  @success: (message) ->
    logger.info "#{logger.tick}  #{message}"
  @fail: (message, explanation) ->
    logger.error "#{logger.cross}  #{message}", explanation

if not sources? and srcdir?
  # automatically generate source list from srcdir
  sources = fs.readdirSync srcdir
  sources = (file.replace(/\.coffee/, '') for file in sources when /\.coffee$/.test file)
if not tests? and testdir?
  # automatically generate test source list from testdir
  tests = fs.readdirSync testdir
  tests = (file.replace(/\.coffee/, '') for file in tests when /test_(.*)\.coffee$/.test file)

### Continually compile the coffee scripts ###
task 'watch', 'continually compile the coffee scripts', ->
  proc = spawn "coffee", ['-wc', '-o', dstdir, srcdir]
  proc.stdout.on 'data', (buffer) ->
    logger.info buffer.toString().trim()
  proc.stderr.on 'data', (buffer) ->
    logger.error buffer.toString().trim()
  proc.on 'exit', (status) ->
    process.exit(1) if status isnt 0

### compile javascripts from coffee scripts ###
task 'compile', 'compile javascripts from coffee scripts', ->
  logger.log "Compiling JavaScripts from #{srcdir}/*.coffee to #{dstdir}/*.js...", logger.bold
  logger.log()
  failed = 0
  remaining = sources.length
  process = ->
    logger.log()
    if failed > 0
      logger.error "#{failed} files has failed to compile."
    else
      logger.info 'All files has successfuly compiled.'
    logger.log()
  for file, index in sources then do (file, index) ->
    src = "#{srcdir}/#{file}.coffee"
    dst = "#{dstdir}/#{file}.js"
    try
      cs = fs.statSync src
    catch e
      logger.fail "#{src} => #{dst}", "- File not found #{e.path}"
      failed++
      process() if --remaining is 0
      return
    try
      js = fs.statSync dst
      if cs.mtime < js.mtime
        # if JavaScript file is latest, then continue to next
        logger.success "#{dst} is latest - skip"
        process() if --remaining is 0
        return
    catch e
      null
    exec "coffee -c -o #{dst.replace(/[^\/]*.js/, '')} #{src}", (err, stdout, stderr) ->
      if err?
        logger.fail "#{src} => #{dst}", stderr
        failed++
      else
        logger.success "#{src} => #{dst}"
      process() if --remaining is 0

### build a single javascript from coffee scripts ###
option '-b', '--buildonly', 'Do not call minify automatically after build'
task 'build', 'build a single javascript from coffee scripts', (options) ->
  output = "#{dstdir}/#{product}.js"
  logger.log "Building a single JavaScript from #{srcdir}/*.coffee to #{output}...", logger.bold
  logger.log()
  failed = 0
  options = []
  remaining = sources.length
  # check file exists
  for file, index in sources then do (file, index) ->
    src = "#{srcdir}/#{file}.coffee"
    path.exists src, (exists) ->
      if exists
        logger.success src
        options.push src
      else
        logger.fail src, "- File not found: #{src}"
        failed++
      process() if --remaining is 0
  process = ->
    logger.log()
    logger.log "==> #{output}"
    logger.log()
    if failed is 0
      exec "coffee -c -j #{output} #{options.join ' '}", (err, stdout, stderr) ->
        if err?
          logger.error "#{output}", stderr
        else
          logger.info 'A single JavaScript has successfully built.'
          if not options.buildonly?
            logger.log()
            invoke 'minify'
    else
      if failed is 1
        logger.error "There is a issue exists. Fix it and try again."
      else
        logger.error "There are #{failed} issues exists. Fix them and try again."
      logger.log()

### minify the resulting javascript after build ###
task 'minify', 'minify the resulting javascript after build', ->
  src = "#{dstdir}/#{product}.js"
  dst = "#{dstdir}/#{product}.min.js"
  logger.log "Minifing the resulting JavaScript after build...", logger.bold
  logger.log()
  exec "java -jar \"#{gcc}\" --js #{src} --js_output_file #{dst}", (err, stdout, stderr) ->
    if err?
      logger.fail "#{src} => #{dst}", stderr
      logger.log()
      logger.error 'Minifing the resulting JavaScript file after build has failed.'
    else
      logger.success "#{src} => #{dst}"
      logger.log()
      logger.info 'Minifing the resulting JavaScript file after build has succeed.'
    logger.log()

### generate annotated source code with docco ###
task 'docs', 'generate annotated source code with docco', ->
  failed = 0
  remaining = sources.length
  logger.log "Generating annotated source codes from CoffeeScript files...", logger.bold
  logger.log()
  for file, index in sources then do (file, index) ->
    src = "#{srcdir}/#{file}.coffee"
    dst = "docs/#{file}.html"
    exec "docco #{src}", (err, stdout, stderr) ->
      if err?
        logger.fail "#{src} => #{dst}", stderr
        failed++
      else
        logger.success "#{src} => #{dst}"
      process() if --remaining is 0
  process = ->
    logger.log()
    if failed is 0
      logger.info 'Annotated source codes has successfuly generated.'
    else
      logger.error "#{failed} document has failed to generate."
    logger.log()

### run the test suites via vows ###
option '-s', '--spec', 'Use spec reporter'
task 'test', 'run the test suites via vows', (options) ->
  if not tests?
    tests = ("test_#{file}" for file in sources)
  args = ("#{testdir}/#{file}.coffee" for file in tests)
  if options.watch?
    args.unshift '--watch'
  if options.spec?
    args.unshift '--spec'
  proc = spawn 'vows', args
  proc.stdout.on 'data', (buffer) ->
    console.log buffer.toString().trim()
  proc.stderr.on 'data', (buffer) ->
    console.log buffer.toString().trim()
  proc.on 'exit', (status) ->
    process.exit(1) if status isnt 0

### clean generated files ###
task 'clean', 'clean generated javascripts and html files', ->
  exec [
    'rm -rf lib',
    'rm -rf docs',
  ].join(' && '), (err, stdout, stderr) ->
    if err
      logger.error stderr.trim()
    else
      logger.info 'done'
