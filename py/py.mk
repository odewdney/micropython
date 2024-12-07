# where py object files go (they have a name prefix to prevent filename clashes)
PY_BUILD = $(BUILD)/py

# where autogenerated header files go
HEADER_BUILD = $(BUILD)/genhdr

# file containing qstr defs for the core Python bit
PY_QSTR_DEFS = $(PY_SRC)/qstrdefs.h

# If qstr autogeneration is not disabled we specify the output header
# for all collected qstrings.
ifneq ($(QSTR_AUTOGEN_DISABLE),1)
QSTR_DEFS_COLLECTED = $(HEADER_BUILD)/qstrdefs.collected.h
endif

# Any files listed by these variables will cause a full regeneration of qstrs
# DEPENDENCIES: included in qstr processing; REQUIREMENTS: not included
QSTR_GLOBAL_DEPENDENCIES += $(PY_SRC)/mpconfig.h mpconfigport.h
QSTR_GLOBAL_REQUIREMENTS += $(HEADER_BUILD)/mpversion.h

# some code is performance bottleneck and compiled with other optimization options
CSUPEROPT = -O3

# Enable building 32-bit code on 64-bit host.
ifeq ($(MICROPY_FORCE_32BIT),1)
CC += -m32
CXX += -m32
LD += -m32
endif

# External modules written in C.
ifneq ($(USER_C_MODULES),)
# pre-define USERMOD variables as expanded so that variables are immediate
# expanded as they're added to them

