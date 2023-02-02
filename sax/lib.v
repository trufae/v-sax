module sax

pub struct SaxAttribute {
pub:
	key string
	val string
}

// pub type SaxEventStartDocument = fn (mut SaxParser)

pub interface SaxCallbacks {
mut:
	document_start(mut SaxParser) !
	document_end(mut SaxParser) !
	element_start(mut SaxParser, string, []SaxAttribute) !
	element_end(mut SaxParser, string) !
	comment(mut SaxParser, string) !
	characters(mut SaxParser, string) !
}

pub struct SaxParser {
mut:
	data   string
	chars  string
	cursor int
	line   int
	on     SaxCallbacks
}

pub fn new_parser(mut callbacks SaxCallbacks) SaxParser {
	return SaxParser{
		on: callbacks
	}
}

fn (mut parser SaxParser) peek() !string {
	if parser.cursor >= parser.data.len {
		// end of document
		return error('unexpected end of document')
	}
	// ch := parser.data[parser.cursor].vstring()
	ch := parser.data[parser.cursor]
	parser.cursor++
	str := '' + unsafe { ch.vstring_with_len(1) }
	if str == '\n' {
		parser.line++
	}
	return str
}

pub fn (mut parser SaxParser) parse_comment() !string {
	mut msg := ''
	for {
		ch := parser.peek()!
		if ch == '>' {
			// end of comment
			break
		} else {
			msg += ch.str()
		}
	}
	return msg
}

fn peek_until(mut parser SaxParser, x string) !string {
	mut text := ''
	for {
		mut ch := parser.peek()!
		if ch == '\\' {
			text += ch
			ch = parser.peek()!
		} else if ch == x {
			break
		}
		text += ch
	}
	return text
}

pub fn (mut parser SaxParser) parse_attributes() ![]SaxAttribute {
	mut attrs := []SaxAttribute{}
	mut key := ''
	for {
		ch := parser.peek()!
		match ch {
			' ' {}
			'>' {
				break
			}
			'=' {
				q0 := parser.peek()!
				if q0 == '"' {
					val := peek_until(mut parser, '"')!
					attrs << SaxAttribute{
						key: key
						val: val
					}
					key = ''
				}
			}
			else {
				key += ch
			}
		}
	}
	return attrs
}

pub fn (mut parser SaxParser) parse_tag() ! {
	mut ch := parser.peek()!
	match ch {
		'!' {
			mut text := peek_until(mut parser, '>')!
			parser.on.comment(mut parser, text)!
		}
		'/' {
			ch = parser.peek()!
			mut text := ch + peek_until(mut parser, '>')!
			parser.on.element_end(mut parser, text)!
		}
		else {
			mut attrs := []SaxAttribute{}
			mut name := ''
			for {
				match ch {
					'>' {
						break
					}
					' ' {
						attrs = parser.parse_attributes()!
						break
					}
					else {
						name += ch
					}
				}
				ch = parser.peek()!
			}
			parser.on.element_start(mut parser, name, attrs)!
		}
	}
}

fn flush_chars(mut parser SaxParser) ! {
	if parser.chars.len > 0 {
		parser.on.characters(mut parser, parser.chars)!
		parser.chars = ''
	}
}

pub fn (mut parser SaxParser) parse(input string) ! {
	parser.data = input
	parser.on.document_start(mut parser)!
	for {
		ch := parser.peek() or {
			// eof
			break
		}
		match ch {
			'<' {
				flush_chars(mut parser)!
				parser.parse_tag()!
			}
			else {
				parser.chars += ch
			}
		}
	}
	flush_chars(mut parser)!
	parser.on.document_end(mut parser)!
}
