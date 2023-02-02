module sax

pub struct Attribute {
pub:
	key string
	val string
}

pub interface SaxCallbacks {
mut:
	document_start(mut Parser) !
	document_end(mut Parser) !
	element_start(mut Parser, string, []Attribute) !
	element_end(mut Parser, string) !
	comment(mut Parser, string) !
	characters(mut Parser, string) !
}

pub struct Parser {
mut:
	data   string
	chars  string
	cursor int
	line   int
	on     SaxCallbacks
}

pub fn new_parser(mut callbacks SaxCallbacks) Parser {
	return Parser{
		on: callbacks
	}
}

fn (mut parser Parser) peek() !rune {
	if parser.cursor >= parser.data.len {
		// end of document
		return error('unexpected end of document')
	}
	// ch := parser.data[parser.cursor].vstring()
	ch := parser.data[parser.cursor]
	parser.cursor++
	if ch == `\n` {
		parser.line++
	}
	return ch
}

pub fn (mut parser Parser) parse_comment() !string {
	mut msg := ''
	for {
		ch := parser.peek()!
		if ch == `>` {
			// end of comment
			break
		} else {
			msg += '${ch}'
		}
	}
	return msg
}

fn peek_until(mut parser Parser, x rune) !string {
	mut text := ''
	for {
		mut ch := parser.peek()!
		if ch == `\\` {
			text += '${ch}'
			ch = parser.peek()!
		} else if ch == x {
			break
		}
		text += '${ch}'
	}
	return text
}

pub fn (mut parser Parser) parse_attributes() ![]Attribute {
	mut attrs := []Attribute{}
	mut key := ''
	for {
		ch := parser.peek()!
		match ch {
			` ` {}
			`>` {
				break
			}
			`=` {
				q0 := parser.peek()!
				if q0 == `"` {
					val := peek_until(mut parser, `"`)!
					attrs << Attribute{
						key: key
						val: val
					}
					key = ''
				}
			}
			else {
				key += '${ch}'
			}
		}
	}
	return attrs
}

pub fn (mut parser Parser) parse_tag() ! {
	mut ch := parser.peek()!
	match ch {
		`!` {
			text := peek_until(mut parser, `>`)!
			parser.on.comment(mut parser, text)!
		}
		`/` {
			ch = parser.peek()!
			text := '${ch}' + peek_until(mut parser, `>`)!
			parser.on.element_end(mut parser, text)!
		}
		else {
			mut attrs := []Attribute{}
			mut name := ''
			for {
				match ch {
					`>` {
						break
					}
					` ` {
						attrs = parser.parse_attributes()!
						break
					}
					else {
						name += '${ch}'
					}
				}
				ch = parser.peek()!
			}
			parser.on.element_start(mut parser, name, attrs)!
		}
	}
}

fn (mut parser Parser)flush_chars() ! {
	if parser.chars.len > 0 {
		parser.on.characters(mut parser, parser.chars)!
		parser.chars = ''
	}
}

pub fn (mut parser Parser) parse(input string) ! {
	parser.data = input
	parser.on.document_start(mut parser)!
	for {
		ch := parser.peek() or {
			// eof
			break
		}
		match ch {
			`<` {
				parser.flush_chars()!
				parser.parse_tag()!
			}
			else {
				parser.chars += '${ch}'
			}
		}
	}
	parser.flush_chars()!
	parser.on.document_end(mut parser)!
}
