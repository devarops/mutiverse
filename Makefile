all:
	src/main.lua

.PHONY: \
	all \
	check \
	clean \
	init \
	parse \
	setup \
	tests

check:
	luacheck src

clean:
	rm --force --recursive templater

init: setup parse tests

setup: clean
	git clone https://github.com/IslasGECI/templater.git
	cd templater && make init

tests:
	busted tests/test.lua

parse:
	tree-sitter parse --lib-path /opt/tree-sitter-r/r.so templater/R/do_nothing.R
