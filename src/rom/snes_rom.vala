public class SNESROM : ROM {
    private RomOffset header;

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
        LOROM = 0x007fc0,
        HIROM = 0x00ffc0,
        EXROM = 0x40ffc0,
    }

    public SNESROM(string fn) throws DataError {
        console = "SNES";
        application = "bsnes"; // STUB

        load_file(fn);
        if (!is_valid()) {
            throw new DataError.INVALID("invalid data for ROM type '%s'",
            console);
        }

        header = find_header_offset();
        name = find_field(header + HeaderField.CARTNAME, 0x15);
    }

    protected override uint detect_offset() {
        if (size % 1024 == 512 && size - 0x200 > 0) {
            return 0x200;
        }

        return 0;
    }

    protected override bool is_valid() {
        uint8[] a, b;

        if (data.length >= 0x10) {
            a = data[0x00:0x10];
            b = {0x78, 0x9C, 0x00, 0x42, 0x9C, 0x0C, 0x42, 0x9C};
            return is_equal_data(a, b);
        }

        return false;
    }
    
    private RomOffset find_header_offset() {
        uint score_lo = score_header(RomOffset.LOROM);
        uint score_hi = score_header(RomOffset.HIROM);
        uint score_ex = score_header(RomOffset.EXROM);
        if (score_ex > 0) {
            score_ex += 4;  //favor ExHiROM on images > 32mbits
        }

        if (score_lo >= score_hi && score_lo >= score_ex) {
          return RomOffset.LOROM;
        } else if (score_hi >= score_ex) {
          return RomOffset.HIROM;
        } else {
          return RomOffset.EXROM;
        }
    }

    private uint score_header(uint addr) {
        if (size < addr + 64) {
            return 0;  //image too small to contain header at this location?
        }
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
        if((checksum + complement) == 0xffff && (checksum != 0) && (complement != 0)) {
            score += 4;
        }

        if(addr == 0x007fc0 && mapper == 0x20) score += 2;  //0x20 is usually LoROM
        if(addr == 0x00ffc0 && mapper == 0x21) score += 2;  //0x21 is usually HiROM
        if(addr == 0x007fc0 && mapper == 0x22) score += 2;  //0x22 is usually ExLoROM
        if(addr == 0x40ffc0 && mapper == 0x25) score += 2;  //0x25 is usually ExHiROM

        if(data[addr + HeaderField.COMPANY] == 0x33) score += 2; //0x33 indicates extended header
        if(data[addr + HeaderField.ROMTYPE] < 0x08) ++score;
        if(data[addr + HeaderField.ROMSIZE] < 0x10) ++score;
        if(data[addr + HeaderField.RAMSIZE] < 0x08) ++score;
        if(data[addr + HeaderField.CARTREGION] < 14) ++score;

        if(score < 0) score = 0;
        return score;
    }

    public override string to_string() {
        string output = "Super Famicon/Nintendo ROM\n";
        output += @"Header offset: $header\n";
        output += @"Game name: $name\n";
        //output += @"Cartridge region: $region\n";
        return output;
    }
    
}
