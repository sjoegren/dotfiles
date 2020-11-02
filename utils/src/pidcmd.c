#include <config.h>
#include <ctype.h>
#include <dirent.h>
#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>

#include "debug.h"

#ifndef PACKAGE
#define PACKAGE "prog"
#define PACKAGE_STRING ""
#endif
static char doc_usage[] = "Usage: " PACKAGE " [-hV] [-a arg] pid";
static char doc_help[] =
    "Get an argument of the command line for a given PIDs child process.\n\n"
    "Options:\n"
    "  -a, --arg ARG         argument id from the pids child command line to return.\n"
    "                          first argument is 0, last is -1.\n"
    "  --tmux-cmd command    indicates that the input pid string is on the format 'cmd1:pid|cmdN:pid'.\n"
    "                          Find the pid associated with the given 'command'.\n"
    "                          Used in tmux format string as:\n"
    "                          #(pidcmd --arg -1 --tmux-cmd ssh \"#{P:#{pane_current_command}:#{pane_pid}|}\")\n"
    "  -h, --help            display this help and exit.\n"
    "  -V, --version         output version information and exit.\n"
	"Arguments:\n"
    "  pid                   parent process whose child to find.";
static const int MAX_FILENAME_LEN = 32;
static const int NO_INDEX = INT_MAX;
static const int MAX_CMDLINE_ARGS = 32;
static const size_t BUFFER_SIZE = 256;
static const char *TMUX_CMD_PID_TOKEN_DELIMITER = "|";

/**
 * Return pointer to a malloc'ed copy of 's', where occurrences of 'search' are
 * replaced by 'replace'.
 * Caller must free() the returned pointer.
 */
char *strndup_replace(const char *s, size_t n, char search, char replace)
{
	char *dest = malloc(sizeof(char) * n + 1);
	check_mem(dest);
	memcpy(dest, s, n);
	for (char *p = dest; p != (dest + n - 1); p++) {
		if (*p == search)
			*p = replace;
	}
	return dest;
error:
	return NULL;
}

/**
 * Return pointer to index'th argument in cmdline.
 * cmdline is a byte array with arguments separated by null bytes.
 */
char *cmdline_arg(char *cmdline, size_t size, int index)
{
	char *p = cmdline, *end = (cmdline + size - 1);
	int i = 0;
	if (index == 0)
		return cmdline;
	char *args[MAX_CMDLINE_ARGS];

	while (p < end && i < MAX_CMDLINE_ARGS) {
		debug("arg %d = '%s'", i, p);
		args[i++] = p;
		p = strchr(p, '\0') + 1;
	}
	check(p >= end, "args should be exhausted");
	if (index < 0) {
		check_debug(abs(index) <= i, "No argument at index '%d' (got %d arguments)", index,
		            i);
		return args[i + index];
	}
	check_debug(index < i, "No argument at index '%d' (got %d arguments)", index, i);
	return args[index];
error:
	return NULL;
}

/*
 * Given a `pid`, read at most n bytes from the file /proc/pid/cmdline into the
 * buffer n bytes pointed to by cmdline.
 */
size_t get_proc_cmdline(int pid, char *cmdline, size_t n)
{
	char filename[MAX_FILENAME_LEN];
	FILE *file;
	size_t size = 0;
	snprintf(filename, MAX_FILENAME_LEN, "/proc/%d/cmdline", pid);
	file = fopen(filename, "r");
	check(file, "%s", filename);
	size = fread(cmdline, 1, n, file);
	debug("Read %lu bytes from %s", size, filename);
error:
	if (file)
		fclose(file);
	return size;
}

/*
 * Return non-zero if all characters in s are digits.
 */
int isnumeric(const char *s)
{
	char *p = (char *)s;
	while (*p)
		if (!isdigit(*p++))
			return 0;
	return 1;
}

/*
 * Given PID `parent`, find the child pid in /proc file system and return the
 * childs pid.
 */
