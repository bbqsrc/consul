using Curses;

void draw_scrollbar(Window scrw, int len, int o)
{
	scrw.bkgdset(COLOR_PAIR(2));
	for(int i = 0; i < LINES-1; i++){
		scrw.mvaddch(i, 0, ' ');
	}

	scrw.attrset(COLOR_PAIR(3));
	int scrlbudlen = len / (LINES-1);
	
	if (len > LINES-1) {
		int offset = o / scrlbudlen;
		for (int i = 0; i <= scrlbudlen; i++) {
			scrw.mvaddch(offset + i, 0, '|');
		}
	}
	scrw.refresh();
}

void curses_init(string[] files) 
{
    initscr ();
    noecho();
	start_color ();
    init_pair (1, Color.WHITE, Color.BLACK);
	init_pair (2, Color.WHITE, Color.BLUE);
	init_pair (3, Color.WHITE, Color.RED);
	curs_set(0);

	int offset = 0;
	int cur = 0;
	int MAINWIN = LINES-2;

    /* Create a window (height/lines, width/columns, y, x) */
    var win = new Window (LINES-1, COLS-1, 0, 0);
    win.bkgdset (COLOR_PAIR (1) | Attribute.BOLD);  // set background
	win.scrollok(true);

	var sclbar = new Window (LINES-1, 1, 0, COLS-1);
    sclbar.bkgdset (COLOR_PAIR (2) | Attribute.BOLD);  // set background
	draw_scrollbar(sclbar, files.length, offset);

	var statusbar = new Window(1, COLS, LINES-1, 0);
	statusbar.bkgdset (COLOR_PAIR(2));
	//statusbar.mvaddstr(0, 0, "This is a test!");
	statusbar.clear();
	statusbar.refresh();
	
	for (int i = 0; i <= MAINWIN; i++) {
		if (i < files.length) {
			win.mvaddstr(i, 0, files[cur++]);
		}
		win.refresh();
	}

	//input loop
	bool die = false;
	while (!die) {
		unichar c = win.getch();
		switch (c) {
			case 'n':
				if ((LINES + offset) < files.length-1) {
					win.scrl(1);
					win.mvaddstr(LINES-2, 0, files[LINES + offset++]);
					win.refresh();
				} else {
					statusbar.addch('!');
					statusbar.refresh();
				}
				break;
			case 'p':
				if (offset > 0) {
					win.scrl(-1);
					win.mvaddstr(0, 0, files[--offset]);
					win.refresh();
				} else {
					statusbar.addch('!');
					statusbar.refresh();
				}
				break;
			case 'q':
				endwin ();
				die = true;
				break;
		}
		draw_scrollbar(sclbar, files.length, offset);
	}
}

int main (string[] args) {
    try {
        var directory = File.new_for_path (".");

        if (args.length > 1) {
            directory = File.new_for_commandline_arg (args[1]);
        }

        var enumerator = directory.enumerate_children (FILE_ATTRIBUTE_STANDARD_NAME, 0);

        FileInfo file_info;
		string[] files = {};
        while ((file_info = enumerator.next_file ()) != null) {
             files += file_info.get_name();
        }
		curses_init(files);	
		

    } catch (Error e) {
        stderr.printf ("Error: %s\n", e.message);
        return 1;
    }

    return 0;
}

