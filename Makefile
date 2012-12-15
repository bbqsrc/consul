all:
	valac --vapidir=src --pkg gee-1.0 --pkg gio-2.0 --pkg curses -X -lncurses src/**/*.vala -o consul
	valac --pkg gio-2.0 src/detect_rom.vala src/rom/*.vala -o detect_rom

clean:
	rm consul detect_rom src/**/*.c src/**/*.o

debug: 
	valac -C --vapidir=. --pkg gee-1.0 --pkg gio-2.0 --pkg curses src/**/*.vala

#xcurses:
#	valac -C --vapidir=. --pkg gee-1.0 --pkg gio-2.0 --pkg curses src/**/*.vala
#	gcc -o consul.x11 consul.vala.o -I/opt/local/include -L/opt/local/lib -lglib-2.0 -lgobject-2.0 -lgio-2.0 `xcurses-config --cflags` `xcurses-config --libs`

