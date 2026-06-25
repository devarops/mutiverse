.PHONY: \
	check \
	parse \
	tests \
	verify

check:
	luacheck src

tests:
	busted tests/test.lua

verify:
	qed verify specs/mutiverse.spec.json

parse:
	tree-sitter parse --xml --lib-path /opt/tree-sitter-python/python.so tests/data/transformations.py
	tree-sitter parse --xml --lib-path /opt/tree-sitter-r/r.so tests/data/do_nothing.R
	tree-sitter parse --cst --lib-path /opt/tree-sitter-python/python.so tests/data/transformations.py
	tree-sitter parse --cst --lib-path /opt/tree-sitter-r/r.so tests/data/do_nothing.R

init: parse tests
