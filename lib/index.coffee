exec = require("child_process").exec
path = require "path"
fs = require "fs"
Q = require "q"
_ = require "underscore"
uslug = require "uslug"
ejs = require "ejs"
cheerio = require "cheerio"
request = require "superagent"
fsextra = require "fs-extra"
removeDiacritics = require('diacritics').remove

uuid = ->
  'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c)->
    r = Math.random()*16|0
    return (if c is 'x' then r else r&0x3|0x8).toString(16)

class EPub
  constructor: (options, output)->
    @options = options
    self = @
    @defer = new Q.defer()

    if output
      @options.output = output

    if not @options.output
      console.error(new Error("No Output Path"))
      @defer.reject(new Error("No output path"))
      return false

    if not options.title or not options.content
      console.log "options not valid"
      return false

    @options = _.extend {
      description: options.title
      publisher: "anonymous"
      author: ["anonymous"]
      tocTitle: "Table Of Contents"
      appendChapterTitles: true
      date: new Date().toISOString()
      lang: "en"
      fonts: []
      customOpfTemplatePath: null
      customNcxTocTemplatePath: null
      customHtmlTocTemplatePath: null
      docType: "html"
    }, options

    if @options.docType is "xhtml"
      @options.mediaType = "application/xhtml+xml"
      @options.docHeader = """<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="#{self.options.lang}">
"""
    else
      @options.mediaType = "text/html"
      @options.docHeader = """<!DOCTYPE html>
<html lang="#{self.options.lang}">
"""

    if _.isString @options.author
      @options.author = [@options.author]
    if _.isEmpty @options.author
      @operator.author = ["anonymous"]
    if not @options.tempDir
      @options.tempDir = path.resolve __dirname, "../tempDir/"
    @id = uuid()
    @uuid = path.resolve @options.tempDir, @id
    @options.uuid = @uuid
    @options.id = @id
    @options.images = []
    @options.content = _.map @options.content, (content, index)->
      titleSlug = uslug removeDiacritics content.title || "no title"
      content.filePath = path.resolve self.uuid, "./OEBPS/#{index}_#{titleSlug}.#{self.options.docType}"
      content.href = "#{index}_#{titleSlug}.#{self.options.docType}"
      content.id = "item_#{index}"

      #fix Author Array
      content.author =
        if content.author and _.isString content.author then [content.author]
        else if not content.author or not _.isArray content.author then []
        else content.author

      # Only body innerHTML is allowed
      #reg = /<body[^>]*>((.|[\n\r])*)<\/body>/
      #content.data = content.data.match(reg)?[1] || content.data
      ## replace with cheerio
      $ = cheerio.load content.data, {xmlMode: true}
      if $("body").length
        $ = cheerio.load $("body").html()
      $("img").each (index, elem)->
        url = $(elem).attr("src")
        id = uuid()
        $(elem).attr("src", "images/#{id}.jpg")
        self.options.images.push {id, url}
      content.data = $.html()
      content

    @render()
    @promise = @defer.promise
    @

  render: ()->
    self = @
    @generateTempFile().then ()->
      self.downloadAllImage().fin ()->
        self.makeCover().then ()->
          self.genEpub().then (result)->
            self.defer.resolve(result)
          , (err)->
            self.defer.reject(err)
        , (err)->
          self.defer.reject(err)
      , (err)->
        self.defer.reject(err)
    , (err)->
      self.defer.reject(err)

  generateTempFile: ()->
    generateDefer = new Q.defer()
    self = @
    if !fs.existsSync(@options.tempDir)
      fs.mkdirSync(@options.tempDir)
    fs.mkdirSync @uuid
    fs.mkdirSync path.resolve(@uuid, "./OEBPS")
    @options.css ||= ".epub-author{color: #555;}.epub-link{margin-bottom: 30px;}.epub-link a{color: #666;font-size: 90%;}.toc-author{font-size: 90%;color: #555;}.toc-link{color: #999;font-size: 85%;display: block;}hr{border: 0;border-bottom: 1px solid #dedede;margin: 60px 10%;}"
    fs.writeFileSync path.resolve(@uuid, "./OEBPS/style.css"), @options.css
    if self.options.fonts.length
      fs.mkdirSync(path.resolve @uuid, "./OEBPS/fonts")
      @options.fonts = _.map @options.fonts, (font)->
        if !fs.existsSync(font)
          generateDefer.reject(new Error('Custom font not found at ' + font + '.'))
          return generateDefer.promise
        filename = path.basename(font)
        fsextra.copySync(font, path.resolve self.uuid, "./OEBPS/fonts/" + filename)
        filename
    fs.mkdirSync(path.resolve @uuid, "./OEBPS/images")
    _.each @options.content, (content)->
      data = """#{self.options.docHeader}
        <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>#{content.title}</title>
        <link rel="stylesheet" type="text/css" href="style.css" />
        </head>
      <body>
      """
      data += if content.title and self.options.appendChapterTitles then "<h1>#{content.title}</h1>" else ""
      data += if content.title and content.author and content.author.length then "<p class='epub-author'>#{content.author.join(", ")}</p>" else ""
      data += if content.title and content.url then "<p class='epub-link'><a href='#{content.url}'>#{content.url}</a></p>" else ""
      data += "#{content.data}</body></html>"
      fs.writeFileSync(content.filePath, data)

    # write minetype file
    fs.writeFileSync(@uuid + "/mimetype", "application/epub+zip")

    # write meta-inf/container.xml
    fs.mkdirSync(@uuid + "/META-INF")
    fs.writeFileSync( "#{@uuid}/META-INF/container.xml", """<?xml version="1.0" encoding="UTF-8" ?><container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container"><rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles></container>""")

    # write meta-inf/com.apple.ibooks.display-options.xml [from pedrosanta:xhtml#6]
    fs.writeFileSync( "#{@uuid}/META-INF/com.apple.ibooks.display-options.xml","""
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <display_options>
        <platform name="*">
          <option name="specified-fonts">true</option>
        </platform>
      </display_options>
    """)

    opfPath = self.options.customOpfTemplatePath or path.resolve(__dirname, "./content.ejs")
    if !fs.existsSync(opfPath)
      generateDefer.reject(new Error('Custom file to OPF template not found.'))
      return generateDefer.promise

    ncxTocPath = self.options.customNcxTocTemplatePath or path.resolve(__dirname , "./toc.ejs" )
    if !fs.existsSync(ncxTocPath)
      generateDefer.reject(new Error('Custom file the NCX toc template not found.'))
      return generateDefer.promise

    htmlTocPath = self.options.customHtmlTocTemplatePath or path.resolve(__dirname, "./content.#{self.options.docType}")
    if !fs.existsSync(htmlTocPath)
      generateDefer.reject(new Error('Custom file to HTML toc template not found.'))
      return generateDefer.promise

    Q.all([
      Q.nfcall ejs.renderFile, opfPath, self.options
      Q.nfcall ejs.renderFile, ncxTocPath, self.options
      Q.nfcall ejs.renderFile, htmlTocPath, self.options
    ]).spread (data1, data2, data3)->
      fs.writeFileSync(path.resolve(self.uuid , "./OEBPS/content.opf"), data1)
      fs.writeFileSync(path.resolve(self.uuid , "./OEBPS/toc.ncx"), data2)
      fs.writeFileSync(path.resolve(self.uuid, "./OEBPS/contents.#{self.options.docType}"), data3)
      generateDefer.resolve()
    , (err)->
      console.error arguments
      generateDefer.reject(err)

    generateDefer.promise

  makeCover: ()->
    userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.116 Safari/537.36"
    coverDefer = new Q.defer()
    destPath = path.resolve @uuid, "./OEBPS/cover.jpg"
    if @options.cover
      writeStream = null
      if @options.cover.slice(0,4) is "http"
        writeStream = request.get(@options.cover).set 'User-Agent': userAgent
        writeStream.pipe(fs.createWriteStream(destPath))
      else
        writeStream = fs.createReadStream(@options.cover)
        writeStream.pipe(fs.createWriteStream(destPath))

      writeStream.on "end", ()->
        console.log "[Success] cover image downloaded successfully!"
        coverDefer.resolve()
      writeStream.on "error", (err)->
        console.log "Error", err
        console.log arguments
        coverDefer.reject(err)
    else
      coverDefer.resolve()

    coverDefer.promise


  downloadImage: (options)->  #{id, url}
    self = @
    userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.116 Safari/537.36"
    if not options.url and typeof options isnt "string"
      return false
    downloadImageDefer = new Q.defer()
    if options.url.indexOf("file://") == 0
      filename = path.resolve(self.uuid, "./OEBPS/images/" + options.id + ".jpg")
      auxpath = options.url.substr(7)
      fsextra.copySync(auxpath,filename)
      return downloadImageDefer.resolve(options)
    else
      requestAction = request.get(options.url).set 'User-Agent': userAgent
      filename = path.resolve self.uuid, ("./OEBPS/images/" + options.id + ".jpg")

      requestAction.pipe(fs.createWriteStream(filename))

      requestAction.on 'error', (err)->
        console.error '[Download Error]' ,'Error while downloading', options.url, err
        fs.unlinkSync(filename)
        downloadImageDefer.reject(err)

      requestAction.on 'end', ()->
        console.log "[Download Success]", options.url
        downloadImageDefer.resolve(options)

      downloadImageDefer.promise


  downloadAllImage: ()->
    self = @
    imgDefer = new Q.defer()
    if not self.options.images.length
      imgDefer.resolve()
    else
      deferArray = []
      _.each self.options.images, (image)->
        deferArray.push self.downloadImage(image)
      Q.all deferArray
      .fin ()->
        imgDefer.resolve()
    imgDefer.promise


  runCommand: (cmd, option)->
    defer = new Q.defer()
    exec cmd, option, (err, stderr, stdout)->
      if err
        console.error(cmd, stderr, stdout)
        defer.reject(err)
        return false
      if stderr
        console.warn stderr
      if stdout and option.quite
        console.log stdout
      defer.resolve stdout
    defer.promise


  genEpub: ()->
    # Thanks to Paul Bradley
    # http://www.bradleymedia.org/gzip-markdown-epub/

    genDefer = new Q.defer()

    self = @
    filename = "book.epub.zip"
    initCmd = "zip -q -X -0 #{filename} mimetype"
    zipCmd  = "zip -q -X -9 -r #{filename} * -x mimetype #{filename}"
    cleanUp = "mv #{filename} book.epub && rm -f -r META-INF OEBPS mimetype"
    cleanUp = "mv #{filename} book.epub"
    cwd = @uuid
    self.runCommand(initCmd, {cwd}).then ()->
      self.runCommand(zipCmd, {cwd}).then ()->
        self.runCommand(cleanUp, {cwd}).then ()->
          stream = fs.createReadStream( path.resolve self.uuid, "book.epub" )
          stream.pipe fs.createWriteStream self.options.output
          stream.on "error", (err)->
            console.error(err)
            self.defer.reject(err)
          stream.on "end", ()->
            self.defer.resolve()
            currentDir = self.options.tempDir
            self.runCommand("rm -f -r #{self.id}/", {cwd: currentDir})
        , (err)->
          genDefer.reject(err)
      , (err)->
        genDefer.reject(err)
    , (err)->
      genDefer.reject(err)

    genDefer.promise

module.exports = EPub