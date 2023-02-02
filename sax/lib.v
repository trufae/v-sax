module sax

import strings

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
	sb     strings.Builder
	cursor int
	line   int
	on     SaxCallbacks
}

pub fn new_parser(mut callbacks SaxCallbacks) Parser {
	return Parser{
		on: callbacks
	}
}

[direct_array_access; inline]
fn (mut parser Parser) peek() !rune {
	if parser.cursor >= parser.data.len {
		// end of document
		return error('unexpected end of document')
	}
	ch := parser.data[parser.cursor]
	parser.cursor++
	if ch == `\n` {
		parser.line++
	}
	return ch
}

pub fn (mut parser Parser) parse_comment() !string {
	mut msg := strings.new_builder(1024)
	for {
		ch := parser.peek()!
		if ch == `>` {
			// end of comment
			break
		} else {
			msg.write_rune(ch)
		}
	}
	return msg.str()
}

fn peek_until(mut parser Parser, x rune) !string {
	mut text := strings.new_builder(128)
	for {
		ch := parser.peek()!
		if ch == `\\` {
			text.write_rune(ch)
			text.write_rune(parser.peek()!)
		} else if ch == x {
			break
		} else {
			text.write_rune(ch)
		}
	}
	return text.str()
}

pub fn (mut parser Parser) parse_attributes() ![]Attribute {
	mut attrs := []Attribute{}
	mut key := strings.new_builder(128)
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
						key: key.str()
						val: val
					}
					key.clear()
				}
			}
			else {
				key.write_rune(ch)
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
			mut name := strings.new_builder(100)
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
						name.write_rune(ch)
					}
				}
				ch = parser.peek()!
			}
			parser.on.element_start(mut parser, name.str(), attrs)!
		}
	}
}

fn (mut parser Parser) flush_chars() ! {
	if parser.sb.len > 0 {
		chars := parser.sb.str()
		parser.on.characters(mut parser, chars)!
		parser.sb.clear()
	}
}

pub fn (mut parser Parser) parse(input string) ! {
	parser.sb = strings.new_builder(1000)
	parser.data = input
	parser.on.document_start(mut parser)!
	for {
		ch := parser.peek() or { break }
		match ch {
			`<` {
				parser.flush_chars()!
				parser.parse_tag()!
			}
			else {
				parser.sb.write_rune(ch)
			}
		}
	}
	parser.flush_chars()!
	parser.on.document_end(mut parser)!
}
