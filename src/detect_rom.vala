int main(string[] args) {
    if (args.length == 1) {
        stdout.printf("%s: <filename>\n", args[0]);
        return 0;
    }

    var rom = load_rom(args[1]);
    if (rom == null) {
        stderr.printf("Unknown ROM type or not a ROM.\n");
        return 1;
    }
    
    stdout.printf(rom.to_string());
    return 0;
}
