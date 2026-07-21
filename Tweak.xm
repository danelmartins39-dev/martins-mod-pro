#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>

// --- MÁSCARA DE VERSÃO ---
static NSString *(*old_systemVersion)(id self, SEL _cmd);
static NSString *new_systemVersion(id self, SEL _cmd) {
    return @"15.0";
}

// --- BYPASS DE CRASH ---
static void (*old_exit)(int status);
static void new_exit(int status) {
    return;
}

static void (*old_abort)(void);
static void new_abort(void) {
    return;
}

// --- REDIRECIONAMENTO ---
static int (*old_open)(const char *path, int oflag, mode_t mode);
static int new_open(const char *path, int oflag, mode_t mode) {
    if (path && strstr(path, "/var/root")) {
        return old_open("/tmp", oflag, mode);
    }
    return old_open(path, oflag, mode);
}

static void __attribute__((constructor)) init() {
    // Hook UIDevice para fingir iOS 15
    MSHookMessageEx([UIDevice class], @selector(systemVersion), (IMP)new_systemVersion, (IMP *)&old_systemVersion);

    // Hook nas funções de saída para evitar crash
    MSHookFunction((void *)exit, (void *)new_exit, (void **)&old_exit);
    MSHookFunction((void *)abort, (void *)new_abort, (void **)&old_abort);
    MSHookFunction((void *)open, (void *)new_open, (void **)&old_open);
}
