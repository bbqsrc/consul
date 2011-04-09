using Curses;
using Gee;

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
		win.refresh();
	}
}

public class Menu : GLib.Object
{
	private Statusbar status;

	private Window scrlwin;
	private Window infobox;

	private const unichar BUD = '|';
	private File directory;
	
	public Window win;
	private int depth = -1;
	//protected FileInfo[] items;
	private ArrayList<string> items;
	public int selected { get; private set; default = 0; }
	public int offset { get; private set; default = 0; }

	public KeyFile config;

	public Menu(int y, int x, 
				int yoff, int xoff, 
				string dir, bool scrl=false)
	{
		this.config = new KeyFile();
		get_config();
		
		if (scrl) {
			this.win = new Window(y, x-1, yoff, xoff);
			this.scrlwin = new Window(y, 1, yoff, x-1);
		} else {
			this.win = new Window(y, x, yoff, xoff);
		}
		infobox = new Window(y - 6, x - 12, yoff + 3, xoff + 6);
		infobox.bkgdset(COLOR_PAIR(2) | Attribute.BOLD);
		
		status = new Statusbar(1, x, y, 0);
		status.set_color(COLOR_PAIR(2) | Attribute.BOLD);
		
		set_directory(dir);

		status.add_message("Consul Alpha", 0);
		status.add_message(@"DEBUG: Depth $depth", 1);
		status.add_message_r(@"$(selected+offset)/$(length())", 2);
		generate();
	}
	
	public string? get_item(int x)
	{
		if (x < items.size) 
			return items.get(x);
		return null;
	}

