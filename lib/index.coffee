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
    self = @
    @defer = new Q.defer()
    if not options.title or not options.content
      console.log "options not valid"
      return false

    @options = _.extend {
      description: options.title
      publisher: "TXT.SX"
      author: ["anonymous"]
      date: new Date().toISOString()
      lang: "en"
    }, options

    if _.isString @options.author
      @options.author = [@options.author]
    if _.isEmpty @options.author
      @operator.author = ["anonymous"]
    if not @options.tempDir
      @options.tempDir = path.resolve __dirname, "../tempDir/"

    @uuid = path.resolve @options.tempDir, uuid()
    @options.uuid = @uuid
    console.log @uuid

    @options.content = _.map @options.content, (content, index)->
      titleSlug = uslug content.title
      content.filePath = path.resolve self.uuid, "./OEBPS/#{index}_#{titleSlug}.html"
      content.href = "#{index}_#{titleSlug}.html"
      content.id = "item_#{index}"
      content.author =
        if content.author
          if _.isString(content.author)
            [content.author]
          else if not content.author.length
            []
          else
            content.author
        else
          []

      # Only body innerHTML is allowed
      reg = /<body[^>]*>((.|[\n\r])*)<\/body>/
      content.data = content.data.match(reg)?[1] || content.data

      content

    @generateTempFile()
    @defer.promise

  generateTempFile: ()->
    self = @
    if !fs.existsSync(@options.tempDir)
      fs.mkdirSync(@options.tempDir)
    fs.mkdirSync @uuid
    fs.mkdirSync path.resolve(@uuid, "./OEBPS")
    @options.css ||= "
    .epub-author{
      color: #555;
    }
    .epub-link{
      margin-bottom: 30px;
    }
    .epub-link a{
      color: #666;
      font-size: 90%;
    }
    .toc-author{
      font-size: 90%;
      color: #555;
    }
    .toc-link{
      color: #999;
      font-size: 85%;
      display: block;
    }
    hr{
      border: 0;
      border-bottom: 1px solid #dedede;
      margin: 60px 10%;
    }
    "
    fs.writeFileSync path.resolve(@uuid, "./OEBPS/style.css"), @options.css

    _.each @options.content, (content, index)->
      data = "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en-US\">
        <head>
        <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
        <title>#{content.title}</title>
        <link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\" />
      </head><body>"
      data += if content.title then "<h1>#{content.title}</h1>" else ""
      data += if content.title and content.author and content.author.length then "<p class='epub-author'>#{content.author.join(", ")}</p>" else ""
      data += if content.title and content.url then "<p class='epub-link'><a href='#{content.url}'>#{content.url}</a></p>" else ""
      data += "#{content.data}</body></html>"
      fs.writeFileSync(content.filePath, data)

    # write minetype file
    fs.writeFileSync(@uuid + "/mimetype", "application/epub+zip")

    # write meta-inf/container.xml
    fs.mkdirSync(@uuid + "/META-INF")
    fs.writeFileSync( "#{@uuid}/META-INF/container.xml", """
<?xml version="1.0" encoding="UTF-8" ?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
    <rootfiles>
        <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
    </rootfiles>
</container>
""")

    ejs.renderFile path.resolve(__dirname, "./content.ejs"), self.options, (err, data)->
      if err
        console.error err
        self.defer.reject(err)
        return false
      fs.writeFileSync(path.resolve(self.uuid , "./OEBPS/content.opf"), data)
      ejs.renderFile path.resolve( __dirname , "./toc.ejs" ), self.options, (err, data)->
        if err
          console.error err
          self.defer.reject(err)
          return false
        fs.writeFileSync(path.resolve(self.uuid , "./OEBPS/toc.ncx"), data)
        ejs.renderFile path.resolve(__dirname, "./content.html"), self.options, (err, data)->
          if err
            console.error err
            self.defer.reject(err)
            return false
          fs.writeFileSync(path.resolve(self.uuid, "./OEBPS/contents.html"), data)
          self.genEpub()

  genEpub: ()->
    self = @
    console.log @uuid
    filename = "book.epub.zip"
    initCmd = "zip -X -0 #{filename} mimetype"
    zipCmd  = "zip -X -9 -r #{filename} * -x mimetype #{filename}"
    cleanUp = "mv #{filename} book.epub && rm -f -r META-INF OEBPS mimetype"
    cwd = @uuid
    exec initCmd, {cwd}, (err, stderr, stdout)->
      if err
        console.error(initCmd, err, stderr, stdout)
        self.defer.reject err
        return false
      if stderr
        console.warn(stderr)
      if stdout
        console.log stdout
      exec zipCmd, {cwd}, (err, stderr, stdout)->
        if err
          console.error(zipCmd, err, stderr, stdout)
          self.defer.reject err
          return false
        if stderr
          console.warn stderr
        if stdout
          console.log stdout
        exec cleanUp, {cwd}, (err, stderr, stdout)->
          if err
            console.error(cleanUp, err, stderr, stdout)
            self.defer.reject err
            return false
          if stderr
            console.warn stderr
          if stdout
            console.log stdout
          self.defer.resolve @

module.exports = EPub