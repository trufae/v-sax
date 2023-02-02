# Stream XML parser for the V language

This module implements a simple and fast way to parse xml files.

## Author

pancake@nopcode.org

## Known Issues and limitations

This library is in a very early stage of development, so things can change and bugs can appear.

* [ ] Not suitable for large files be (input data is copied into a string)
* [ ] use a callback or reader api to peek() from somewhere else
* [ ] Only expect utf8 encodings

## Usage

See [main.v](main.v)

```sh
$ v -o vsax main.v
$ ./vsax test.xml
```

```v
import sax
import os

struct XmlToHtml {
mut:
	depth int
	res   string
}

fn (mut mp XmlToHtml) document_start(mut st sax.SaxParser) ! {
	...
}

...

fn main() {
	if os.args.len < 2 {
		println('vsax file.xml')
		exit(1)
	}
	file_xml := os.read_file(os.args[1])!

	mut to_html := XmlToHtml{}
	mut p := sax.new_parser(mut to_html)
	p.parse(file_xml) or { println('parsing failed ${err}') }
	println(to_html.res)
}
```
