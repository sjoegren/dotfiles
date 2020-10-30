#ifndef __debug_h__
#define __debug_h__

#include <errno.h>
#include <stdio.h>
#include <string.h>

/* Don't print debug() messages when NDEBUG is defined. */
#ifdef NDEBUG
#define debug(M, ...)
#else
#define debug(M, ...) fprintf(stderr, "[DEBUG] %s:%d: " M "\n", \
	__FILE__, __LINE__, ##__VA_ARGS__)
#endif /* NDEBUG */

#define clean_errno() (errno == 0 ? "None" : strerror(errno))

#define log_err(M, ...) fprintf(stderr, "[ERROR] (%s:%d: errno: %s) " M "\n", \
	__FILE__, __LINE__, clean_errno(), ##__VA_ARGS__)

#define log_warn(M, ...) fprintf(stderr, "[WARNING] (%s:%d: errno: %s) " M "\n", \
	__FILE__, __LINE__, clean_errno(), ##__VA_ARGS__)

#define log_info(M, ...) fprintf(stderr, "[INFO] (%s:%d) " M "\n", \
	__FILE__, __LINE__, ##__VA_ARGS__)

#define check(A, M, ...) if(!(A)) { \
	log_err(M, ##__VA_ARGS__); errno = 0; goto error; }

#define check_debug(A, M, ...) if (!(A)) { \
	debug(M, ##__VA_ARGS__); errno = 0; goto error; }

#define sentinel(M, ...) { log_err(M, ##__VA_ARGS__); errno=0; goto error; }

#define check_mem(A) check((A != NULL), "Out of memory.")

#endif /* __debug_h__ */
