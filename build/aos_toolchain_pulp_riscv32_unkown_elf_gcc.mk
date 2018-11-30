GNU_ARCH_LIST := RI5CY \
                 ZERO_RISCY

ifneq ($(filter $(HOST_ARCH), $(GNU_ARCH_LIST)),)

TOOLCHAIN_PATH    ?=
TOOLCHAIN_PREFIX  := riscv32-unknown-elf-
TOOLCHAIN_DEFAULT_FOLDER := riscv32_unkown_elf_gcc7.1.1

ifneq (,$(wildcard $(COMPILER_ROOT)/$(TOOLCHAIN_DEFAULT_FOLDER)/$(HOST_OS)/bin))
TOOLCHAIN_PATH    := $(COMPILER_ROOT)/$(TOOLCHAIN_DEFAULT_FOLDER)/$(HOST_OS)/bin/
endif

BINS ?=

ifeq ($(HOST_OS),Win32)
################
# Windows settings
################

ifeq (,$(TOOLCHAIN_PATH))
SYSTEM_GCC_PATH = $(shell where $(TOOLCHAIN_PREFIX)gcc.exe)
ifneq (,$(findstring $(TOOLCHAIN_PREFIX)gcc.exe,$(SYSTEM_GCC_PATH)))
TOOLCHAIN_PATH :=
else
$(error can not find compiler toolchain, please download $(TOOLCHIAN_FILE) from $(DOWNLOAD_URL) and unzip to $(COMPILER_ROOT)/$(TOOLCHAIN_DEFAULT_FOLDER)/$(HOST_OS) folder)
endif
endif

GDB_KILL_OPENOCD   = shell $(TOOLS_ROOT)/cmd/win32/taskkill /F /IM st-util.exe
GDBINIT_STRING     = shell start /B $(TOOLS_ROOT)/cmd/win32/st-util.exe
GDB_COMMAND        = $(call CONV_SLASHES, $(TOOLCHAIN_PATH))$(TOOLCHAIN_PREFIX)gdb$(EXECUTABLE_SUFFIX)

else  # Win32
ifneq (,$(filter $(HOST_OS),Linux32 Linux64))
################
# Linux 32/64-bit settings
################

ifeq (,$(TOOLCHAIN_PATH))
SYSTEM_GCC_PATH = $(shell which $(TOOLCHAIN_PREFIX)gcc)
ifneq (,$(findstring $(TOOLCHAIN_PREFIX)gcc,$(SYSTEM_GCC_PATH)))
TOOLCHAIN_PATH :=
else
$(error can not find compiler toolchain, please download $(TOOLCHIAN_FILE) from $(DOWNLOAD_URL) and unzip to $(COMPILER_ROOT)/$(TOOLCHAIN_DEFAULT_FOLDER)/$(HOST_OS) folder)
endif
endif

else # Linux32/64
ifeq ($(HOST_OS),OSX)
################
# OSX settings
################

ifeq (,$(TOOLCHAIN_PATH))
SYSTEM_GCC_PATH = $(shell which $(TOOLCHAIN_PREFIX)gcc)
ifneq (,$(findstring $(TOOLCHAIN_PREFIX)gcc,$(SYSTEM_GCC_PATH)))
TOOLCHAIN_PATH :=
else
$(error can not find compiler toolchain, please download $(TOOLCHIAN_FILE) from $(DOWNLOAD_URL) and unzip to $(COMPILER_ROOT)/$(TOOLCHAIN_DEFAULT_FOLDER)/$(HOST_OS) folder)
endif
endif


else # OSX
$(error unsupport OS $(HOST_OS))
endif # OSX
endif # Linux32 Linux64 OSX
endif # Win32

# Notes on C++ options:
# The next two CXXFLAGS reduce the size of C++ code by removing unneeded
# features. For example, these flags reduced the size of a console app build
# (with C++ iperf) from 604716kB of flash to 577580kB of flash and 46756kB of
# RAM to 46680kB of RAM.
#
# -fno-rtti
# Disable generation of information about every class with virtual functions for
# use by the C++ runtime type identification features (dynamic_cast and typeid).
# Disabling RTTI eliminates several KB of support code from the C++ runtime
# library (assuming that you don't link with code that uses RTTI).
#
# -fno-exceptions
# Stop generating extra code needed to propagate exceptions, which can produce
# significant data size overhead. Disabling exception handling eliminates
# several KB of support code from the C++ runtime library (assuming that you
# don't link external code that uses exception handling).

