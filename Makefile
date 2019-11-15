BUILDDIR := build
MACROS =

# If findstring finds "True" in command output, it evaluates to "" and the
# ifneq expression evaluates to true.
ifneq (,$(findstring True, \
	$(shell git --version | bin/check_version.py --match 'version (\d+\.\d+\.\d+)' --operator ge --check-version 2.21) \
	))
	MACROS += -D DF_GIT_DATE_FORMAT="human"
	MACROS += -D DF_GIT_VERSION_21
else
	MACROS += -D DF_GIT_DATE_FORMAT="short"
endif

ifneq (,$(findstring True, \
	$(shell tmux -V | bin/check_version.py --match '(\d+\.\d+)' --operator ge --check-version 2.4) \
	))
	MACROS += -D DF_TMUX_VERSION_24
endif

ifneq (,$(findstring True, \
	$(shell tmux -V | bin/check_version.py --match '(\d+\.\d+)' --operator ge --check-version 2.9) \
	))
	MACROS += -D DF_TMUX_VERSION_29
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
