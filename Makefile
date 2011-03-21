all: ;
	valac --vapidir=. --pkg gio-2.0 --pkg curses -X -lncurses consul.vala

clean: ;
	rm consul consul.vala.o consul.vala.c consul.vala.h

c: ;
	valac -C --vapidir=. --pkg gio-2.0 --pkg curses consul.vala