CC      := "$(TOOLCHAIN_PATH)$(TOOLCHAIN_PREFIX)gcc$(EXECUTABLE_SUFFIX)"
CXX     := "$(TOOLCHAIN_PATH)$(TOOLCHAIN_PREFIX)g++$(EXECUTABLE_SUFFIX)"
AS      := $(CC)
AR      := "$(TOOLCHAIN_PATH)$(TOOLCHAIN_PREFIX)ar$(EXECUTABLE_SUFFIX)"
LD      := "$(TOOLCHAIN_PATH)$(TOOLCHAIN_PREFIX)ld$(EXECUTABLE_SUFFIX)"
CPP     := "$(TOOLCHAIN_PATH)$(TOOLCHAIN_PREFIX)cpp$(EXECUTABLE_SUFFIX)"
OBJDUMP := "$(TOOLCHAIN_PATH)$(TOOLCHAIN_PREFIX)objdump$(EXECUTABLE_SUFFIX)"
OBJCOPY := "$(TOOLCHAIN_PATH)$(TOOLCHAIN_PREFIX)objcopy$(EXECUTABLE_SUFFIX)"
STRIP   := "$(TOOLCHAIN_PATH)$(TOOLCHAIN_PREFIX)strip$(EXECUTABLE_SUFFIX)"
NM      := "$(TOOLCHAIN_PATH)$(TOOLCHAIN_PREFIX)nm$(EXECUTABLE_SUFFIX)"
READELF := "$(TOOLCHAIN_PATH)$(TOOLCHAIN_PREFIX)readelf$(EXECUTABLE_SUFFIX)"

ADD_COMPILER_SPECIFIC_STANDARD_CFLAGS   = $(1) -Wall -Wfatal-errors -fsigned-char -ffunction-sections -fdata-sections -fno-common -std=gnu11 $(if $(filter yes,$(MXCHIP_INTERNAL) $(TESTER)),-Werror)
ADD_COMPILER_SPECIFIC_STANDARD_CXXFLAGS = $(1) -Wall -Wfatal-errors -fsigned-char -ffunction-sections -fdata-sections -fno-common -fno-rtti -fno-exceptions  $(if $(filter yes,$(MXCHIP_INTERNAL) $(TESTER)),-Werror)
ADD_COMPILER_SPECIFIC_STANDARD_ADMFLAGS = $(1)
COMPILER_SPECIFIC_OPTIMIZED_CFLAGS    := -O2
COMPILER_SPECIFIC_UNOPTIMIZED_CFLAGS  := -O0
COMPILER_SPECIFIC_PEDANTIC_CFLAGS  := $(COMPILER_SPECIFIC_STANDARD_CFLAGS) -Werror -Wstrict-prototypes  -W -Wshadow  -Wwrite-strings -pedantic -std=c99 -U__STRICT_ANSI__ -Wconversion -Wextra -Wdeclaration-after-statement -Wconversion -Waddress -Wlogical-op -Wstrict-prototypes -Wold-style-definition -Wmissing-prototypes -Wmissing-declarations -Wmissing-field-initializers -Wdouble-promotion -Wswitch-enum -Wswitch-default -Wuninitialized -Wunknown-pragmas -Wfloat-equal  -Wundef  -Wshadow # -Wcast-qual -Wtraditional -Wtraditional-conversion
COMPILER_SPECIFIC_ARFLAGS_CREATE   := -rcs
COMPILER_SPECIFIC_ARFLAGS_ADD      := -rcs
COMPILER_SPECIFIC_ARFLAGS_VERBOSE  := -v

#debug: no optimize and log enable
COMPILER_SPECIFIC_DEBUG_CFLAGS     := -DDEBUG -ggdb $(COMPILER_SPECIFIC_UNOPTIMIZED_CFLAGS)
COMPILER_SPECIFIC_DEBUG_CXXFLAGS   := -DDEBUG -ggdb $(COMPILER_SPECIFIC_UNOPTIMIZED_CFLAGS)
COMPILER_SPECIFIC_DEBUG_ASFLAGS    := -DDEBUG=1 -ggdb
COMPILER_SPECIFIC_DEBUG_LDFLAGS    := -Wl,--gc-sections -Wl,--cref

