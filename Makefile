BUILDDIR := build
MACROS =

GIT_VERSION := $(shell git --version | bin/check_version.py --match 'version (\d+\.\d+\.\d+)' --operator ge --check-version 2.21)

ifeq ($(.SHELLSTATUS), 0)
	MACROS += -D DF_GIT_DATE_FORMAT="human"
	MACROS += -D DF_GIT_PUSH_DEFAULT
else
	MACROS += -D DF_GIT_DATE_FORMAT="short"
endif

SOURCES := $(wildcard *.m4)
TARGETS := $(patsubst %.m4, %, $(SOURCES))
BUILD_TARGETS := $(addprefix $(BUILDDIR)/, $(TARGETS))

.PHONY: all clean

all: $(TARGETS)

%: $(BUILDDIR)/%
	cp $< $@

.INTERMEDIATE: $(BUILD_TARGETS)
$(BUILDDIR)/% : %.m4
	m4 $(M4_OPTS) $(MACROS) $< > $@

$(BUILD_TARGETS): | $(BUILDDIR)

$(BUILDDIR):
	mkdir -p $@

clean:
	rm -rf $(BUILDDIR)
	rm -fv $(TARGETS)
