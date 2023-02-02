all:
	v .
	v fmt -w main.v sax/lib.v
	-./vx2doc
	./vx2doc test.xml
# ./vx2doc ../examples/list.xml
