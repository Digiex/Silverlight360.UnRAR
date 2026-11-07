// The POSIX calls UnRAR's Unix build makes that xsdk doesn't link (xsdk docs/GUIDE.md, "Porting: the C and POSIX
// calls"), each doing what the console allows. What it can't do fails with ENOSYS, which UnRAR reports and goes past:
// owners and times aren't restored, and an extracted file keeps the time it was written. xsdk has rmdir and chmod
// (the read-only attribute) of its own.
#include <errno.h>
#include <grp.h>
#include <pwd.h>
#include <stddef.h>
#include <sys/stat.h>
#include <sys/times.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#include "compat.h"

struct timespec;

// The console has no links, so a path's status is its own.
int lstat(const char *path, struct stat *status)
{
	return stat(path, status);
}

// The console has one user, so UnRAR's root.
uid_t geteuid(void)
{
	return 0;
}

// newlib's clock() counts the process's user and system ticks from these; the monotonic clock stands in for both.
clock_t times(struct tms *buffer)
{
	struct timespec now;
	if (clock_gettime(CLOCK_MONOTONIC, &now) != 0)
		return (clock_t)-1;
	const clock_t ticks = (clock_t)(now.tv_sec * CLOCKS_PER_SEC + now.tv_nsec / (1000000000 / CLOCKS_PER_SEC));
	if (buffer)
		*buffer = (struct tms){ .tms_utime = ticks };
	return ticks;
}

int lchown(const char *path, uid_t owner, gid_t group)
{
	(void)path;
	(void)owner;
	(void)group;
	errno = ENOSYS;
	return -1;
}

struct passwd *getpwnam(const char *name)
{
	(void)name;
	errno = ENOENT;
	return NULL;
}

struct group *getgrnam(const char *name)
{
	(void)name;
	errno = ENOENT;
	return NULL;
}

int utimensat(int directory, const char *path, const struct timespec times[2], int flags)
{
	(void)directory;
	(void)path;
	(void)times;
	(void)flags;
	errno = ENOSYS;
	return -1;
}

int flock(int fd, int operation)
{
	(void)fd;
	(void)operation;
	errno = ENOSYS;
	return -1;
}

int dup(int fd)
{
	(void)fd;
	errno = ENOSYS;
	return -1;
}
