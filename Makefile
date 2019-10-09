BUILDDIR := build
GIT_VERSION := $(shell git --version)
GIT_V1 := $(findstring git version 1, $(GIT_VERSION))
MACROS =

ifdef GIT_V1
	MACROS += '-DGIT_V1'
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
	mkdir $@

clean:
	rm -rf $(BUILDDIR)
	rm -fv $(TARGETS)
