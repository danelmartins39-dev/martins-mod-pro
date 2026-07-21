#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>

// --- MÁSCARA DE VERSÃO ---
static NSString *(*old_systemVersion)(id self, SEL _cmd);
static NSString *new_systemVersion(id self, SEL _cmd) {
    return @"15.0"; // Engana o app fazendo-o pensar que é iOS antigo
}

// --- BYPASS DE CRASH ---
static void (*old_exit)(int status);
static void new_exit(int status) {
    return; // Impede o app de fechar
}

static void (*old_abort)(void);
static void new_abort(void) {
    return; // Impede o app de abortar
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
    // Aplica o Hook na versão do sistema
    MSHookMessageEx([UIDevice class], @selector(systemVersion), (IMP)new_systemVersion, (IMP *)&old_systemVersion);

    // Aplica os Hooks de segurança
    MSHookFunction((void *)exit, (void *)new_exit, (void **)&old_exit);
    MSHookFunction((void *)abort, (void *)new_abort, (void **)&old_abort);
    MSHookFunction((void *)open, (void *)new_open, (void **)&old_open);
}
