PREFIX := $(HOME)/.local
BUILDDIR := build
PATH := $(PREFIX):bin:$(PATH)
CHECKVER := $(PREFIX)/bin/check_version
DOTFILES_DIR := $(PWD)
MACROS += -D DOTFILES_DIR="$(DOTFILES_DIR)"
MACROS += -D HOME_DIR="$(HOME)"
ifeq ($(USER), root)
	MACROS += -D BASIC_CONFIG=1
endif

gituser := $(shell git -C ~ config --get user.name 2> /dev/null)
ifeq ($(.SHELLSTATUS), 0)
	MACROS += -D GIT_USER_NAME="$(gituser)"
else
	MACROS += -D GIT_USER_NAME=$(USER)
endif

ifneq ($(wildcard /usr/share/doc/powerline-fonts),)
	MACROS += -D HAVE_POWERLINE_FONTS=1
endif

# check existence of programs in prog_list, define m4 macros "HAVE_prog" for
# those that exist.
prog_list := xclip tmux bat fzf git realpath jq check_version pidcmd delta rg fd
check_program = $(if $(shell command -v $(prog) 2> /dev/null), -D HAVE_$(prog))
have_progs := $(foreach prog, $(prog_list), $(check_program))

SOURCES := $(wildcard *.m4)
SOURCES += $(wildcard bash/*.m4)
SOURCES += $(wildcard vim/*.m4)
TARGETS := $(patsubst %.m4, %, $(SOURCES))
BUILD_TARGETS = bin/pidcmd

.PHONY: all clean clean-build

all: $(TARGETS)

%: %.m4 Makefile | $(CHECKVER) $(BUILD_TARGETS)
	@echo "--- Building $@"
	@m4 $(MACROS) $(have_progs) $< > $@

.PHONY: check_version
check_version: $(CHECKVER)

$(CHECKVER):
	@echo "--- Installing $@"
	PREFIX="$(PREFIX)" bash get_check_version.sh
	check_version -V

$(BUILD_TARGETS):
	@echo "--- Installing $@"
	utils/build-utils.sh "$(DOTFILES_DIR)"

clean: clean-build
	rm -fv $(TARGETS) $(CHECKVER)

clean-build:
	rm -fv $(BUILD_TARGETS)
