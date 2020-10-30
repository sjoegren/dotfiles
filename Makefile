BUILDDIR := build
PATH := bin:$(PATH)
CHECKVER := bin/check_version
DOTFILES_DIR := $(PWD)
MACROS = -D DOTFILES_DIR="$(DOTFILES_DIR)"
MACROS += -D HOME_DIR="$(HOME)"

SOURCES := $(wildcard *.m4)
SOURCES += $(wildcard bash/*.m4)
TARGETS := $(patsubst %.m4, %, $(SOURCES))
BUILD_TARGETS = bin/pidcmd

.PHONY: all clean

all: $(TARGETS) $(BUILD_TARGETS)

%: %.m4 | $(CHECKVER)
	m4 $(MACROS) $< > $@

$(CHECKVER):
	bash get_check_version.sh

bin/%:
	utils/build-utils.sh "$(DOTFILES_DIR)"

clean:
	rm -fv $(TARGETS) $(CHECKVER)