# Confirm the provided path exists, show abspath if not to make it clearer to fix.
$(if $(wildcard $(USER_C_MODULES)/.),,$(error USER_C_MODULES doesn't exist: $(abspath $(USER_C_MODULES))))

# C/C++ files that are included in the QSTR/module build
SRC_USERMOD_C :=
SRC_USERMOD_CXX :=
# Other C/C++/Assembly files (e.g. libraries or helpers)
SRC_USERMOD_LIB_C :=
SRC_USERMOD_LIB_CXX :=
SRC_USERMOD_LIB_ASM :=
# Optionally set flags
CFLAGS_USERMOD :=
CXXFLAGS_USERMOD :=
LDFLAGS_USERMOD :=

# Backwards compatibility with older user c modules that set SRC_USERMOD
# added to SRC_USERMOD_C below
SRC_USERMOD :=

$(foreach module, $(wildcard $(USER_C_MODULES)/*/micropython.mk), \
    $(eval USERMOD_DIR = $(patsubst %/,%,$(dir $(module))))\
    $(info Including User C Module from $(USERMOD_DIR))\
	$(eval include $(module))\
)

SRC_USERMOD_C += $(SRC_USERMOD)

SRC_USERMOD_PATHFIX_C += $(patsubst $(USER_C_MODULES)/%.c,%.c,$(SRC_USERMOD_C))
SRC_USERMOD_PATHFIX_CXX += $(patsubst $(USER_C_MODULES)/%.cpp,%.cpp,$(SRC_USERMOD_CXX))
SRC_USERMOD_PATHFIX_LIB_C += $(patsubst $(USER_C_MODULES)/%.c,%.c,$(SRC_USERMOD_LIB_C))
SRC_USERMOD_PATHFIX_LIB_CXX += $(patsubst $(USER_C_MODULES)/%.cpp,%.cpp,$(SRC_USERMOD_LIB_CXX))
SRC_USERMOD_PATHFIX_LIB_ASM += $(patsubst $(USER_C_MODULES)/%.S,%.S,$(SRC_USERMOD_LIB_ASM))

CFLAGS += $(CFLAGS_USERMOD)
CXXFLAGS += $(CXXFLAGS_USERMOD)
LDFLAGS += $(LDFLAGS_USERMOD)

SRC_QSTR += $(SRC_USERMOD_PATHFIX_C) $(SRC_USERMOD_PATHFIX_CXX)
PY_O += $(addprefix $(BUILD)/, $(SRC_USERMOD_PATHFIX_C:.c=.o))
PY_O += $(addprefix $(BUILD)/, $(SRC_USERMOD_PATHFIX_CXX:.cpp=.o))
PY_O += $(addprefix $(BUILD)/, $(SRC_USERMOD_PATHFIX_LIB_C:.c=.o))
PY_O += $(addprefix $(BUILD)/, $(SRC_USERMOD_PATHFIX_LIB_CXX:.cpp=.o))
PY_O += $(addprefix $(BUILD)/, $(SRC_USERMOD_PATHFIX_LIB_ASM:.S=.o))
endif

# py object files
PY_CORE_O_BASENAME = $(addprefix py/,\
	mpstate.o \
	nlr.o \
	nlrx86.o \
	nlrx64.o \
	nlrthumb.o \
	nlraarch64.o \
	nlrmips.o \
	nlrpowerpc.o \
	nlrxtensa.o \
	nlrrv32.o \
	nlrrv64.o \
	nlrsetjmp.o \
	malloc.o \
	gc.o \
	pystack.o \
	qstr.o \
	vstr.o \
	mpprint.o \
	unicode.o \
	mpz.o \
	reader.o \
	lexer.o \
	parse.o \
	scope.o \
	compile.o \
	emitcommon.o \
	emitbc.o \
	asmbase.o \
	asmx64.o \
	emitnx64.o \
	asmx86.o \
	emitnx86.o \
	asmthumb.o \
	emitnthumb.o \
	emitinlinethumb.o \
	asmarm.o \
	emitnarm.o \
	asmxtensa.o \
	emitnxtensa.o \
	emitinlinextensa.o \
	emitnxtensawin.o \
	asmrv32.o \
	emitnrv32.o \
	emitndebug.o \
	formatfloat.o \
	parsenumbase.o \
	parsenum.o \
	emitglue.o \
	persistentcode.o \
	runtime.o \
	runtime_utils.o \
	scheduler.o \
	nativeglue.o \
	pairheap.o \
	ringbuf.o \
	cstack.o \
	stackctrl.o \
	argcheck.o \
	warning.o \
	profile.o \
	map.o \
	obj.o \
	objarray.o \
	objattrtuple.o \
	objbool.o \
	objboundmeth.o \
	objcell.o \
	objclosure.o \
	objcomplex.o \
	objdeque.o \
	objdict.o \
	objenumerate.o \
	objexcept.o \
	objfilter.o \
	objfloat.o \
	objfun.o \
	objgenerator.o \
	objgetitemiter.o \
	objint.o \
	objint_longlong.o \
	objint_mpz.o \
	objlist.o \
	objmap.o \
	objmodule.o \
	objobject.o \
	objpolyiter.o \
	objproperty.o \
	objnone.o \
	objnamedtuple.o \
	objrange.o \
	objreversed.o \
	objringio.o \
	objset.o \
	objsingleton.o \
	objslice.o \
	objstr.o \
	objstrunicode.o \
	objstringio.o \
	objtuple.o \
	objtype.o \
	objzip.o \
	opmethods.o \
	sequence.o \
	stream.o \
	binary.o \
	builtinimport.o \
	builtinevex.o \
	builtinhelp.o \
	modarray.o \
	modbuiltins.o \
	modcollections.o \
	modgc.o \
	modio.o \
	modmath.o \
	modcmath.o \
	modmicropython.o \
	modstruct.o \
	modsys.o \
	moderrno.o \
	modthread.o \
	vm.o \
	bc.o \
	showbc.o \
	repl.o \
	smallint.o \
	frozenmod.o \
	)

# prepend the build destination prefix to the py object files
PY_CORE_O = $(addprefix $(BUILD)/, $(PY_CORE_O_BASENAME))

# this is a convenience variable for ports that want core, extmod and frozen code
PY_O += $(PY_CORE_O)

# object file for frozen code specified via a manifest
ifneq ($(FROZEN_MANIFEST),)
PY_O += $(BUILD)/frozen_content.o
endif

# Sources that may contain qstrings
SRC_QSTR_IGNORE = py/nlr%
SRC_QSTR += $(filter-out $(SRC_QSTR_IGNORE),$(PY_CORE_O_BASENAME:.o=.c))

# Anything that depends on FORCE will be considered out-of-date
FORCE:
.PHONY: FORCE

$(HEADER_BUILD)/mpversion.h: FORCE | $(HEADER_BUILD)
	$(Q)$(PYTHON) $(PY_SRC)/makeversionhdr.py $@

# mpconfigport.mk is optional, but changes to it may drastically change
# overall config, so they need to be caught
MPCONFIGPORT_MK = $(wildcard mpconfigport.mk)

# qstr data
# Adding an order only dependency on $(HEADER_BUILD) causes $(HEADER_BUILD) to get
# created before we run the script to generate the .h
# Note: we need to protect the qstr names from the preprocessor, so we wrap
# the lines in "" and then unwrap after the preprocessor is finished.
# See more information about this process in docs/develop/qstr.rst.
$(HEADER_BUILD)/qstrdefs.generated.h: $(PY_QSTR_DEFS) $(QSTR_DEFS) $(QSTR_DEFS_COLLECTED) $(PY_SRC)/makeqstrdata.py mpconfigport.h $(MPCONFIGPORT_MK) $(PY_SRC)/mpconfig.h | $(HEADER_BUILD)
	$(ECHO) "GEN $@"
	$(Q)$(CAT) $(PY_QSTR_DEFS) $(QSTR_DEFS) $(QSTR_DEFS_COLLECTED) | $(SED) 's/^Q(.*)/"&"/' | $(CPP) $(CFLAGS) - | $(SED) 's/^\"\(Q(.*)\)\"/\1/' > $(HEADER_BUILD)/qstrdefs.preprocessed.h
	$(Q)$(PYTHON) $(PY_SRC)/makeqstrdata.py $(HEADER_BUILD)/qstrdefs.preprocessed.h > $@

$(HEADER_BUILD)/compressed.data.h: $(HEADER_BUILD)/compressed.collected
	$(ECHO) "GEN $@"
	$(Q)$(PYTHON) $(PY_SRC)/makecompresseddata.py $< > $@

# build a list of registered modules for py/objmodule.c.
$(HEADER_BUILD)/moduledefs.h: $(HEADER_BUILD)/moduledefs.collected
	@$(ECHO) "GEN $@"
	$(Q)$(PYTHON) $(PY_SRC)/makemoduledefs.py $< > $@

# build a list of registered root pointers for py/mpstate.h.
$(HEADER_BUILD)/root_pointers.h: $(HEADER_BUILD)/root_pointers.collected $(PY_SRC)/make_root_pointers.py
	@$(ECHO) "GEN $@"
	$(Q)$(PYTHON) $(PY_SRC)/make_root_pointers.py $< > $@

# Standard C functions like memset need to be compiled with special flags so
# the compiler does not optimise these functions in terms of themselves.
CFLAGS_BUILTIN ?= -ffreestanding -fno-builtin -fno-lto
$(BUILD)/shared/libc/string0.o: CFLAGS += $(CFLAGS_BUILTIN)

# Force nlr code to always be compiled with space-saving optimisation so
# that the function preludes are of a minimal and predictable form.
$(PY_BUILD)/nlr%.o: CFLAGS += -Os

# optimising gc for speed; 5ms down to 4ms on pybv2
$(PY_BUILD)/gc.o: CFLAGS += $(CSUPEROPT)

# optimising vm for speed, adds only a small amount to code size but makes a huge difference to speed (20% faster)
$(PY_BUILD)/vm.o: CFLAGS += $(CSUPEROPT)
# Optimizing vm.o for modern deeply pipelined CPUs with branch predictors
# may require disabling tail jump optimization. This will make sure that
# each opcode has its own dispatching jump which will improve branch
# branch predictor efficiency.
# https://marc.info/?l=lua-l&m=129778596120851
# http://hg.python.org/cpython/file/b127046831e2/Python/ceval.c#l828
# http://www.emulators.com/docs/nx25_nostradamus.htm
#-fno-crossjumping