	public int length()
	{
		//return items.length - 1;
		return items.size - 1;
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

	public void info_window()
	{
		infobox.clear();
		//infobox.addstr("Herpy derpy!");
		string f = items.get(offset+selected);
		var rom = get_rom(directory.get_path() + "/" + f);
		infobox.addstr(get_rom_data(rom));
		infobox.clrtoeol();
		infobox.noutrefresh();
		doupdate();
		//infobox.getch();
	}

	public string? keypress(int key)
	{
		switch(key) {
			case 'i':
				info_window();
				break;
			case 'p':
			case Key.UP:
				scroll_up();
				break;
			case 'n':
			case Key.DOWN:
				scroll_down();
				break;
			case 'e':
			case Key.RIGHT:
			case Key.ENTER:
				do_selected();
				generate();
				break;
			case Key.LEFT:
			case 'u':
				set_directory(directory.get_path() + "/..");
				generate();
				break;
			default:
				break;
		}
		return null;
	}

	public void set_directory(string d)
	{
		try {
			if ("/.." in d)
				if (depth > 0)
					--depth;
				else return; // stop going up
			else
				++depth;
			status.add_message(@"DEBUG: Depth $depth", 1);

			directory = File.new_for_commandline_arg(d);
			var enumerator = directory.enumerate_children 
				(FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_TYPE, 0);
	
			FileInfo file_info;

			items = new ArrayList<string>();
			var files = new ArrayList<string>();
			var dirs = new ArrayList<string>();
			
			string name;
			while ((file_info = enumerator.next_file ()) != null) {
				name = file_info.get_name();
				if (name[0] != '.') {
					if (file_info.get_file_type() == FileType.DIRECTORY)
						dirs.add(name);
					else
						files.add(name);
				}
			}
			dirs.sort();
			files.sort();
			items.add_all(dirs);
			items.add_all(files);
			
			selected = 0;
			offset = 0;

    	}
		catch (Error e) {
			stderr.printf ("Error: %s\n", e.message);
    	}
	}

	private bool is_directory(string d)
	{
		try {
			var file = File.new_for_path(directory.get_path() + "/" + d);
			var f = file.query_info("*", FileQueryInfoFlags.NONE);
			if (f.get_file_type() == FileType.DIRECTORY)
				return true;
			return false;
		}
		catch(Error e) {
			return false;
		}
	}

	public void do_selected() 
	{
		var f = items.get(selected + offset);
		if(is_directory(f))
			set_directory(directory.get_path() + "/" + f);
		//stub
	}

	public void generate(int offset=0, int x=0) 
	{
		generate_list(offset, x);
		if (scrlwin != null)
			generate_scrollbar(offset, x);
		status.show();
		doupdate();
	}

	private void generate_list(int offset=0, int x=0)
	{
		win.clear();
		for (int c = 0; c <= length(); ++c) {
			if (c == selected)
				win.attron(Attribute.REVERSE);
			if (c + offset <= length()) {
				string item = items.get(c + offset);
				if(is_directory(item))
					item += " >";
				if (item != null)
					win.mvaddstr(c, x, item);
			}
			win.attroff(Attribute.REVERSE);
			win.noutrefresh();
		}
	}

	private void generate_scrollbar(int offset=0, int x=0)
	{
		scrlwin.bkgdset(COLOR_PAIR(2)); //TODO color pair as a variable
		for(int i = 0; i < win.getmaxy(); i++){
			scrlwin.mvaddch(i, 0, ' ');
		}

		scrlwin.attrset(COLOR_PAIR(3));

		if (length() > 0) {
			int o = ((selected+offset)*100 / length()) * 100;
			o /= 10000 / (scrlwin.getmaxy() - 1);
			scrlwin.mvaddch(o, 0, BUD);
		}
		status.add_message_r(@"$(selected+offset)/$(length())", 2);
		status.show();
		scrlwin.noutrefresh();
	}

	private void get_config()
	{
		config = new KeyFile();
		var dir = File.new_for_path(Environment.get_home_dir() + "/.consul");
		try {
			if (!dir.query_exists())
				dir.make_directory();
		} catch (Error e) {
			error(@"Error making .consul: $(e.message)");
		}

		try {
			config.load_from_file(dir.get_path() + "/consul.cfg", KeyFileFlags.NONE);
		} catch (KeyFileError err) {
			error(@"KeyFileError: $(err.message)");
		} catch (FileError err) {
			//config.set_string("Consul", "", "");
			config.set_string("Filetypes", "smc", "zsnes");
			config.set_string("Filetypes", "gen", "gens");
			var str = config.to_data(null);
			try {
				FileUtils.set_contents (dir.get_path() + "/consul.cfg", str, str.length);
			} catch (FileError err) {
				error(@"FileError: $(err.message)");
			}
		}
	}

}

void error(string msg)
{
	refresh();
	def_prog_mode();
	endwin();
	
	stdout.printf("----------------------\n");
	stdout.printf("| An error occurred: |\n");
	stdout.printf("----------------------\n");
	stdout.flush();
	stderr.printf("%s\n\n", msg);
	stderr.flush();
	stdout.printf("Press ENTER to continue...\n");
	stdout.flush();
	getch();

	/*
	var win = new Window(10, 10, 2, 2);
	win.keypad(true);
	win.addstr(msg);
	refresh();
	win.getch();
	*/

	reset_prog_mode();
	refresh();
}
void curses_init() 
{
    initscr();
    noecho();
	start_color();
    init_pair(1, Color.WHITE, Color.BLACK);
	init_pair(2, Color.WHITE, Color.BLUE);
	init_pair(3, Color.WHITE, Color.RED);
	init_pair(4, Color.RED, Color.BLACK);
	init_pair(5, Color.BLACK, Color.WHITE);
	curs_set(0);

}

int main (string[] args)
{
		curses_init();	
		var dir = ".";
		if (args.length > 1) {
			dir = args[1];
		}
		var list = new Menu(LINES-1, COLS, 0, 0, dir, true);
    	list.win.bkgdset (COLOR_PAIR(1));  // set background
		list.win.scrollok(true);
		list.win.keypad(true);
		//list.generate();

	
		for (;;) {
			int c = list.win.getch();
			if(c == 'q') {
				endwin();
				break;
			}
			list.keypress(c);
		}

    return 0;
}

