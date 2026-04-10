all:
	src/main.lua

.PHONY: \
	all \
	check \
	clean \
	init \
	setup \
	tests

check:
	luacheck src

clean:
	rm --force --recursive templater

init: setup tests

setup: clean
	git clone https://github.com/IslasGECI/templater.git
	cd templater && make init
	tree-sitter parse --lib-path /opt/tree-sitter-r/r.so templater/R/do_nothing.R

tests:
	busted tests/test.lua
