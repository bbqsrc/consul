using Curses;

public class Statusbar : GLib.Object
{
	private int msgmax;
	private int[] msgpos;
	private Window win;
	private int color = 0;
	private string[] message;

	public Statusbar(int y, int x, int yoff, int xoff)
	{
		this.win = new Window(y, x, yoff, xoff);
		this.win.bkgdset(color);
		this.message = new string[3];
		msgmax = (win.getmaxx() - 6) / 3;
		msgpos = {0, msgmax+3, msgmax+msgmax+6};
		show();
	}

	public void set_color(int c)
	{
		color = c;
		win.bkgdset(color);
		show();
	}

	public bool add_message(string msg, uint p)
	{
		if (p <= 3 && msg.length <= msgmax) {
			message[p] = msg;
			return true;
		}
		return false;
	}

	public bool add_message_r(string msg, uint p)
	{
		int l = msg.length;
		string s = "";
		for (int i = 0; i < msgmax; ++i) {
			if (i < (msgmax - l))
				s += " ";
			else {
				s += msg;
				break;
			}
		}
		return add_message(s, p);
	}

	public bool del_message(uint p)
	{
		if (p <= 3) {
			message[p] = "";
			return true;
		}
		return false;
	}

	public void show() {
		win.clear();
		for (int i = 0; i < 3; ++i) {
			win.mvaddstr(0, msgpos[i], message[i]);
		}
		win.mvaddch(0, msgmax+1, '|');
		win.mvaddch(0, msgmax*2+2, '|');
		win.mvaddch(0, msgmax*3+3, '|');
		win.refresh();
	}
}

public class Menu : GLib.Object
{
	private Statusbar status;

	private Window scrlwin;
	private const unichar BUD = '|';

	public Window win;// {get; private set;}
	private string[] items;
	public int selected { get; private set; default = 0; }
	public int offset { get; private set; default = 0; }

	public Menu(int y, int x, 
				int yoff, int xoff, 
				string[] items, bool scrl=false) 
	{
		if (scrl) {
			this.win = new Window(y, x-1, yoff, xoff);
			this.scrlwin = new Window(y, 1, yoff, x-1);
		} else {
			this.win = new Window(y, x, yoff, xoff);
		}
		status = new Statusbar(1, x, y, 0);
		status.set_color(COLOR_PAIR(2) | Attribute.BOLD);

		this.items = {};
		for (int i = 0; i < items.length; ++i) {
			if(items[i][0] != '.')
				this.items += items[i]; 
		}

		status.add_message("Consul Test :)", 0);
		status.add_message("... something ...", 1);
		status.add_message_r(@"$(selected+offset)/$(length())", 2);
		generate();
	}
	
	public string? get_item(int x)
	{
		if (x < items.length) 
			return items[x];
		return null;
	}

	public int length()
	{
		return items.length - 1;
	}

	public void scroll_up()
	{
		if (selected == 0) {
			if (offset > 0) //< items.length)
				--offset;
		} else if (selected > 0) {
			--selected;
		}
		generate(offset);
	}

	public void scroll_down()
	{
		if (selected == win.getmaxy()-1) {
			if ((win.getmaxy()-1 + offset) < length())
				++offset;
		} else if (selected < length()) {
			++selected;
		}
		generate(offset);
	}

	public void keypress(int key)
	{
		switch(key) {
			case Key.UP:
			case 'p':
				scroll_up();
				break;
			case Key.DOWN:
			case 'n':
				scroll_down();
				break;
			default:
				break;
		}
		
	}
	
	public void generate(int offset=0, int x=0) 
	{
		win.clear();
		for (int c = 0; c <= win.getmaxy()-1; ++c) {
			if (c == selected)
				win.attron(Attribute.REVERSE);
			win.mvaddstr(c, x, items[c + offset]);
			win.attroff(Attribute.REVERSE);
			win.noutrefresh();
		}
		if (scrlwin != null) {
			scrlwin.bkgdset(COLOR_PAIR(2)); //TODO color pair as a variable
			for(int i = 0; i < win.getmaxy(); i++){
				scrlwin.mvaddch(i, 0, ' ');
			}
	
			scrlwin.attrset(COLOR_PAIR(3));
			if (length() > scrlwin.getmaxy()) {
				int o = (((selected+offset)*100 / length()) * 100 / (10000 / (scrlwin.getmaxy()-1)));
				scrlwin.mvaddch(o, 0, BUD);
			}
			status.add_message_r(@"$(selected+offset)/$(length())", 2);
			status.show();
			scrlwin.noutrefresh();
		}
		doupdate();
	}
}

void curses_init(string[] files) 
{
    initscr();
    noecho();
	start_color();
    init_pair(1, Color.WHITE, Color.BLACK);
	init_pair(2, Color.WHITE, Color.BLUE);
	init_pair(3, Color.WHITE, Color.RED);
	curs_set(0);

	var list = new Menu(LINES-1, COLS, 0, 0, files, true);
    list.win.bkgdset (COLOR_PAIR (1) | Attribute.BOLD);  // set background
	list.win.scrollok(true);
	list.generate();
	
	for (;;) {
		int c = list.win.getch();
		if(c == 'q')
			break;
		list.keypress(c);
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
		endwin();

    } catch (Error e) {
        stderr.printf ("Error: %s\n", e.message);
        return 1;
    }

    return 0;
}

