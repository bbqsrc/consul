public class GBAROM : ROM {
    public string code { get; protected set; }
    
    enum HeaderField {
        JUMP       = 0x00,
        LOGO       = 0x04,
        GAMENAME   = 0xA0,
        GAMECODE   = 0xAC,
        MAKERCODE  = 0xB0,
        COMPLEMENT = 0xBD,
    }

    public GBAROM(string fn) throws DataError {
        console = "GBA";
        application = "mednafen"; // STUB
        
        load_file(fn);
        if (!is_valid()) {
            throw new DataError.INVALID("invalid data for ROM type '%s'",
            console);
        }

        name = find_field(HeaderField.GAMENAME, 0x0C);
        code = find_field(HeaderField.GAMECODE, 0x04);
    }
    
    protected override uint detect_offset() {
        return 0;
    }

    protected override bool is_valid() {
        uint8[] a, b;
        
        if (data.length >= 0x08) {
            a = data[0x04:0x08];
            b = {0x24, 0xFF, 0xAE, 0x51};
            return is_equal_data(a, b);
        }

        return false;
    }

    public override string to_string() {
        string output = "Game Boy Advance ROM\n";
        output += @"Name: $name\n";
        output += @"Code: $code\n";
        return output;
    }
    
}
