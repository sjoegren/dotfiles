BUILDDIR := build
MACROS =

# If findstring finds "True" in command output, it evaluates to "" and the
# ifneq expression evaluates to true.
ifneq (,$(findstring true, \
	$(shell git --version | bin/check_version -r 'version ([0-9]+\.[0-9]+\.[0-9]+)' -c 2.21) \
	))
	MACROS += -D DF_GIT_DATE_FORMAT="human"
	MACROS += -D DF_GIT_VERSION_21
else
	MACROS += -D DF_GIT_DATE_FORMAT="short"
endif

ifneq (,$(findstring true, \
	$(shell tmux -V | bin/check_version -r 'tmux ([0-9]+\.[0-9]+)' -c 2.4) \
	))
	MACROS += -D DF_TMUX_VERSION_24
endif

ifneq (,$(findstring true, \
	$(shell tmux -V | bin/check_version -r 'tmux ([0-9]+\.[0-9]+)' -c 2.9) \
	))
	MACROS += -D DF_TMUX_VERSION_29
endif

SOURCES := $(wildcard *.m4)
SOURCES += $(wildcard bash/*.m4)
TARGETS := $(patsubst %.m4, %, $(SOURCES))

.PHONY: all clean

all: $(TARGETS)

%: %.m4
	m4 $(M4_OPTS) $(MACROS) $< > $@

clean:
	rm -fv $(TARGETS)
