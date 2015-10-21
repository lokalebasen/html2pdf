ChildProcess = require('child_process')
Path = require('path')
Fs = require('fs')
Uuid = require('node-uuid')

module.exports = class PhantomRunner

  constructor: (@conversionOptions) ->
    systemCall = ['phantomjs', @phantomArguments()]
    console.log ("Invoking: #{systemCall}")
    @phantomProcess = ChildProcess.spawn.apply(this, systemCall)
    @phantomProcess.stdout.on 'data', (data) ->
      console.log 'PhantomJS says: ' + data
    @phantomProcess.stderr.on 'data', (data) ->
      console.log 'PhantomJS cries: ' + data

  on: (event, callback) ->
    switch event
      when 'done'
        @phantomProcess.on 'close', (code) =>
          if code is 0
            pdfBinary = Fs.readFileSync(@temporaryFilePath())
            Fs.unlink @temporaryFilePath()
            callback(pdfBinary)
      else
        throw new Error("PhantomRunner does not support event: #{event}")

  phantomArguments: ->
    [
      '--web-security=no'
      '--ssl-protocol=any'
      @absolutePathToPhantomScript()
      @conversionOptions.source_url
      @temporaryFilePath()
      @conversionOptions.paperFormat
      @conversionOptions.orientation
      @conversionOptions.margin
      @conversionOptions.zoom
    ]

  temporaryFilePath: ->
    @_temporaryFilePath ?= @generateTmpPath()

  generateTmpPath: ->
    Path.join('/tmp', Uuid.v4() + '.pdf')

  absolutePathToPhantomScript: ->
    Path.join(__dirname, '../rasterize/rasterize.js')