int get_child_pid(int parent)
{
	DIR *proc = opendir("/proc");
	char filename[MAX_FILENAME_LEN], buf[BUFFER_SIZE], *lineptr;
	FILE *file;
	struct dirent *dir;
	int pid, ppid, found_pid = 0, read;

	check_mem(proc);
	while ((dir = readdir(proc)) != NULL && !found_pid) {
		if (dir->d_type == DT_DIR && isnumeric(dir->d_name)) {
			sprintf(filename, "/proc/%s/stat", dir->d_name);
			if ((file = fopen(filename, "r")) == NULL) {
				log_warn("Couldn't open file '%s'", filename);
				continue;
			}
			read = fscanf(file, "%d %*s %*c %d", &pid, &ppid);
			fclose(file);
			if (read != 2) {
				continue;
			}
			if (ppid == parent) {
				found_pid = pid;
			}
		}
	}
	check(errno == 0, "Failed to read /proc");
	check(closedir(proc) == 0, "failed to closedir()");
	debug("Found pid: %d", found_pid);
error:
	return found_pid;
}

char *get_pid_for_tmux_cmd(char *input, const char *tmux_cmd)
{
	debug("Find pid in input '%s' prefixed with tmux_cmd: '%s'", input, tmux_cmd);
	char *delim = NULL, *token = strtok(input, TMUX_CMD_PID_TOKEN_DELIMITER);
	while (token != NULL) {
		debug("token = %s", token);
		delim = strchr(token, ':');
		check(delim, "Invalid input format: '%s'", token);
		*delim = '\0';
		if (!strcmp(token, tmux_cmd)) {
			debug("Found command '%s' with value '%s'", token, delim + 1);
			return delim + 1;
		}
		token = strtok(NULL, TMUX_CMD_PID_TOKEN_DELIMITER);
	}
error:
	return NULL;
}

int main(int argc, char **argv)
{
	char *command = NULL, *arg, buf[BUFFER_SIZE], *input = NULL, *pid_in = NULL, *tmux_cmd = NULL;
	size_t size = 0;
	int retval = 1, index = NO_INDEX, child_pid;

#ifdef LOG_ARGS
	FILE *log = fopen("/tmp/pidcmd.log", "w");
	check_mem(log);
	for (int i = 0; i < argc; i++) {
		fprintf(log, "argv[%d]=%s\n", i, argv[i]);
	}
	fclose(log);
#endif

	while (argc > 1 && *argv[1] == '-') {
		debug("argc: %d, argv[1]: '%s', argv[2]: '%s'", argc, argv[1], (argc > 2) ? argv[2] : "n/a");
		if (!strcmp(argv[1], "-h") || !strcmp(argv[1], "--help")) {
			puts(doc_usage);
			puts(doc_help);
			return 0;
		} else if (!strcmp(argv[1], "-V") || !strcmp(argv[1], "--version")) {
			puts(PACKAGE_STRING);
			return 0;
		} else if (!strcmp(argv[1], "-a") || !strcmp(argv[1], "--arg")) {
			check(argc > 2, "%s requires an argument", argv[1]);
			index = atoi(argv[2]);
			argc--;
			argv++;
		} else if (!strcmp(argv[1], "--tmux-cmd")) {
			check(argc > 2, "%s requires an argument", argv[1]);
			tmux_cmd = argv[2];
			argc--;
			argv++;
		} else {
			log_info("Unknown option: '%s'", argv[1]);
			puts(doc_usage);
			puts("Try '" PACKAGE " --help' for more information");
			return 2;
		}
		argc--;
		argv++;
	}
	debug("after option parsing: argc: %d, argv[1]: %s", argc, (argc > 1) ? argv[1] : "n/a");

	if (argc < 2) {
		puts(doc_usage);
		puts("Try '" PACKAGE " --help' for more information");
		return 2;
	}
	input = argv[1];

	if (tmux_cmd) {
		pid_in = get_pid_for_tmux_cmd(input, tmux_cmd);
		check(pid_in, "Couldn't find command '%s' in input", tmux_cmd);
		pid_in = strpbrk(pid_in, "123456789");
	}
	else {
		pid_in = strpbrk(input, "123456789");
	}
	check(pid_in, "Numbers not found in input: '%s'", input);

	child_pid = get_child_pid(atoi(pid_in));
	check(child_pid, "Child process not found for %s", pid_in);

	size = get_proc_cmdline(child_pid, buf, BUFFER_SIZE);
	check(size, "Nothing read from cmdline file");

	command = strndup_replace(buf, size, '\0', ' ');
	check_mem(command);

	if (index != NO_INDEX) {
		if ((arg = cmdline_arg(buf, size, index)) == NULL) {
			sentinel("No argument with index '%d' in command line '%s'", index,
			         command);
		}
		printf("%s\n", arg);
	} else {
		printf("%s\n", command);
	}

	retval = 0;
error:
	free(command);
	return retval;
}
