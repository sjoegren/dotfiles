PREFIX := $(HOME)/.local
BUILDDIR := build
PATH := bin:$(PATH)
CHECKVER := $(PREFIX)/bin/check_version
DOTFILES_DIR := $(PWD)
MACROS = -D DOTFILES_DIR="$(DOTFILES_DIR)"
MACROS += -D HOME_DIR="$(HOME)"
ifeq ($(USER), root)
	MACROS += -D BASIC_CONFIG=1
endif

gituser := $(shell git -C ~ config --get user.name)
ifeq ($(.SHELLSTATUS), 0)
	MACROS += -D GIT_USER_NAME="$(gituser)"
else
	MACROS += -D GIT_USER_NAME=$(USER)
endif

SOURCES := $(wildcard *.m4)
SOURCES += $(wildcard bash/*.m4)
SOURCES += $(wildcard vim/*.m4)
TARGETS := $(patsubst %.m4, %, $(SOURCES))
BUILD_TARGETS = bin/pidcmd

.PHONY: all clean clean-build

all: $(TARGETS)

%: %.m4 | $(CHECKVER) $(BUILD_TARGETS)
	@echo "--- Installing $@"
	m4 $(MACROS) $< > $@

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
