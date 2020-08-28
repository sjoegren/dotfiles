BUILDDIR := build
PATH := bin:$(PATH)
CHECKVER := bin/check_version
DOTFILES_DIR := $(HOME)/.dotfiles
MACROS = -D DOTFILES_DIR="$(DOTFILES_DIR)"

SOURCES := $(wildcard *.m4)
SOURCES += $(wildcard bash/*.m4)
TARGETS := $(patsubst %.m4, %, $(SOURCES))

.PHONY: all clean

all: $(TARGETS)

%: %.m4 | $(CHECKVER)
	m4 $(MACROS) $< > $@

$(CHECKVER):
	bash get_check_version.sh

clean:
	rm -fv $(TARGETS) $(CHECKVER)
