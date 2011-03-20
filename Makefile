all: ;
	valac --pkg gio-2.0 --pkg curses -X -lncurses consul.vala

clean: ;
	rm consul
