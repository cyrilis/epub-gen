exec = require("child_process").exec
path = require "path"
fs = require "fs"
Q = require "q"
_ = require "underscore"
uslug = require "uslug"
ejs = require "ejs"

uuid = ->
  'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c)->
    r = Math.random()*16|0
    return (if c is 'x' then r else r&0x3|0x8).toString(16)

class EPub
  constructor: (@options)->
    if not options.title or not options.content
      console.log "options not valid"
      return false
    @options = _.extend {
      description: options.title
      publisher: "TXT.SX"
      author: "anonymous"
      date: new Date().toLocaleString()
      lang: "en"
    }, options
    @generateTempFile()

  generateTempFile: ()->
    defer = new Q.defer()
    if not @options.tempDir
      @options.tempDir = path.resolve __dirname, "../tempDir/"
    @uuid = path.resolve @options.tempDir, uuid()
    if !fs.existsSync(@options.tempDir)
      fs.mkdirSync(@options.tempDir)
    fs.mkdirSync @uuid
    self = @
    console.log @uuid


    @options.content = _.map @options.content, (content, index)->
      titleSlug = uslug content.title
      content.filePath = path.resolve self.uuid, "./OEBPS/#{index}_#{titleSlug}.html"
      content.href = "#{index}_#{titleSlug}.html"
      content.id = "item_#{index}"
      content

    fs.mkdirSync path.resolve(@uuid, "./OEBPS")

    _.each @options.content, (content, index)->
      data = """
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-US">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>#{content.title}</title>
</head>
<body>
#{content.data}
</body>
</html>
"""
      fs.writeFileSync(content.filePath, data)

    # write minetype file
    fs.writeFileSync(@uuid + "/minetype", "application/epub+zip")

    # write meta-inf/container.xml
    fs.mkdirSync(@uuid + "/META-INF")
    fs.writeFileSync(@uuid + "/META-INF/" + "container.xml", """
<?xml version="1.0" encoding="UTF-8" ?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
    <rootfiles>
        <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
    </rootfiles>
</container>
""")

    ejs.renderFile path.resolve(__dirname, "./content.ejs"), @options, (err, data)->
      if err
        console.error err
        return false
      console.log "./content"
      fs.writeFileSync(path.resolve(self.uuid , "./OEBPS/content.opf"), data)
      ejs.renderFile path.resolve( __dirname , "./toc" ), @options, (err, data)->
        if err
          console.log err
          return false
        console.log "./content"
        fs.writeFileSync(path.resolve(self.uuid , "./OEBPS/toc.ncx"), data)

module.exports = EPub