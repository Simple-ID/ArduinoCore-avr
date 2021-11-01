SHELL:=cmd
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables
MAKEFLAGS += --warn-undefined-variables
makefiles:=$(MAKEFILE_LIST)
.DEFAULT_GOAL: all
.PHONY: all upload

compiler:=avr-gcc

build_dir:=build
implementation_dir:=cores/arduino
variant_dir:=variants/standard

compiler_search_dir_flags:=-I $(implementation_dir) -I $(variant_dir)
required_arduino_flags:= -fdata-sections -ffunction-sections -Os -fno-exceptions -flto -fuse-linker-plugin -Wall -Wextra -Wshadow -Werror -pedantic
boards_flags:= -mmcu=atmega328p -DF_CPU=16000000L -DARDUINO=185 -DARDUINO_=AVR -DARDUINO_ARCH_=AVR_UNO
required_exceutable_flags:=-s #remove symbols

flags:=$(boards_flags) $(required_arduino_flags) $(compiler_search_dir_flags)


objects:=$(patsubst %.cpp,$(build_dir)/objects/%.o,$(notdir $(wildcard $(implementation_dir)/*.cpp)))
objects+=$(patsubst %.c,$(build_dir)/objects/%.o,$(notdir $(wildcard $(implementation_dir)/*.c)))
objects+=$(build_dir)/objects/wiring_pulse_a.o

dependencies:=$($(notdir $(objects):%.o=$(build_dir)/dependencies/%.d)
$(dependencies):;


vpath %.c $(implementation_dir)
vpath %.S $(implementation_dir)
vpath %.cpp $(implementation_dir)
vpath %.d $(build_dir)/dependencies

all:$(build_dir)/sketch.hex;

$(build_dir)/objects/%.o:%.c $(makefiles)|$(build_dir)/objects
	$(compiler) $(flags) -o $@ -c $<

$(build_dir)/objects/%.o:%.cpp $(makefiles)|$(build_dir)/objects
	$(compiler) $(flags) -o $@ -c $<

$(build_dir)/objects/wiring_pulse_a.o:wiring_pulse.S $(makefiles)|$(build_dir)/objects
		avr-as -o $@ $<

$(build_dir)/libArduino.a:$(objects)|$(build_dir)
	avr-ar -rcs $@ $(objects)

$(build_dir)/sketch.elf: sketch.cpp $(build_dir)/libArduino.a $(makefiles)|$(build_dir)
	$(compiler) $(flags) -s -o $@ $< -L$(build_dir) -lArduino

$(build_dir)/sketch.hex:$(build_dir)/sketch.elf|$(build_dir)
	avr-objcopy  -O ihex -R .eeprom $< $@

upload:$(build_dir)/sketch.hex
	avrdude -c arduino -P com3 -p m328p -b 115200 -U flash:w:$(build_dir)/sketch.hex:i

$(build_dir):
	md $(subst /,\\,$@)>NUL
$(build_dir)/objects:
	md $(subst /,\\,$@)>NUL
