import pdf
import sax
import os

struct XmlToHtml {
mut:
	// custom shit
	depth int
	res   string
}

fn (mut mp XmlToHtml) document_start(mut st sax.SaxParser) ! {
	mp.res += 'INIT\n'
	println('init')
}

fn (mut mp XmlToHtml) document_end(mut st sax.SaxParser) ! {
	println('fini')
}

fn (mut mp XmlToHtml) element_start(mut st sax.SaxParser, name string, attrs []sax.SaxAttribute) ! {
	if mp.depth == 0 {
		if name != 'xmldoc' {
			return error('Invalid root directory ${name}')
		}
	}
	println('tag_open: <${name}>')
	for a in attrs {
		println('   KV (${a.key}) = (${a.val})')
	}
	mp.depth++
}

fn (mut mp XmlToHtml) element_end(mut st sax.SaxParser, name string) ! {
	println('tag_close: </${name}>')
	mp.depth--
}

fn (mut mp XmlToHtml) comment(mut st sax.SaxParser, text string) ! {
	println('comment: ${text}')
}

fn (mut mp XmlToHtml) characters(mut st sax.SaxParser, text string) ! {
	println('text: ${text}')
}

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
