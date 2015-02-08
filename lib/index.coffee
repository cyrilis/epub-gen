exec = require("child_process").exec

path = require "path"

fs = require "fs"

Q = require "q"

uuid = ->
  'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c)->
    r = Math.random()*16|0
    return (if c is 'x' then r else r&0x3|0x8).toString(16)

class EPub
  constructor: (@options)->
    if not options.meta or options.content
      return false
    console.log options
    self = @
    @generateTempFile(options).then ->
      self.render()

  generateTempFile: ()->
    defer = new Q.defer()
    @uuid = uuid()
    fs.mkdirSync path.resolve __dirname , "../", @uuid











