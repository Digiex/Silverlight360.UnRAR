// Forced into each UnRAR file (-include): what its Unix build expects that newlib's headers leave out. src/posix.c
// defines the calls.
#ifndef UNRAR360_COMPAT_H
#define UNRAR360_COMPAT_H

#include <sys/stat.h>

#ifdef __cplusplus
extern "C" {
#endif

int lstat(const char *path, struct stat *status);

#ifdef __cplusplus
}
#endif

// utimensat's "leave this time" (POSIX); src/posix.c's utimensat sets no time at all.
#ifndef UTIME_NOW
#define UTIME_NOW ((1L << 30) - 1L)
#define UTIME_OMIT ((1L << 30) - 2L)
#endif

#endif
