VGMPlay MSX
===========

Copyright 2015 Laurens Holst

Thanks go to l_oliveira, popolon(fr), Pencioner and JunSoft for support.

Project information
-------------------

Plays back VGM music files on MSX with the supported sound chips.

Author: Laurens Holst <laurens.nospam@grauw.nl>  
Site: <https://bitbucket.org/grauw/vgmplay-msx>  
Downloads: <https://bitbucket.org/grauw/vgmplay-msx/downloads>  
History: <https://bitbucket.org/grauw/vgmplay-msx/src/default/CHANGES.md>  
Issues: <https://bitbucket.org/grauw/vgmplay-msx/issues>  
Support: <http://www.msx.org/forum/msx-talk/software/vgmplay-msx>  
License: Simplified BSD License

VGMPlay can play back music for quite a number of sound chips using various
common and less common sound expansions for MSX, such as the PSG, MoonSound and
Yamaha SFG. A detailed list can be found below.

Both the VGM and VGZ formats are supported. The compressed VGZ format takes
longer to load but also consumes less disk space. If so desired, VGZ files can
be manually decompressed to VGM with
[gunzip for MSX](https://bitbucket.org/grauw/gunzip) or PC.

The timing resolution is 50 or 60 Hz on MSX1 machines with a TMS9918 VDP, 300 Hz
on machines with a V9938 or V9958 VDP, and 4000 Hz on MSX turboR.

For more information on the VGM format see:  
<http://www.smspower.org/Music/VGMFileFormat>

For collections of VGM music see:  
<http://vgmrips.net/>  
<http://www.smspower.org/Music/VGMs>  
<http://opl.wafflenet.com/>


System Requirements
-------------------

  * MSX, MSX2, MSX2+ or MSX turboR
  * 128K main RAM
  * 16K video RAM
  * MSX-DOS 2


Supported sound chips
---------------------

  * AY-3-8910 PSG / YM2149 SSG x2
    * Internal PSG, Darky, MegaFlashROM SCC+
  * YM2151 OPM x2
    * Yamaha SFG
  * YM2413 OPLL
    * MSX-MUSIC, FM-PAC
  * YM3526 OPL x2
    * MSX-AUDIO, Music Module, MoonSound, OPL3
  * YM3812 OPL2 x2
    * MoonSound, OPL3
  * YMF262 OPL3 x2
    * MoonSound, OPL3
  * YMF278B OPL4
    * MoonSound, DalSoRi R2 (4MB mode)
  * Y8950 MSX-AUDIO x2
    * MSX-AUDIO, Music Module, MoonSound (no ADPCM), OPL3 (no ADPCM)
  * K051649 Konami SCC
    * Konami SCC, Konami Sound Cartridge
  * K052539 Konami SCC+
    * Konami Sound Cartridge
  * SN76489 DCSG x2
    * Musical Memory Mapper, Playsoniq, Franky, PSG
  * YM2203 OPN x2
    * OPNA, Neotron, Yamaha SFG + PSG
  * YM2608 OPNA
    * OPNA, Yamaha SFG + PSG + MSX-AUDIO (no drums)
  * YM2610 OPNB
    * Neotron, Yamaha SFG + PSG (no ADPCM)
  * YM2610B OPNB-B
    * Neotron + OPNA
  * YM2612 OPN2 x2
    * OPNA + turboR PCM, Yamaha SFG + turboR PCM


Usage instructions
------------------

Run VGMPlay from MSX-DOS 2, specifying the VGM file to play on the command line.

Usage:

    vgmplay [options] <file.vgm>

The compressed VGZ format is also supported.

Options:

  * `/l` Number of playback loops. Default: 2.
    
    Many VGM music loops once the end of the song is reached. With this setting
    you can specify how many times VGMPlay should play the repeating part before
    exiting. The amount is specified like `/L15`. Use `/L` or `/L0` to loop
    infinitely. This setting will have no effect for songs which don’t loop.
    
  * `/b` Enter blackout mode during playback.
    
    This setting makes the screen go black during playback. For machines with a
    lot of VDP interference on the audio output, this may reduce the amount of
    interference.

To configure Multi Mente to play VGM files, add the following lines to
MMRET.DAT:

    .VGM    VGMPLAY $T
    .VGZ    VGMPLAY $T


Development information
-----------------------

VGMPlay is free and open source software. If you want to contribute to the
project you are very welcome to. Please contact me at any one of the places
mentioned in the project information section.

You are also free to re-use code for your own projects, provided you abide by
the license terms.

VGMPlay depends on the library projects Neonlib and Gunzip; it is recommended
to clone the project with Mercurial so they will automatically be pulled in
at the correct version, otherwise you have to download them manually:

    hg clone https://bitbucket.org/grauw/vgmplay-msx

Building the project is really easy on all modern desktop platforms. On MacOS
and Linux, simply invoke `make` to build the binary and symbol files into the
`bin` directory:

    make

Windows users can open the `Makefile` and build by pasting the line in the `all`
target into the Windows command prompt.

To launch the build in openMSX after building, put a copy of `MSXDOS2.SYS` and
`COMMAND2.COM` and some VGM files to test with in the `bin` directory, and then
invoke the `make run` command.

Note that the [glass](https://bitbucket.org/grauw/glass) assembler which is
embedded in the project requires [Java 8](http://java.com/getjava). To check
your Java version, invoke the `java -version` command.
