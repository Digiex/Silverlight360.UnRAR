#ifndef UNRAR360_RUNTIME_H
#define UNRAR360_RUNTIME_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Sets up the C and C++ runtime, with a heap of up to heap_bytes; once, before any other call. 0, or an NTSTATUS.
int32_t unrar360_init(uint32_t heap_bytes);

// The heap's committed bytes, now and at most since unrar360_init.
uint32_t unrar360_heap_committed(void);
uint32_t unrar360_heap_peak(void);

#ifdef __cplusplus
}
#endif

#endif
