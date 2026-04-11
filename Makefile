all:
	src/main.lua

.PHONY: \
	all \
	check \
	parse \
	tests

check:
	luacheck src

tests:
	busted tests/test.lua

parse:
	tree-sitter parse --xml --lib-path /opt/tree-sitter-python/python.so tests/data/transformations.py
	tree-sitter parse --xml --lib-path /opt/tree-sitter-r/r.so tests/data/do_nothing.R
	tree-sitter parse --cst --lib-path /opt/tree-sitter-python/python.so tests/data/transformations.py
	tree-sitter parse --cst --lib-path /opt/tree-sitter-r/r.so tests/data/do_nothing.R
