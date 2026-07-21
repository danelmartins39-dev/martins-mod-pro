#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <sys/sysctl.h>

// --- SPOOFING DE HARDWARE ---
static int (*old_sysctlbyname)(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen);
static int new_sysctlbyname(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    if (name && strcmp(name, "hw.machine") == 0) {
        if (oldp && oldlenp && *oldlenp >= 11) {
            strcpy((char *)oldp, "iPhone10,1"); // Fingindo ser iPhone 8
            *oldlenp = 11;
            return 0;
        }
    }
    return old_sysctlbyname(name, oldp, oldlenp, newp, newlen);
}

// --- MÁSCARA DE AMBIENTE ---
static NSDictionary *(*old_environment)(id self, SEL _cmd);
static NSDictionary *new_environment(id self, SEL _cmd) {
    return @{}; // Limpa rastros de Jailbreak
}

// --- MÁSCARA DE VERSÃO ---
static NSString *new_systemVersion(id self, SEL _cmd) {
    return @"14.0"; // Fingindo iOS antigo e estável
}

// --- BLOQUEIO DE CRASH ---
static void new_exit(int status) { return; }
static void new_abort(void) { return; }

// --- INICIALIZAÇÃO SUPREMA ---
static void __attribute__((constructor)) init() {
    NSLog(@"[MartinsGod] INICIANDO BYPASS DE ELITE...");

    // Hook no Hardware
    MSHookFunction((void *)sysctlbyname, (void *)new_sysctlbyname, (void **)&old_sysctlbyname);
    
    // Hook no Processo
    MSHookMessageEx([NSProcessInfo class], @selector(environment), (IMP)new_environment, (IMP *)&old_environment);
    
    // Hook na Versão do iOS
    MSHookMessageEx([UIDevice class], @selector(systemVersion), (IMP)new_systemVersion, NULL);

    // Bloqueia Ordens de Fechamento
    MSHookFunction((void *)exit, (void *)new_exit, NULL);
    MSHookFunction((void *)abort, (void *)new_abort, NULL);
}
