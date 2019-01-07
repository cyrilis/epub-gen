# epub-gen - a library to make EPUBs from HTML

[![Join the chat at https://gitter.im/cyrilis/epub-gen](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/cyrilis/epub-gen?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Generate EPUB books from HTML with simple API in Node.js.

------

This epub library will generate temp html and download images in your DOMs, then generate the epub book you want.

It's very fast, except the time to download images from the web.


## Usage

Install the lib and add it as a dependency (recommended), run on your project dir:

	npm install epub-gen --save

Then put this in your code:

```javascript
    const Epub = require("epub-gen");

    new Epub(option [, output]).promise.then(
        () => console.log("Ebook Generated Successfully!"),
	err => console.error("Failed to generate Ebook because of ", err)
    );
```

#### Options

- `title`:
    Title of the book
- `author`:
    Name of the author for the book, string or array, eg. `"Alice"` or `["Alice", "Bob"]`
- `publisher`:
    Publisher name (optional)
- `cover`:
    Book cover image (optional), File path (absolute path) or web url, eg. `"http://abc.com/book-cover.jpg"` or `"/User/Alice/images/book-cover.jpg"`
- `output`
    Out put path (absolute path), you can also path output as the second argument when use `new` , eg: `new Epub(options, output)`
- `version`:
    You can specify the version of the generated EPUB, `3` the latest version (http://idpf.org/epub/30) or `2` the previous version (http://idpf.org/epub/201, for better compatibility with older readers). If not specified, will fallback to `3`.
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
- `tocTitle`:
    Title of the table of contents. If not specified, will fallback to `Table Of Contents`.
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
        required, HTML String of the chapter content. image paths should be absolute path (should start with "http" or "https"), so that they could be downloaded. With the upgrade is possible to use local images (for this the path 	must start with file: //)
    - `excludeFromToc`:
        optional, if is not shown on Table of content, default: false;
    - `beforeToc`:
        optional, if is shown before Table of content, such like copyright pages. default: false;
    - `filename`:
        optional, specify filename for each chapter, default: undefined;
- `verbose`:
    specify whether or not to console.log progress messages, default: false.

#### Output
If you don't want pass the output pass the output path as the second argument, you should specify output path as `option.output`.

------

## Demo Code:

```javascript
    const Epub = require("epub-gen");

    const option = {
        title: "Alice's Adventures in Wonderland", // *Required, title of the book.
        author: "Lewis Carroll", // *Required, name of the author.
        publisher: "Macmillan & Co.", // optional
        cover: "http://demo.com/url-to-cover-image.jpg", // Url or File path, both ok.
        content: [
            {
                title: "About the author", // Optional
                author: "John Doe", // Optional
                data: "<h2>Charles Lutwidge Dodgson</h2>"
                +"<div lang=\"en\">Better known by the pen name Lewis Carroll...</div>" // pass html string
            },
            {
                title: "Down the Rabbit Hole",
                data: "<p>Alice was beginning to get very tired...</p>"
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

![Demo Preview](demo_preview.png?raw=true)

_From Lewis Carroll "Alice's Adventures in Wonderland", based on text at https://www.cs.cmu.edu/~rgs/alice-table.html and images from http://www.alice-in-wonderland.net/resources/pictures/alices-adventures-in-wonderland._

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
