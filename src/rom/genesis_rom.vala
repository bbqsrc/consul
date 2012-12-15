public class GenesisROM : ROM {
    const uint HEADER = 0x100;
    public string console_name { get; protected set; }
    public string osname { get; protected set; }
    public string region { get; protected set; }

    enum HeaderField {
        CONSOLE       = 0x00,
        COPYRIGHT     = 0x10,
        NAME_DOMESTIC = 0x20,
        NAME_OVERSEAS = 0x50,
        TYPE          = 0x80, // GM = game, Al = education
        PRODUCT_CODE  = 0x82,
        COMPLEMENT    = 0x8E,
        IOSUPPORT     = 0x90,
        STARTADDR     = 0xA0,
        ENDADDR       = 0xA4,
        CARTREGION    = 0xF0,
    }

    public GenesisROM(string fn) throws DataError {
        console = "Genesis";
        application = "gens"; // STUB

        load_file(fn);
        if (!is_valid()) {
            throw new DataError.INVALID("invalid data for ROM type '%s'",
            console);
        }

        name = find_field(HEADER + HeaderField.NAME_DOMESTIC, 0x30);
        console_name = find_field(HEADER + HeaderField.CONSOLE, 0x10);
        osname = find_field(HEADER + HeaderField.NAME_OVERSEAS, 0x30);
        region = find_field(HEADER + HeaderField.CARTREGION, 0x03);
    }
    
    protected override uint detect_offset() {
        return 0;
    }

    protected override bool is_valid() {
        uint8[] a, b;

        if (data.length >= 0x108) {
            a = data[0x100:0x108];
            b = {0x53, 0x45, 0x47, 0x41};
            return is_equal_data(a, b);
        }

        return false;
    }
    
    public override string to_string() { 

        string output = "Sega Genesis/Mega Drive ROM\n";
        output += @"Console: $console_name\n";
        output += @"Domestic name: $name\n";
        output += @"Overseas name: $osname\n";
        output += @"Cartridge region: $region\n";
        return output;
    }
}
