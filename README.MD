# Library to make Epub from HTML

[![Join the chat at https://gitter.im/cyrilis/epub-gen](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/cyrilis/epub-gen?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Generate EPUB books from HTML with simple API in Node.js.

------

This epub library will generate temp html and download images in your DOMs, then generate the epub book you want.

It's very fast, except the time to download images from the web.


## Usage

Firstly, make sure you have `zip` installed. then cd to your project dir, run:

	npm install epub-gen

put this in your code:

```javascript
    var Epub = require("epub-gen")

    new Epub(option [, output]).promise.then(function(){
        console.log("Ebook Generated Successfully!")
   	}, function(err){
        console.error("Failed to generate Ebook because of ", err)
    })
```

#### Options

- `title`:
    Title of the book
- `author`:
    Name of the author for the book, string or array both Okay, eg. `"Alice"` or `["Alice", "Bob"]`
- `publisher`:
    Publisher name (optional)
- `cover`:
    Book cover image, File path (absolute path) or web url both ok. eg. `"http://abc.com/book-cover.jpg"` or `"/User/Alice/images/book-cover.jpg"`
- `output`
    Out put path(absolute path), you can also path output as the second argument when use `new` , eg: `new Epub(options, output)`
- `css`:
    If you really hate our css, you can pass css string to replace our default style. eg: `"body{background: #000}"`
- `fonts`:
    Array of (absolute) paths to custom fonts to include on the book so they can be used on custom css. Ex: if you configure the array to `fonts: ['/path/to/Merriweather.ttf']` you can use the following on the custom CSS:

    ```
    @font-face {
        font-family: "Merriweather";
        font-style: normal;
        font-weight: normal;
        src : url("./fonts/Merriweather.ttf");
    }
    ```
- `lang`:
    Language of the book in 2 letters code (optional). If not specified, will fallback to `en`.
- `appendChapterTitles`:
    Automatically append the chapter title at the beginning of each contents. You can disable that by specifying `false`.
- `customOpfTemplatePath`:
    Optional. For advanced customizations: absolute path to an OPF template.
- `customNcxTocTemplatePath`:
    Optional. For advanced customizations: absolute path to a NCX toc template.
- `customHtmlTocTemplatePath`:
    Optional. For advanced customizations: absolute path to a HTML toc template.
- `content`:
    Book Chapters content. It's should be an array of objects. eg. `[{title: "Chapter 1",data: "<div>..."}, {data: ""},...]`

    **Within each chapter object:**

    - `title`:
        optional, Chapter title
    - `author`:
        optional, if each book author is different, you can fill it.
    - `data`:
        HTML String of the chapter content. image paths should be absolute path (should start with "http" or "https"), so that they could be downloaded. With the upgrade is possible to use images that are in place (for this the path 	must start with file: //)


#### Output
if you don't want pass the output pass the output path as the second argument, you should specify output path as `option.outpath`

------

## Demo Code:

```javascript
    var Epub = require("epub-gen")

    var option = {
        title: "Simple Book", // *Required, title of the book.
        author: "Me", // *Required, name of the author.
        publisher: "Demo Inc.", // optional
        cover: "http://demo.com/url-to-cover-image.jpg", // Url or File path both ok.
        content: [
            {
                title: "Chapter 1", // Optional
                author: "author", // Optional
                data: "<h1>Learning JavaScript Design Patterns</h1>"
                +"<div lang=\"en\"><div>.....</div>" // pass html string
            },
            {
                title: "Chapter 2",
                data: "<html><head> ......</html>"
            },
            {
                ...
            }
            ...
        ]
    };

    new Epub(option, "/path/to/book/file/path.epub");

```

------

## Demo Preview:

![Demo File Preview](http://s3.again.cc/capture/2015-02-14_163343.png)

Simple html from: http://addyosmani.com/resources/essentialjsdesignpatterns/book/

## License

(The MIT License)

Copyright (c) 2015 Cyril Hou &lt;houshoushuai@gmail.com&gt;

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
