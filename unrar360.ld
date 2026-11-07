/* Lays unrar360 out for xsdk's elf2xex --dll, as xsdk's src/xsdk.ld lays out a title: read-only, code and writable data
   each on their own 64 KB pages. */
OUTPUT_FORMAT("elf32-powerpc")
OUTPUT_ARCH(powerpc:common)
ENTRY(unrar360_entry)

SECTIONS
{
	/* Clear of the title (0x82000000) and the Silverlight runtime's modules, the last of which ends at 0x8B860000 and
	   the next starts at 0x942B0000 (the Plex 0.0.0.7 runtime's XEX headers). On a console, XexLoadImage refuses
	   0x8A000000, 0x8C000000 and 0x8E000000 in a Silverlight app's process (STATUS_CONFLICTING_ADDRESSES), and
	   Silverlight360.Https has 0x8D000000, so this is at 0x8F000000. The Makefile's elf2xex --base says the same. */
	. = 0x8F000000 + 0x1000;
	.rdata : {
		*(.rodata .rodata.* .gnu.linkonce.r.*)
		*(.sdata2 .sdata2.* .sbss2 .sbss2.*)
		*(.gcc_except_table .gcc_except_table.*)
	}
	/* runtime.c registers this with libgcc's unwinder; the zero word ends the list, as crtend.o would. */
	.eh_frame : {
		__eh_frame_start = .;
		KEEP(*(.eh_frame))
		LONG(0)
	}

	. = ALIGN(0x10000);
	.text : {
		*(.text.xsdk_thunk_*)
		*(.text .text.*)
	}

	. = ALIGN(0x10000);
	.preinit_array : {
		__preinit_array_start = .;
		KEEP(*(.preinit_array))
		__preinit_array_end = .;
	}
	.init_array : {
		__init_array_start = .;
		KEEP(*(SORT_BY_INIT_PRIORITY(.init_array.*)))
		KEEP(*(.init_array))
		__init_array_end = .;
	}
	.fini_array : {
		KEEP(*(SORT_BY_INIT_PRIORITY(.fini_array.*)))
		KEEP(*(.fini_array))
	}
	.data : {
		*(.data .data.* .gnu.linkonce.d.*)
		*(.sdata .sdata.*)
	}
	.bss : {
		*(.sbss .sbss.* .bss .bss.* COMMON)
	}

	.xsdk.imports 0 : {
		KEEP(*(.xsdk.imports))
	}
	.xsdk.exports 0 : {
		KEEP(*(.xsdk.exports))
	}

	/DISCARD/ : {
		*(.comment .note.* .gnu.attributes)
	}
}
