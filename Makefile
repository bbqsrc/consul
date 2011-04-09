all: ;
	valac --vapidir=. --pkg gee-1.0 --pkg gio-2.0 --pkg curses -X -lncurses consul.vala console.vala

xcurses: ;
	valac -C --vapidir=. --pkg gee-1.0 --pkg gio-2.0 --pkg curses consul.vala
	gcc -o consul.x11 consul.vala.o -I/opt/local/include -L/opt/local/lib -lglib-2.0 -lgobject-2.0 -lgio-2.0 `xcurses-config --cflags` `xcurses-config --libs`

clean: ;
	rm consul consul.vala.o consul.vala.c consul.vala.h

c: ;
	valac -C --vapidir=. --pkg gee-1.0 --pkg gio-2.0 --pkg curses consul.vala
