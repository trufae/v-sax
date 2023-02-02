all:
	v -o vsax main.v
	v fmt -w **.v
	-./vsax
	./vsax test.xml

clean:
	rm -f vsax main
