public errordomain DataError {
    INVALID
}

public abstract class ROM : Object {
    public string console { get; protected set; }
    public uint size { get; protected set; }
    public uint8[] data { get; protected set; }
    public string name { get; protected set; } 
    public string application { get; protected set; } 
    
    protected abstract bool is_valid();
    protected abstract uint detect_offset();
    public abstract string to_string();

    protected void load_file(string fn) throws DataError {
        try {
            var file = File.new_for_path(fn);
            var f = file.query_info("*", FileQueryInfoFlags.NONE);
		    if (f.get_file_type() == FileType.DIRECTORY) {
                throw new DataError.INVALID("File is a directory");
            }
            
            var file_stream = file.read();
            var data_stream = new DataInputStream(file_stream);
            data_stream.set_byte_order(DataStreamByteOrder.LITTLE_ENDIAN);
            
            this.size = (uint) f.get_size();
            uint offset = detect_offset();
        
            this.data = new uint8[size - offset];
            file_stream.seek(offset, SeekType.CUR);
            data_stream.read(data);
        } catch (Error e) {
            stderr.printf("%s\n", e.message);
        }
    }
    
    protected string find_field(uint field, uint size) {
        uint8[] buf = data[field:field+size];
        return ((string)buf)[0:size];
    } 
}

ROM? load_rom(string fn) {
    try {
        return new GBAROM(fn);
    } catch (Error e) {}
    
    try {
        return new GenesisROM(fn);
    } catch (Error e) {}
    
    try {
        return new SNESROM(fn);
    } catch (Error e) {}
    
    return null;
}

bool is_equal_data(uint8[] a, uint8[] b) {
    for (int i = 0; i < b.length; ++i) {
        if (a[i] != b[i]) {
            return false;
        }
    }
    return true;
}

