RomData? get_rom(string r)
{
	try {
		var file = File.new_for_path(r);
		var f = file.query_info("*", FileQueryInfoFlags.NONE);
		if (f.get_file_type() == FileType.DIRECTORY)
			return null;
		return new RomData(file, 0x200);
	}
	catch(Error e) {
		return null;
	}
}	

string get_rom_data(RomData rom)
{
	switch(rom.console) {
		case Console.SNES:
			return Snes.get_rom_data(rom);
		case Console.GENESIS:
			return Genesis.get_rom_data(rom);
		case Console.GBA:
			return Gba.get_rom_data(rom);
		case Console.UNKNOWN:
		default:
			return "Unknown console.\n";
	}
}

string? get_rom_app(RomData rom)
{
	switch(rom.console) {
		case Console.SNES:
			return Snes.get_rom_app();
		case Console.GENESIS:
			return Genesis.get_rom_app();
		case Console.GBA:
			return Gba.get_rom_app();
		case Console.UNKNOWN:
		default:
			return null;
	}
}

enum Console {
	UNKNOWN,
	SNES,
	GENESIS,
	GBA,
}

class RomData : GLib.Object {
	public uint size { get; private set; }
	public bool header { get; private set; }
	public uint8[] data { get; private set; }
	public uint console { get; private set; }

	public RomData(File f, uint o)
	{
		try {
			var file_stream = f.read();
			var data_stream = new DataInputStream(file_stream);
			data_stream.set_byte_order(DataStreamByteOrder.LITTLE_ENDIAN);
			
			var file_info = f.query_info("*", FileQueryInfoFlags.NONE);
			this.size = (uint)file_info.get_size();
			
			uint offset = 0;
			if(headered() && (size - o > 0)) {
				header = true;
				offset = o;
			}
			else {
				header = false;
				offset = 0;
			}

			this.data = new uint8[size - offset];
			file_stream.seek(offset, SeekType.CUR);
			data_stream.read(data);
			
			this.console = detect_console();
		}

		catch (Error e) {
			error(e.message);
		}
		
	}
	
	private uint detect_console()
	{
		uint8[] a, b;
		if(data.length >= 0x08) {
			a = data[0x04:0x08];
			b = {0x24, 0xFF, 0xAE, 0x51};
			if(compare_intarray(a, b))
				return Console.GBA;
		}

		if(data.length >= 0x10) {
			a = data[0x00:0x10];
			b = {0x78, 0x9C, 0x00, 0x42, 0x9C, 0x0C, 0x42, 0x9C};
			if(compare_intarray(a, b))
				return Console.SNES;
		}
		
		if(data.length >= 0x108) {
			a = data[0x100:0x108];
			b = {0x53, 0x45, 0x47, 0x41};
			if(compare_intarray(a, b))
				return Console.GENESIS;
		}

		return Console.UNKNOWN;
	}

	private bool compare_intarray(uint8[] a, uint8[] b)
	{
		bool ret = true;
		for(int i = 0; i < b.length; ++i) {
			if(a[i] != b[i]) {
				ret = false;
				break;
			}
		}
		return ret;
	}

	private bool headered()
	{
		int64 res = this.size % 1024;
		if(res == 512)
			return true;
		return false;
	}
}

namespace Gba {
	enum HeaderField {
		JUMP		= 0x00,
		LOGO		= 0x04,
		GAMENAME	= 0xA0,
		GAMECODE	= 0xAC,
		MAKERCODE	= 0xB0,
		COMPLEMENT	= 0xBD,
	}

	string get_rom_data(RomData rom)
	{
		uint header = 0x00;
	
		string name = get_name(rom.data, header);
		string gamecode = get_gamecode(rom.data, header);

		string output = "Game Boy Advance Rom\n";
		output += @"Name: $name\n";
		output += @"Code: $gamecode\n";
		return output;
	}

	string get_rom_app()
	{
		return "mednafen"; //stub
	}

	string get_name(uint8[] data, uint offset)
	{
		uint header = offset + HeaderField.GAMENAME;
		uint8[] buff = data[header:header+0x0C];
		string output = ((string)buff)[0:0x0C];
		return output;
	}	
	
