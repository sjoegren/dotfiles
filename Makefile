PREFIX := $(HOME)/.local
BUILDDIR := build
PATH := bin:$(PATH)
CHECKVER := $(PREFIX)/bin/check_version
DOTFILES_DIR := $(PWD)
MACROS = -D DOTFILES_DIR="$(DOTFILES_DIR)"
MACROS += -D HOME_DIR="$(HOME)"

SOURCES := $(wildcard *.m4)
SOURCES += $(wildcard bash/*.m4)
TARGETS := $(patsubst %.m4, %, $(SOURCES))
BUILD_TARGETS = bin/pidcmd

.PHONY: all clean clean-build

all: $(TARGETS) $(BUILD_TARGETS)

%: %.m4 | $(CHECKVER)
	m4 $(MACROS) $< > $@

$(CHECKVER):
	PREFIX="$(PREFIX)" bash get_check_version.sh

bin/%:
	utils/build-utils.sh "$(DOTFILES_DIR)"

clean: clean-build
	rm -fv $(TARGETS) $(CHECKVER)

clean-build:
	rm -fv $(BUILD_TARGETS)
