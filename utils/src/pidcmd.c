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
static char doc[] = "Usage: " PACKAGE " PID|- [argument]\n\n"
"Get an argument of the command line for a given PIDs child process.\n"
"Example:\n\n"
"  # second to last command line argument of pid 123's child\n"
"  pidcmd 123 -2\n"
"  # first argument (read from stdin)\n"
"  echo 123 | pidcmd - 0\n"
"  # full command line\n"
"  pidcmd 123\n"
"\nVersion: " PACKAGE_STRING;
static const int MAX_FILENAME_LEN = 32;
static const int NO_INDEX = INT_MAX;
static const int MAX_CMDLINE_ARGS = 32;
static const size_t BUFFER_SIZE = 256;

/**
 * Return pointer to a malloc'ed copy of 's', where occurences or 'search' are
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
		check_debug(abs(index) <= i, "No argument at index '%d' (got %d arguments)", index, i);
		return args[i + index];
	}
	check_debug(index < i, "No argument at index '%d' (got %d arguments)", index, i);
	return args[index];
error:
	return NULL;
}

/*
 * Gived a `pid`, read at most n bytes from the file /proc/pid/cmdline into the
 * buffer pointed to by cmdline.
 */
size_t get_cmdline(int pid, char *cmdline, size_t n)
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
 * Read a line from the stream `input` and return a pointer to the initial
 * portion of the string that consists of digits, possibly prefixed with
 * spaces. The resulting string is null terminated.
 * It is the callers responsibility to free() the pointer.
 */
char *getline_numeric(FILE *input)
{
	char *lineptr = NULL, *p;
	size_t size = 0;
	ssize_t read_n;
	read_n = getline(&lineptr, &size, input);
	check(read_n != -1, "Failed to read from stdin");
	p = lineptr;
	while (isdigit(*p) || *p == ' ')
		p++;
	*p = '\0';
error:
	return lineptr;
}

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
	char filename[MAX_FILENAME_LEN], buf[BUFFER_SIZE], *lineptr;;
	FILE *file;
	struct dirent *dir;
	int pid, ppid, found_pid = 0, read;

	check_mem(proc);
	while((dir = readdir(proc)) != NULL && !found_pid) {
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

int main(int argc, const char **argv)
{
	char *command = NULL, *arg, buf[256], *input = NULL, *pid_in;
	size_t size = 0;
	int retval = 1, index = NO_INDEX, child_pid;

	if (argc < 2 || strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0) {
		puts(doc);
		return 0;
	}
	if (strcmp(argv[1], "-V") == 0 || strcmp(argv[1], "--version") == 0) {
		puts(PACKAGE_STRING);
		return 0;
	}

	if (strcmp(argv[1], "-") == 0) {
		debug("Read pid from stdin");
		input = getline_numeric(stdin);
		check(input != NULL, "Failed to read pid from stdin");
	}
	else {
		input = (char *)argv[1];
	}
	pid_in = strpbrk(input, "123456789");
	check(pid_in, "Numbers not found in input: '%s'", input);

	child_pid = get_child_pid(atoi(pid_in));
	if (input && strcmp(argv[1], "-") == 0)
		free(pid_in);
	check(child_pid, "Child process not found for %s", pid_in);

	if (argc >= 3) {
		index = atoi(argv[2]);
	}

	size = get_cmdline(child_pid, buf, BUFFER_SIZE);
	if (!size)
		goto error;

	command = strndup_replace(buf, size, '\0', ' ');
	check_mem(command);

	if (index != NO_INDEX) {
		if ((arg = cmdline_arg(buf, size, index)) == NULL) {
			sentinel("No argument with index '%d' in command line '%s'", index, command);
		}
		printf("%s\n", arg);
	}
	else {
		printf("%s\n", command);
	}


	retval = 0;
error:
	free(command);
	return retval;
}