	string get_gamecode(uint8[] data, uint offset)
	{
		uint header = offset + HeaderField.GAMECODE;
		uint8[] buff = data[header:header+0x04];
		string output = ((string)buff)[0:0x04];
		return output;
	}	
}

namespace Genesis {
	enum HeaderField {
		CONSOLE		= 0x00,
		COPYRIGHT	= 0x10,
		NAME_DOMESTIC = 0x20,
		NAME_OVERSEAS = 0x50,
		TYPE		= 0x80, // GM = game, Al = education
		PRODUCT_CODE = 0x82,
		COMPLEMENT	= 0x8E,
		IOSUPPORT	= 0x90,
		STARTADDR	= 0xA0,
		ENDADDR		= 0xA4,
		CARTREGION  = 0xF0,
	}

	//int check(RomData rom)
	string get_rom_data(RomData rom)
	{
		uint header = 0x100;
		string console = get_console(rom.data, header);
		string name = get_name_domestic(rom.data, header);
		string osname = get_name_overseas(rom.data, header);
		string region = get_region(rom.data, header);

		string output = "Sega Genesis/Mega Drive Rom\n";
		output += @"Console: $console\n";
		output += @"Domestic name: $name\n";
		output += @"Overseas name: $osname\n";
		output += @"Cartridge region: $region\n";
		return output;
	}
	
	string get_rom_app()
	{
		return "gens"; //stub
	}

	string get_console(uint8[] data, uint offset)
	{
		uint8[] buff = data[offset:offset+0x10];
		string output = ((string)buff)[0:0x10];
		return output;
	}

	string get_name_domestic(uint8[] data, uint offset)
	{
		uint header = offset + HeaderField.NAME_DOMESTIC;
		uint8[] buff = data[header:header+0x30];
		string output = ((string)buff)[0:0x30];
		return output;
	}	
	
	string get_name_overseas(uint8[] data, uint offset)
	{
		uint header = offset + HeaderField.NAME_OVERSEAS;
		uint8[] buff = data[header:header+0x30];
		string output = ((string)buff)[0:0x30];
		return output;
	}	

	string get_region(uint8[] data, uint offset)
	{
		uint header = offset + HeaderField.CARTREGION;
		uint8[] buff = data[header:header+0x03];
		string output = ((string)buff)[0:0x03];
		return output;
	}
}	

namespace Snes {
	enum HeaderField {
		CARTNAME    = 0x00,
		MAPPER      = 0x15,
		ROMTYPE     = 0x16,
		ROMSIZE     = 0x17,
		RAMSIZE     = 0x18,
		CARTREGION  = 0x19,
		COMPANY     = 0x1a,
		VERSION     = 0x1b,
		COMPLEMENT  = 0x1c,  //inverse checksum
		CHECKSUM    = 0x1e,
		RESETVECTOR = 0x3c,
	}

	enum RomOffset {
		LOROM	= 0x007fc0,
		HIROM	= 0x00ffc0,
		EXROM	= 0x40ffc0,
	}

	string get_rom_data(RomData rom) 
	{
		uint header = find_header(rom.data, rom.size);// - offset);
		string name = get_name(rom.data, header);
			
		string output = "Super Famicon/Nintendo Rom\n";
		output += @"Header offset: $header\n";
		output += @"Game name: $name\n";
		//output += @"Cartridge region: $region\n";
		return output;
	}
	
	string get_rom_app()
	{
		return "zsnes"; //stub
	}

	string get_name(uint8[] data, uint header)
	{
		uint8[] buff = data[header:header+21];
		string output = ((string)buff)[0:0x15];
		return output;
	}	

	uint find_header(uint8[] data, uint size) {
		uint score_lo = score_header(data, size, RomOffset.LOROM);
		uint score_hi = score_header(data, size, RomOffset.HIROM);
		uint score_ex = score_header(data, size, RomOffset.EXROM);
		if(score_ex > 0) score_ex += 4;  //favor ExHiROM on images > 32mbits
	
		if(score_lo >= score_hi && score_lo >= score_ex) {
		  return RomOffset.LOROM;
		} else if(score_hi >= score_ex) {
		  return RomOffset.HIROM;
		} else {
		  return RomOffset.EXROM;
		}
	}
	
