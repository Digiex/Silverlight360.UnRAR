// Extraction through UnRAR's own library interface (third_party/unrar/dll.hpp), for an app that passes paths and reads
// progress from memory it pins.
#include <stdint.h>
#include <string.h>

#include <memory>
#include <string>

#include "export.h"
#include "runtime.h"
#include "xsdk/log.h"

#include "dll.hpp"

namespace {

enum {
	API_VERSION = 1,
	NAME_BYTES = 256,
	MESSAGE_BYTES = 256,
};

// What the app passes to watch and stop an extraction, big-endian as every field here is. The app sets cancel; the
// rest is the DLL's, written as it goes.
struct Progress {
	volatile uint32_t cancel;
	volatile uint32_t files;
	volatile uint64_t bytes;
	char name[NAME_BYTES];
	char message[MESSAGE_BYTES];
};

// The console's paths are 8-bit; each byte becomes its own character, and back.
std::wstring widen(const char *text)
{
	std::wstring wide;
	for (; *text; text++)
		wide += (wchar_t)(unsigned char)*text;
	return wide;
}

void narrow(const wchar_t *wide, char *text, size_t bytes)
{
	size_t i = 0;
	for (; wide[i] && i + 1 < bytes; i++)
		text[i] = wide[i] < 0x100 ? (char)wide[i] : '?';
	text[i] = '\0';
}

int CALLBACK callback(UINT message, LPARAM user_data, LPARAM p1, LPARAM p2)
{
	Progress *progress = (Progress *)user_data;
	(void)p1;
	switch (message) {
	case UCM_PROCESSDATA:
		progress->bytes += (uint32_t)p2;
		return progress->cancel ? -1 : 1;
	case UCM_CHANGEVOLUME:
	case UCM_CHANGEVOLUMEW:
		// Notified of the next volume, go on; asked for one that isn't beside the first, stop.
		return p2 == RAR_VOL_NOTIFY ? 1 : -1;
	case UCM_LARGEDICT:
		// The bounded heap decides: a dictionary that doesn't fit fails as ERAR_NO_MEMORY.
		return 1;
	default:
		// A password the app didn't give.
		return -1;
	}
}

} // namespace

extern "C" {

uint32_t unrar360_version(void)
{
	return API_VERSION << 16 | (uint32_t)RARGetDllVersion();
}

// Extracts every file of archive into destination, keeping the archive's folders. Paths are the console's, such as
// "hdd:\\Games\\a.rar" or "game:\\a.rar"; password may be null. Returns 0, or one of dll.hpp's ERAR_ codes.
int32_t unrar360_extract(const char *archive, const char *destination, const char *password, Progress *progress)
{
	memset(progress->name, 0, sizeof(progress->name));
	memset(progress->message, 0, sizeof(progress->message));
	std::wstring archive_name = widen(archive);
	std::wstring destination_name = widen(destination);

	RAROpenArchiveDataEx open = {};
	open.ArcNameW = archive_name.data();
	open.OpenMode = RAR_OM_EXTRACT;
	open.Callback = callback;
	open.UserData = (LPARAM)progress;
	HANDLE handle = RAROpenArchiveEx(&open);
	if (!handle) {
		xsdk_log_write("unrar360: can't open %s: %u", archive, open.OpenResult);
		return (int32_t)open.OpenResult;
	}
	if (password)
		RARSetPassword(handle, (char *)password);

	// About 14 KB, too much for the caller's stack.
	auto header = std::make_unique<RARHeaderDataEx>();
	int result;
	while ((result = RARReadHeaderEx(handle, header.get())) == ERAR_SUCCESS) {
		narrow(header->FileNameW, progress->name, sizeof(progress->name));
		result = RARProcessFileW(handle, RAR_EXTRACT, destination_name.data(), nullptr);
		if (result != ERAR_SUCCESS)
			break;
		progress->files++;
	}
	if (result == ERAR_END_ARCHIVE)
		result = ERAR_SUCCESS;
	else
		snprintf(progress->message, sizeof(progress->message), "%s: error %d", progress->name, result);
	RARCloseArchive(handle);
	xsdk_log_write("unrar360: %s into %s: %d, %u entries, %llu bytes, heap peak %u KB", archive, destination, result,
		(unsigned)progress->files, (unsigned long long)progress->bytes, (unsigned)(unrar360_heap_peak() >> 10));
	return result;
}

} // extern "C"

UNRAR360_EXPORT(1, unrar360_version);
UNRAR360_EXPORT(3, unrar360_extract);
