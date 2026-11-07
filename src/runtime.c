// The runtime xsdk's title start sets up (xsdk src/start.c), set up instead by unrar360_init, as a DLL in another title's
// process has no start of its own. Its heap is bounded, as xsdk's grows into all the title's free memory (xsdk
// src/sbrk.c) and this process belongs to the Silverlight runtime.
#include <errno.h>
#include <stddef.h>
#include <stdint.h>
#include <sys/types.h>
#include <time.h>

#include "export.h"
#include "runtime.h"
#include "xsdk/kernel.h"
#include "xsdk/log.h"

enum {
	HEAP_COMMIT_BYTES = 64 * 1024,
};

// xsdk's start-up pieces (xsdk src/lock_private.h, pthread_private.h, reent_private.h, system_private.h).
void xsdk_lock_init(void);
void xsdk_pthread_init(void);
void xsdk_reent_init(void);

// Bounds that unrar360.ld defines.
extern void (*__preinit_array_start[])(void);
extern void (*__preinit_array_end[])(void);
extern void (*__init_array_start[])(void);
extern void (*__init_array_end[])(void);
extern const char __eh_frame_start[];

// libgcc's unwinder (unwind-dw2-fde.h); UnRAR reports errors by throwing, so the DLL registers its frames.
void __register_frame_info(const void *begin, void *object);
static uint32_t eh_frame_object[16];

// __cxa_atexit names the image by this. Defined here, so xsdk's start.o, which wants a main, isn't linked.
void *__dso_handle = &__dso_handle;

void *sbrk(ptrdiff_t increment);

static uintptr_t heap_base;
static uintptr_t heap_end;
static uintptr_t heap_break;
static uintptr_t heap_committed;
static uintptr_t heap_peak;
static int started;

static NTSTATUS reserve_heap(uint32_t size_bytes)
{
	size_bytes = (size_bytes + HEAP_COMMIT_BYTES - 1) & ~(uint32_t)(HEAP_COMMIT_BYTES - 1);
	void *base = NULL;
	NTSTATUS status = NtAllocateVirtualMemory(&base, &size_bytes, MEM_RESERVE, PAGE_READWRITE, 0);
	if (!NT_SUCCESS(status))
		return status;
	heap_base = (uintptr_t)base;
	heap_end = heap_base + size_bytes;
	heap_break = heap_base;
	heap_committed = heap_base;
	heap_peak = heap_base;
	return status;
}

// As xsdk's sbrk, in the room unrar360_init reserved.
void *sbrk(ptrdiff_t increment)
{
	if (!heap_base || (increment > 0 && (uintptr_t)increment > heap_end - heap_break)) {
		errno = ENOMEM;
		return (void *)-1;
	}
	if (increment < 0 && 0 - (uintptr_t)increment > heap_break - heap_base) {
		errno = EINVAL;
		return (void *)-1;
	}
	const uintptr_t new_break = heap_break + increment;
	if (new_break > heap_committed) {
		void *base = (void *)heap_committed;
		uint32_t bytes = (new_break - heap_committed + HEAP_COMMIT_BYTES - 1) & ~(uint32_t)(HEAP_COMMIT_BYTES - 1);
		if (!NT_SUCCESS(NtAllocateVirtualMemory(&base, &bytes, MEM_COMMIT, PAGE_READWRITE, 0))) {
			errno = ENOMEM;
			return (void *)-1;
		}
		heap_committed += bytes;
		if (heap_committed > heap_peak)
			heap_peak = heap_committed;
	}
	const uintptr_t kept_end = (new_break + HEAP_COMMIT_BYTES - 1) & ~(uintptr_t)(HEAP_COMMIT_BYTES - 1);
	if (kept_end < heap_committed) {
		void *base = (void *)kept_end;
		uint32_t bytes = heap_committed - kept_end;
		if (NT_SUCCESS(NtFreeVirtualMemory(&base, &bytes, MEM_DECOMMIT, 0)))
			heap_committed = kept_end;
	}
	void *old_break = (void *)heap_break;
	heap_break = new_break;
	return old_break;
}

int32_t unrar360_init(uint32_t heap_bytes)
{
	if (started)
		return 0;
	const NTSTATUS status = reserve_heap(heap_bytes);
	if (!NT_SUCCESS(status))
		return status;
	xsdk_lock_init();
	xsdk_pthread_init();
	xsdk_reent_init();
	// The log is the host title's, <title>.log in game:\, where game: can be written.
	(void)xsdk_log_open();
	// No time zone, which xsdk's start sets (xsdk src/system.c): the DLL sets no file times, and xenia-edge has no
	// GetTimeZoneInformation.
	__register_frame_info(__eh_frame_start, eh_frame_object);
	for (void (**function)(void) = __preinit_array_start; function < __preinit_array_end; function++)
		(*function)();
	for (void (**function)(void) = __init_array_start; function < __init_array_end; function++)
		(*function)();
	started = 1;
	xsdk_log_write("unrar360: started, a heap of up to %u MB at 0x%08X", (unsigned)((heap_end - heap_base) >> 20),
		(unsigned)heap_base);
	return 0;
}

uint32_t unrar360_heap_committed(void)
{
	return heap_committed - heap_base;
}

uint32_t unrar360_heap_peak(void)
{
	return heap_peak - heap_base;
}

// newlib's exit and abort end in these. xsdk's take the title back to the dashboard (xsdk src/exit.c), and the title
// here is the Silverlight host, so a fatal error in the DLL parks the thread it happened on instead: the extraction
// never returns, and the log says why.
enum {
	PROCESS_ID = 1,
};

void _exit(int status)
{
	xsdk_log_write("unrar360: exit %d; this thread stops here", status);
	for (;;) {
		struct timespec hour = { .tv_sec = 3600 };
		(void)nanosleep(&hour, NULL);
	}
}

pid_t getpid(void)
{
	return PROCESS_ID;
}

int kill(pid_t pid, int signal)
{
	if (pid != PROCESS_ID) {
		errno = ESRCH;
		return -1;
	}
	xsdk_log_write("unrar360: signal %d", signal);
	_exit(128 + signal);
}

// The loader calls this as DllMain (xenia:src/xenia/kernel/kernel_state.cc:783). The runtime waits for unrar360_init,
// outside the loader.
uint32_t unrar360_entry(void *module, uint32_t reason, void *reserved)
{
	(void)module;
	(void)reason;
	(void)reserved;
	return 1;
}

UNRAR360_EXPORT(2, unrar360_init);
UNRAR360_EXPORT(4, unrar360_heap_committed);
UNRAR360_EXPORT(5, unrar360_heap_peak);
