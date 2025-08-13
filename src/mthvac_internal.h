/* HVAC_Internal.h
 * 
 * These functions are separated out in case someone wants to use the API
 * directly. It's probably easiest to work through the close / fclose call
 * intercept though.
 * 
 */

#ifndef __HVAC_INTERNAL_H__
#define __HVAC_INTERNAL_H__

#include <stdio.h>
#include <unistd.h>
#include <stdarg.h> /* va_list, va_start, va_arg, va_end */
#include <stdlib.h>
#include <stdint.h> /* size specified data types */
#include <stdbool.h>
#include <fcntl.h>
#include <sys/uio.h>
#include <sys/mman.h>

// A version string.  Currently, it just gets written to the log file.
#define MT-HVAC_VERSION "0.0.1"

#ifdef HVAC_PRELOAD

#define REAL_DECL(func, ret, args) \
    extern ret (*__real_ ## func)args;

#define WRAP_DECL(__name) __name

#define MAP_OR_FAIL(func) \
    if (!(__real_ ## func)) \
    { \
        __real_ ## func = dlsym(RTLD_NEXT, #func); \
        if(!(__real_ ## func)) { \
            fprintf(stderr, "hvac failed to map symbol: %s\n", #func); \
            exit(1); \
        } \
    }

#else

#define REAL_DECL(func, ret, args) \
    extern ret __real_ ## func args;

#define WRAP_DECL(__name) __wrap_ ## __name

#define MAP_OR_FAIL(func)
#endif

// REAL_DECL(fopen, FILE *, (const char *path, const char *mode))
// REAL_DECL(fopen64, FILE *, (const char *path, const char *mode))
REAL_DECL(pread, ssize_t, (int fd, void *buf, size_t count, off_t offset))
// REAL_DECL(readv, ssize_t, (int fd, const struct iovec *iov, int iovcnt))
// REAL_DECL(write, ssize_t, (int fd, const void *buf, size_t count))
REAL_DECL(open, int, (const char *pathname, int flags, ...))
// REAL_DECL(open64, int, (const char *pathname, int flags, ...))
REAL_DECL(read, ssize_t, (int fd, void *buf, size_t count))
// REAL_DECL(read64, ssize_t, (int fd, void *buf, size_t count))
REAL_DECL(close, int, (int fd))
// REAL_DECL(lseek, off_t, (int fd, off_t offset, int whence))
// REAL_DECL(lseek64, off64_t, (int fd, off64_t offset, int whence))

#ifdef __cplusplus
extern "C" {
#endif

bool hvac_track_file(const char* path, int flags, int fd);
const char* hvac_get_path(int fd);
bool hvac_remove_fd(int fd);
ssize_t hvac_remote_read(int fd, void *buf, size_t count);
ssize_t hvac_remote_pread(int fd, void *buf, size_t count, off_t offset);
ssize_t hvac_remote_lseek(int fd, int offset, int whence);
void hvac_remote_close(int fd);
bool hvac_file_tracked(int fd);

#ifdef __cplusplus
}
#endif

#endif // __HVAC_INTERNAL_H__
