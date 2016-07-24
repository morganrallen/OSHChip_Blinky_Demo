DEVICE := NRF51
DEVICESERIES := nrf51
TARGET_CHIP := NRF51822_QFAA_CA
BOARD	:= BOARD_CUSTOM
OUTPUT_FILENAME = $(shell basename "$(realpath ../)")
DEVICE_VARIANT := common

GNU_INSTALL_ROOT := /usr
GNU_VERSION := 4.9.3
GNU_PREFIX := arm-none-eabi

NRF_SDK_PATH ?= /vagrant/devel/nRF5_SDK_11/
SDK_INCLUDE_PATH = $(NRF_SDK_PATH)
SDK_SOURCE_PATH = $(NRF_SDK_PATH)

ifeq ($(USE_SOFTDEVICE),s110)
	USE_BLE = 1
	SOFTDEVICE = $(wildcard $(SOC_PATH)/$(USE_SOFTDEVICE)_*.hex)
endif
ifeq ($(USE_SOFTDEVICE),s120)
	SOFTDEVICE = $(wildcard $(SOC_PATH)/$(USE_SOFTDEVICE)_*.hex)
	USE_BLE = 1
endif

ifeq ($(LINKER_SCRIPT),)
	ifeq ($(USE_SOFTDEVICE), s110)
		LINKER_SCRIPT = gcc_$(DEVICESERIES)_s110_$(DEVICE_VARIANT).ld
		OUTPUT_FILENAME := $(OUTPUT_FILENAME)_s110_$(DEVICE_VARIANT)
	else
		ifeq ($(USE_SOFTDEVICE), s120)
			LINKER_SCRIPT = gcc_$(DEVICESERIES)_s120_$(DEVICE_VARIANT).ld
			OUTPUT_FILENAME := $(OUTPUT_FILENAME)_s120_$(DEVICE_VARIANT)
		else
			LINKER_SCRIPT = nrf51_no_softdevice.ld
			OUTPUT_FILENAME := $(OUTPUT_FILENAME)_$(DEVICE_VARIANT)
		endif
	endif
else
# Use externally defined settings
endif

# which arch do you use
CPU := cortex-m0

