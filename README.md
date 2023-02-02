# Stream XML parser for the V language

This module implements a simple and fast way to read large xml files.

## Author

pancake@nopcode.org

## Usage

See [main.v](main.v)

```v
struct XmlToHtml {
mut:
	// custom shit
	depth int
	res   string
}

fn (mut mp XmlToHtml) document_start(mut st sax.SaxParser) ! {
	...
}

...

fn main() {
	if os.args.len < 2 {
		println('vx2doc file.xml')
		exit(1)
	}
	argv := os.args[1]
	file_xml := os.read_file(argv)!

	mut to_html := XmlToHtml{}
	mut p := sax.new_parser(mut to_html)
	p.parse(file_xml) or { println('parsing failed ${err}') }
	println(to_html.res)
}
```