	uint score_header(uint8[] data, uint size, uint addr) {
		if(size < addr + 64) return 0;  //image too small to contain header at this location?
		int score = 0;
	
		uint16 resetvector = data[addr + HeaderField.RESETVECTOR] | (data[addr + HeaderField.RESETVECTOR + 1] << 8);
		uint16 checksum    = data[addr + HeaderField.CHECKSUM   ] | (data[addr + HeaderField.CHECKSUM    + 1] << 8);
		uint16 complement  = data[addr + HeaderField.COMPLEMENT ] | (data[addr + HeaderField.COMPLEMENT  + 1] << 8);
	
		uint8 resetop = data[(addr & ~0x7fff) | (resetvector & 0x7fff)];  //first opcode executed upon reset
		uint8 mapper  = data[addr + HeaderField.MAPPER] & ~0x10;                      //mask off irrelevent FastROM-capable bit
	
		//$00:[000-7fff] contains uninitialized RAM and MMIO.
		//reset vector must point to ROM at $00:[8000-ffff] to be considered valid.
		if(resetvector < 0x8000) return 0;
	
		//some images duplicate the header in multiple locations, and others have completely
		//invalid header information that cannot be relied upon.
		//below code will analyze the first opcode executed at the specified reset vector to
		//determine the probability that this is the correct header.
	
		//most likely opcodes
		if(resetop == 0x78  //sei
		|| resetop == 0x18  //clc (clc; xce)
		|| resetop == 0x38  //sec (sec; xce)
		|| resetop == 0x9c  //stz $nnnn (stz $4200)
		|| resetop == 0x4c  //jmp $nnnn
		|| resetop == 0x5c  //jml $nnnnnn
		) score += 8;
	
		//plausible opcodes
		if(resetop == 0xc2  //rep #$nn
		|| resetop == 0xe2  //sep #$nn
		|| resetop == 0xad  //lda $nnnn
		|| resetop == 0xae  //ldx $nnnn
		|| resetop == 0xac  //ldy $nnnn
		|| resetop == 0xaf  //lda $nnnnnn
		|| resetop == 0xa9  //lda #$nn
		|| resetop == 0xa2  //ldx #$nn
		|| resetop == 0xa0  //ldy #$nn
		|| resetop == 0x20  //jsr $nnnn
		|| resetop == 0x22  //jsl $nnnnnn
		) score += 4;
	
		//implausible opcodes
		if(resetop == 0x40  //rti
		|| resetop == 0x60  //rts
		|| resetop == 0x6b  //rtl
		|| resetop == 0xcd  //cmp $nnnn
		|| resetop == 0xec  //cpx $nnnn
		|| resetop == 0xcc  //cpy $nnnn
		) score -= 4;
	
		//least likely opcodes
		if(resetop == 0x00  //brk #$nn
		|| resetop == 0x02  //cop #$nn
		|| resetop == 0xdb  //stp
		|| resetop == 0x42  //wdm
		|| resetop == 0xff  //sbc $nnnnnn,x
		) score -= 8;
	
		//at times, both the header and reset vector's first opcode will match ...
		//fallback and rely on info validity in these cases to determine more likely header.
	
		//a valid checksum is the biggest indicator of a valid header.
		if((checksum + complement) == 0xffff && (checksum != 0) && (complement != 0)) score += 4;
	
		if(addr == 0x007fc0 && mapper == 0x20) score += 2;  //0x20 is usually LoROM
		if(addr == 0x00ffc0 && mapper == 0x21) score += 2;  //0x21 is usually HiROM
		if(addr == 0x007fc0 && mapper == 0x22) score += 2;  //0x22 is usually ExLoROM
		if(addr == 0x40ffc0 && mapper == 0x25) score += 2;  //0x25 is usually ExHiROM
	
		if(data[addr + HeaderField.COMPANY] == 0x33) score += 2;        //0x33 indicates extended header
		if(data[addr + HeaderField.ROMTYPE] < 0x08) score++;
		if(data[addr + HeaderField.ROMSIZE] < 0x10) score++;
		if(data[addr + HeaderField.RAMSIZE] < 0x08) score++;
		if(data[addr + HeaderField.CARTREGION] < 14) score++;
	
		if(score < 0) score = 0;
		return score;
	}
}