# Toolchain commands
CC       := $(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-gcc
GDB       := $(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-gdb
AS       := $(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-as
AR       := $(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-ar -r
LD       := $(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-ld
NM       := $(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-nm
OBJDUMP  := $(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-objdump
OBJCOPY  := $(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-objcopy

MK       := mkdir
RM       := rm -rf

OBJECT_DIRECTORY := _build
LISTING_DIRECTORY := _build
OUTPUT_BINARY_DIRECTORY := _build

# build bare-bone bootloader
C_SOURCE_FILES += system_$(DEVICESERIES).c
C_SOURCE_FILES += nrf_delay.c
C_SOURCE_FILES += src/main.c
ASSEMBLER_SOURCE_FILES += gcc_startup_$(DEVICESERIES).s

# Linker flags
LDFLAGS += -L"$(NRF_SDK_PATH)components/toolchain/gcc/"
LDFLAGS += -L"$(GNU_INSTALL_ROOT)arm-none-eabi/lib/armv6-m"
LDFLAGS += -L"$(GNU_INSTALL_ROOT)lib/gcc/arm-none-eabi/$(GNU_VERSION)/armv6-m"
LDFLAGS += -Xlinker -Map=$(LISTING_DIRECTORY)/$(OUTPUT_FILENAME).map
LDFLAGS += -mcpu=$(CPU) -mthumb -mabi=aapcs -T$(LINKER_SCRIPT)

# Compiler flags (remove -Werror)
CFLAGS += -mcpu=$(CPU) -mthumb -mabi=aapcs -D$(DEVICE) -D$(BOARD) -D$(TARGET_CHIP) --std=gnu99
CFLAGS += -Wall
CFLAGS += -mfloat-abi=soft
ifdef USE_BLE
CFLAGS += -DBLE_STACK_SUPPORT_REQD
endif

# Assembler flags
ASMFLAGS += -x assembler-with-cpp

INCLUDEPATHS += -I"$(SDK_INCLUDE_PATH)components/drivers_nrf/delay"
INCLUDEPATHS += -I"$(SDK_INCLUDE_PATH)components/drivers_nrf/hal"
INCLUDEPATHS += -I"$(SDK_INCLUDE_PATH)components/device"
INCLUDEPATHS += -I"$(SDK_INCLUDE_PATH)components/toolchain/gcc"
INCLUDEPATHS += -I"$(SDK_INCLUDE_PATH)components/toolchain"
INCLUDEPATHS += -I"$(SDK_INCLUDE_PATH)components/toolchain/CMSIS/Include"
INCLUDEPATHS += -I"$(SDK_INCLUDE_PATH)examples/bsp"
INCLUDEPATHS += -I"./include/"
INCLUDEPATHS += -I"./src/"
INCLUDEPATHS += -I"$(SDK_INCLUDE_PATH)"
INCLUDEPATHS += -I"$(SDK_INCLUDE_PATH)gcc"
ifdef USE_BLE
INCLUDEPATHS += -I"$(SDK_INCLUDE_PATH)ble"
INCLUDEPATHS += -I"$(SDK_INCLUDE_PATH)ble/ble_services"
INCLUDEPATHS += -I"$(SDK_INCLUDE_PATH)app_common"
INCLUDEPATHS += -I"$(SDK_INCLUDE_PATH)sd_common"
INCLUDEPATHS += -I"$(SDK_INCLUDE_PATH)$(USE_SOFTDEVICE)"
endif
ifdef USE_EXT_SENSORS
INCLUDEPATHS += -I"$(SDK_INCLUDE_PATH)ext_sensors"
endif

BUILD_DIRECTORIES := $(sort $(OBJECT_DIRECTORY) $(OUTPUT_BINARY_DIRECTORY) $(LISTING_DIRECTORY) )

C_SOURCE_FILENAMES = $(notdir $(C_SOURCE_FILES) )
ASSEMBLER_SOURCE_FILENAMES = $(notdir $(ASSEMBLER_SOURCE_FILES) )

C_SOURCE_PATHS = src/

# Make a list of source paths
C_SOURCE_PATHS += $(SDK_SOURCE_PATH) $(wildcard $(SDK_SOURCE_PATH)*/)
ifdef USE_BLE
C_SOURCE_PATHS += $(wildcard $(SDK_SOURCE_PATH)ble/*/)
endif
ifdef USE_EXT_SENSORS
C_SOURCE_PATHS += $(wildcard $(SDK_SOURCE_PATH)ext_sensors/*/)
endif
ASSEMBLER_SOURCE_PATHS = ../ $(SDK_SOURCE_PATH) $(wildcard $(SDK_SOURCE_PATH)*/)

C_OBJECTS = $(addprefix $(OBJECT_DIRECTORY)/, $(C_SOURCE_FILENAMES:.c=.o) )
ASSEMBLER_OBJECTS = $(addprefix $(OBJECT_DIRECTORY)/, $(ASSEMBLER_SOURCE_FILENAMES:.s=.o) )

C_SOURCE_PATHS += $(SDK_INCLUDE_PATH)components/drivers_nrf/delay
C_SOURCE_PATHS += $(SDK_INCLUDE_PATH)components/toolchain
ASSEMBLER_SOURCE_PATHS += $(SDK_INCLUDE_PATH)components/toolchain/gcc

# Set source lookup paths
vpath %.c $(C_SOURCE_PATHS)
vpath %.s $(ASSEMBLER_SOURCE_PATHS)

# Include automatically previously generated dependencies
-include $(addprefix $(OBJECT_DIRECTORY)/, $(COBJS:.o=.d))

### Targets
debug:    CFLAGS += -DDEBUG -g3 -O0
debug:    ASMFLAGS += -DDEBUG -g3 -O0
debug:    $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).bin $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).hex

.PHONY: release
release:  clean
release:  CFLAGS += -DNDEBUG -O3
release:  ASMFLAGS += -DNDEBUG -O3
release:  $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).bin $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).hex

echostuff:
	@echo "CC      [$(CC)]"
	@echo "AS      [$(AS)]"
	@echo "AR      [$(AR)]"
	@echo "LD      [$(LD)]"
	@echo "NM      [$(NM)]"
	@echo "OBJDUMP [$(OBJDUMP)]"
	@echo "OBJCOPY [$(OBJCOPY)]"
	@echo ""
	@echo ASSEMBLER_SOURCE_FILES [$(ASSEMBLER_SOURCE_FILES)]
	@echo ""
	@echo C_SOURCE_FILENAMES: [$(C_SOURCE_FILENAMES)]
	@echo C_OBJECTS: [$(C_OBJECTS)]
	@echo C_SOURCE_FILES: [$(C_SOURCE_FILES)]
	@echo C_SOURCE_FILENAMES: [$(C_SOURCE_FILENAMES)]
	@echo C_SOURCE_PATHS [$(C_SOURCE_PATHS)]
	@echo ""
	@echo SDK_SOURCE_PATH [$(SDK_SOURCE_PATH)]
	@echo ""
	@echo "NRF_SDK_PATH [$(NRF_SDK_PATH)]"
	@echo "SDK_INCLUDE_PATH [$(SDK_INCLUDE_PATH)]"
	@echo ""
	@echo "LDFLAGS [$(LDFLAGS)]"
	@echo "INCLUDEPATHS [$(INCLUDEPATHS)]"
	@echo ""

## Create build directories
$(BUILD_DIRECTORIES):
	$(MK) $@

## Create objects from C source files
$(OBJECT_DIRECTORY)/%.o: %.c
	@echo $(OBJECT_DIRECTORY)/$@
	$(CC) $(CFLAGS) $(INCLUDEPATHS) -M $< -MF "$(@:.o=.d)" -MT $@
	$(CC) $(CFLAGS) $(INCLUDEPATHS) -c -o $@ $<

## Assemble .s files
$(OBJECT_DIRECTORY)/%.o: %.s
	@echo $(OBJECT_DIRECTORY)/$@
	$(CC) $(ASMFLAGS) $(INCLUDEPATHS) -c -o $@ $<

## Link C and assembler objects to an .out file
$(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out: $(BUILD_DIRECTORIES) $(C_OBJECTS) $(ASSEMBLER_OBJECTS) $(LIBRARIES)
	@echo "Linking C and assembler objects to an .out file" [$(OBJECT_DIRECTORY)/$@]
	@echo ""
	$(CC) $(LDFLAGS) $(C_OBJECTS) $(ASSEMBLER_OBJECTS) $(LIBRARIES) -o $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out

## Create binary .bin file from the .out file
$(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).bin: $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out
	@echo $(OBJECT_DIRECTORY)/$@
	$(OBJCOPY) -O binary $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).bin

## Create binary .hex file from the .out file
$(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).hex: $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out
	@echo $(OBJECT_DIRECTORY)/$@
	$(OBJCOPY) -O ihex $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).hex

## Default build target
.PHONY: all
all: clean debug

clean:
	rm -rf $(OUTPUT_BINARY_DIRECTORY)
	rm -f .gdbinit

HEX = $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).hex
ELF = $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out
BIN = $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).bin

SERIAL_PORT = /dev/ttyACM0
GDB_PORT_NUMBER = 3333

SOFTDEVICE_OUTPUT = $(OUTPUT_BINARY_DIRECTORY)/$(notdir $(SOFTDEVICE))
MAIN_BIN = $(SOFTDEVICE_OUTPUT:.hex=_mainpart.bin)
UICR_BIN = $(SOFTDEVICE_OUTPUT:.hex=_uicr.bin)

PYOCD_FLASH = sudo pyocd-flashtool
PYOCD_GDB = sudo pyocd-gdbserver

flash: all
	$(PYOCD_FLASH) $(HEX)

flash-softdevice: erase-all flash-softdevice
ifndef SOFTDEVICE
	$(error "You need to set the SOFTDEVICE command-line parameter to a path (without spaces) to the softdevice hex-file")
endif
	# Convert from hex to binary. Split original hex in two to avoid huge (>250 MB) binary file with just 0s.
	$(OBJCOPY) -Iihex -Obinary --remove-section .sec3 $(SOFTDEVICE) $(MAIN_BIN)
	$(OBJCOPY) -Iihex -Obinary --remove-section .sec1 --remove-section .sec2 $(SOFTDEVICE) $(UICR_BIN)

erase-all:
	$(PYOCD_FLASH) -ce

gdb:
	@echo $(GDB) -x .gdbinit $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out
	$(GDB) -x .gdbinit $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out

startdebug:
	$(PYOCD_GDB) -o -t nrf51

.PHONY: flash flash-softdevice erase-all startdebug
