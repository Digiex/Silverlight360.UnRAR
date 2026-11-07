# Builds unrar360.xex, UnRAR's library in an Xbox 360 DLL, with xsdk's toolchain. In WSL: make
# XSDK is an xsdk checkout with elf2xex --dll and a built libxsdk.a, the dll-modules build XboxNGen uses, and
# TOOLCHAIN its compiler's prefix: tools/Configure.ps1 finds or sets them up and writes them to config.mk. It also
# fetches UnRAR's source into third_party/unrar.
-include config.mk
XSDK ?= $(HOME)/xsdk
TOOLCHAIN ?= $(HOME)/xsdk-gcc/bin/powerpc-xsdk-elf-
ELF2XEX ?= $(XSDK)/tools/elf2xex.py
CC := $(TOOLCHAIN)gcc
CXX := $(TOOLCHAIN)g++
BUILD := build
UNRAR := third_party/unrar
BASE := 8F000000

# UnRAR's makefile, its "lib" target's objects, with its own threads (RAR_SMP) left out.
UNRAR_NAMES := rar strlist strfn pathfn smallfn global file filefn filcreat archive arcread unicode system crypt crc \
	rawread encname resource match timefn rdwrfn consio options errhnd rarvm secpassword rijndael getbits sha1 sha256 \
	blake2s hash extinfo extract volume list find unpack headers threadpool rs16 cmddata ui largepage filestr scantree \
	dll qopen
UNRAR_OBJECTS := $(UNRAR_NAMES:%=$(BUILD)/unrar/%.o)
OBJECTS := $(BUILD)/runtime.o $(BUILD)/extract.o $(BUILD)/posix.o $(UNRAR_OBJECTS)

TARGET_FLAGS := -mcpu=cell -fno-pic -O2 -g
CFLAGS := $(TARGET_FLAGS) -std=gnu17 -Wall -Wextra -Werror -I$(XSDK)/include
UNRAR_DEFINES := -DRARDLL -D_UNIX -DBIG_ENDIAN -D_FILE_OFFSET_BITS=64
CXXFLAGS := $(TARGET_FLAGS) -std=c++17 $(UNRAR_DEFINES) -I$(XSDK)/include -I$(UNRAR)
UNRAR_CXXFLAGS := $(CXXFLAGS) -w -include src/compat.h
LIBS := -Wl,--start-group -lstdc++ $(XSDK)/build/libxsdk.a -lc -lm -lgcc -Wl,--end-group

all: unrar360.xex

unrar360.xex: $(BUILD)/unrar360.elf
	@grep -q -e '--dll' $(ELF2XEX) || { echo "$(ELF2XEX) has no --dll: use xsdk's dll-modules build" \
		"(https://github.com/jessenic/xsdk), which tools/Configure.ps1 finds or clones."; exit 1; }
	python3 $(ELF2XEX) --dll --base $(BASE) $< $@

$(BUILD)/unrar360.elf: $(OBJECTS) unrar360.ld
	$(CXX) -static -nostdlib -T unrar360.ld -Wl,-Map,$(BUILD)/unrar360.map -o $@ $(OBJECTS) $(LIBS)

$(BUILD)/%.o: src/%.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/%.o: src/%.cpp | $(UNRAR)/dll.hpp $(BUILD)
	$(CXX) $(CXXFLAGS) -Wall -Wextra -c $< -o $@

$(BUILD)/unrar/%.o: $(UNRAR)/%.cpp | $(BUILD)
	$(CXX) $(UNRAR_CXXFLAGS) -c $< -o $@

$(UNRAR)/dll.hpp:
	@echo "UnRAR's source isn't in $(UNRAR): run tools/Configure.ps1, which fetches it."; exit 1

$(BUILD):
	mkdir -p $(BUILD)/unrar

clean:
	rm -rf $(BUILD) unrar360.xex

.PHONY: all clean
