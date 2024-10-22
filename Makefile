Q = @

CC = arm-none-eabi-gcc

BUILD_DIR = output
NWLINK = npx --yes -- nwlink@0.0.17
LINK_GC = 1
LTO = 1

define object_for
$(addprefix $(BUILD_DIR)/,$(addsuffix .o,$(basename $(1))))
endef

src = $(addprefix src/,\
	main.c \
)

CFLAGS = -std=c99
CFLAGS += $(shell $(NWLINK) eadk-cflags)
CFLAGS += -Os -Wall
CFLAGS += -ggdb

# CFLAGS += -mfloat-abi=hard
# # CFLAGS += -mfloat-abi=softfp
# # CFLAGS += -mfpu=fpv4-sp-d16
# # CFLAGS += -marm
# CFLAGS += -mcpu=cortex-m7
# CFLAGS += -mthumb

LDFLAGS = -Wl,--relocatable
LDFLAGS += -nostartfiles
LDFLAGS += --specs=nano.specs
# LDFLAGS += --specs=nosys.specs # Alternatively, use full-fledged newlib

# LDFLAGS += -mfloat-abi=hard
# # LDFLAGS += -mfloat-abi=softfp
# # LDFLAGS += -mfpu=fpv4-sp-d16
# # LDFLAGS += -marm
# LDFLAGS += -mcpu=cortex-m7
# LDFLAGS += -mthumb

# OMICROBFLAGS += -cxxopt "-mfloat-abi=hard"
# OMICROBFLAGS += -cxxopt "-nostartfiles"
# # OMICROBFLAGS += -cxxopt "-mfloat-abi=softfp"
# # OMICROBFLAGS += -mfpu=fpv4-sp-d16
# # OMICROBFLAGS += -marm
# OMICROBFLAGS += -cxxopt "-mcpu=cortex-m7"
# # OMICROBFLAGS += -cxxopt mthumb

# # Add flags to link OCaml code too -------------------------------
# # # CFLAGS += -fPIC
# # CFLAGS += -I $(ocamlopt -where)
# # CFLAGS += -L $(ocamlopt -where)
# CFLAGS += -lm
# # # CFLAGS += -ltermcap
# # # CFLAGS += -ldl

POSTCAMLFLAGS =
# # POSTCAMLFLAGS += -lcamlrun   # for OCaml bytecode
# # POSTCAMLFLAGS += -lasmrun    # for OCaml native code
# POSTCAMLFLAGS += -lm
# # POSTCAMLFLAGS += -ltermcap
# # POSTCAMLFLAGS += -ldl
# # ---------------------------------------- Done for the OCaml flags

ifeq ($(LINK_GC),1)
CFLAGS += -fdata-sections -ffunction-sections
LDFLAGS += -Wl,-e,main -Wl,-u,eadk_app_name -Wl,-u,eadk_app_icon -Wl,-u,eadk_api_level
LDFLAGS += -Wl,--gc-sections
endif

ifeq ($(LTO),1)
CFLAGS += -flto -fno-fat-lto-objects
CFLAGS += -fwhole-program
CFLAGS += -fvisibility=internal
LDFLAGS += -flinker-output=nolto-rel
endif

.PHONY: ocaml-c-native-app
ocaml-c-native-app: ocaml-standalone-object $(BUILD_DIR)/ocaml-c-native-app.nwa

.PHONY: build
build: $(BUILD_DIR)/app.nwa

.PHONY: ocaml-standalone-object
ocaml-standalone-object:
	mkdir --parents ./output/src/
# eval $(opam env --switch=4.02.3+32bit)
# @echo "OCaml version:"
# ocamlopt -version
# opam switch
#	ocamlopt -cc arm-none-eabi-gcc -output-obj -o ./output/src/embed_out.o src/fact.ml
#	ocamlfind -toolchain armv7_none_eabihf ocamlopt -cc arm-none-eabi-gcc -output-obj -o ./output/src/embed_out.o src/fact.ml
	/home/lilian/publis/OMicroB.git/bin/omicrob $(OMICROBFLAGS) -v -device microbit2 src/fact.ml
# /home/lilian/publis/OMicroB.git/bin/omicrob $(OMICROBFLAGS) -v -device numworks src/fact.ml
	file src/fact.arm_o
	readelf -h src/fact.arm_o
# /home/lilian/publis/ocaml-arm/OUTPUT/bin/ocamlopt -farch armv7 -output-obj -o output/src/embed_out.o src/fact.ml
# ocamlopt -output-obj -o output/src/embed_out.o src/fact.ml

.PHONY: check
check: $(BUILD_DIR)/app.bin

.PHONY: run
run: $(BUILD_DIR)/app.nwa src/input.txt
	@echo "INSTALL $<"
	$(Q) $(NWLINK) install-nwa --external-data src/input.txt $<

$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.nwa src/input.txt
	@echo "BIN     $@"
	$(Q) $(NWLINK) nwa-bin --external-data src/input.txt $< $@

$(BUILD_DIR)/%.elf: $(BUILD_DIR)/%.nwa src/input.txt
	@echo "ELF     $@"
	$(Q) $(NWLINK) nwa-elf --external-data src/input.txt $< $@

$(BUILD_DIR)/app.nwa: $(call object_for,$(src)) $(BUILD_DIR)/icon.o
	@echo "LD      $@"
	$(Q) $(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^ $(POSTCAMLFLAGS)
# $(Q) $(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^ src/fact.arm_o $(POSTCAMLFLAGS)

$(addprefix $(BUILD_DIR)/,%.o): %.c | $(BUILD_DIR)
	@echo "CC      $^"
	$(Q) $(CC) $(CFLAGS) -c $^ -o $@ $(POSTCAMLFLAGS)

# FIXME: experimental: add only ONE rule to compile directly
$(BUILD_DIR)/ocaml-c-native-app.nwa: $(BUILD_DIR)/icon.o src/main.c
	@echo "CC+LD   $@"
	$(Q) $(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^ $(POSTCAMLFLAGS)
# $(Q) $(CC) $(CFLAGS) $(LDFLAGS) -o $@ src/fact.arm_o $^ $(POSTCAMLFLAGS)
	readelf -h $@
	file $@
	ls -larth $@

$(BUILD_DIR)/icon.o: src/icon.png
	@echo "ICON    $<"
	$(Q) $(NWLINK) png-icon-o $< $@

.PRECIOUS: $(BUILD_DIR)
$(BUILD_DIR):
	$(Q) mkdir -p $@/src

.PHONY: clean
clean:
	@echo "CLEAN"
	$(Q) rm -rf $(BUILD_DIR)