#release_log: optimize but log enable
COMPILER_SPECIFIC_RELEASE_LOG_CFLAGS   := -ggdb $(COMPILER_SPECIFIC_OPTIMIZED_CFLAGS)
COMPILER_SPECIFIC_RELEASE_LOG_CXXFLAGS := -ggdb $(COMPILER_SPECIFIC_OPTIMIZED_CFLAGS)
COMPILER_SPECIFIC_RELEASE_LOG_ASFLAGS  := -ggdb
COMPILER_SPECIFIC_RELEASE_LOG_LDFLAGS  := -Wl,--gc-sections -Wl,$(COMPILER_SPECIFIC_OPTIMIZED_CFLAGS) -Wl,--cref

#release: optimize and log disable
COMPILER_SPECIFIC_RELEASE_CFLAGS   := -DNDEBUG -ggdb $(COMPILER_SPECIFIC_OPTIMIZED_CFLAGS)
COMPILER_SPECIFIC_RELEASE_CXXFLAGS := -DNDEBUG -ggdb $(COMPILER_SPECIFIC_OPTIMIZED_CFLAGS)
COMPILER_SPECIFIC_RELEASE_ASFLAGS  := -ggdb
COMPILER_SPECIFIC_RELEASE_LDFLAGS  := -Wl,--gc-sections -Wl,$(COMPILER_SPECIFIC_OPTIMIZED_CFLAGS) -Wl,--cref

COMPILER_SPECIFIC_DEPS_FLAG        := -MD
COMPILER_SPECIFIC_COMP_ONLY_FLAG   := -c
COMPILER_SPECIFIC_LINK_MAP         =  -Wl,-Map,$(1)
COMPILER_SPECIFIC_LINK_FILES       =  -Wl,--whole-archive -Wl,--start-group $(1) -Wl,--end-group -Wl,-no-whole-archive
COMPILER_SPECIFIC_LINK_SCRIPT_DEFINE_OPTION = -Wl$(COMMA)-T
COMPILER_SPECIFIC_LINK_SCRIPT      =  $(addprefix -Wl$(COMMA)-T ,$(1))
LINKER                             := $(CC) --static -Wl,-static -Wl,--warn-common
LINK_SCRIPT_SUFFIX                 := .ld
TOOLCHAIN_NAME := GCC
OPTIONS_IN_FILE_OPTION    := @

ENDIAN_CFLAGS_LITTLE   :=
ENDIAN_CXXFLAGS_LITTLE :=
ENDIAN_ASMFLAGS_LITTLE :=
ENDIAN_LDFLAGS_LITTLE  :=
CLIB_LDFLAGS_NANO      :=
CLIB_LDFLAGS_NANO_FLOAT:=

# Chip specific flags for GCC

ifeq ($(HOST_ARCH),RI5CY)
CPU_CFLAGS     := -march=rv32imcxpulpv2 -g
CPU_CXXFLAGS   := -march=rv32imcxpulpv2 -g
CPU_ASMFLAGS   := $(CPU_CFLAGS) 
CPU_LDFLAGS    := -march=rv32imcxpulpv2 -g
else ifeq ($(BINS), ZERO_RISCY)
CPU_CFLAGS     := -march=rv32imc -g
CPU_CXXFLAGS   := -march=rv32imc -g
CPU_ASMFLAGS   := $(CPU_CFLAGS)
CPU_LDFLAGS    := -march=rv32imc -g
endif

# $(1) is map file, $(2) is CSV output file
COMPILER_SPECIFIC_MAPFILE_TO_CSV = $(PYTHON) $(MAPFILE_PARSER) $(1) > $(2)

MAPFILE_PARSER            :=$(MAKEFILES_PATH)/scripts/map_parse_gcc.py

# $(1) is map file, $(2) is CSV output file
COMPILER_SPECIFIC_MAPFILE_DISPLAY_SUMMARY = $(PYTHON) $(MAPFILE_PARSER) $(1)

KILL_OPENOCD_SCRIPT := $(MAKEFILES_PATH)/scripts/kill_openocd.py

KILL_OPENOCD = $(PYTHON) $(KILL_OPENOCD_SCRIPT)

STRIP_OUTPUT_PREFIX := -o
OBJCOPY_BIN_FLAGS   := -O binary -R .eh_frame -R .init -R .fini -R .comment -R .ARM.attributes
OBJCOPY_HEX_FLAGS   := -O ihex -R .eh_frame -R .init -R .fini -R .comment -R .ARM.attributes

LINK_OUTPUT_SUFFIX :=.elf
BIN_OUTPUT_SUFFIX  :=.bin
HEX_OUTPUT_SUFFIX  :=.hex

endif
