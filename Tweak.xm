#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <sys/sysctl.h>

// --- SPOOFING DE AMBIENTE ---
static int (*old_sysctlbyname)(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen);
static int new_sysctlbyname(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    if (strcmp(name, "hw.machine") == 0) {
        if (oldp) strcpy((char *)oldp, "iPhone10,1"); // Fingindo ser um iPhone 8 (mais fácil de enganar)
        return 0;
    }
    return old_sysctlbyname(name, oldp, oldlenp, newp, newlen);
}

// --- MÁSCARA DE PROCESSO ---
static NSDictionary *(*old_environment)(id self, SEL _cmd);
static NSDictionary *new_environment(id self, SEL _cmd) {
    return @{}; // Esconde qualquer variável de ambiente de Jailbreak
}

// --- BLOQUEIO DE CRASH ---
static void new_exit(int status) { NSLog(@"[MartinsGod] Bloqueado exit"); return; }
static void new_abort(void) { NSLog(@"[MartinsGod] Bloqueado abort"); return; }

// --- INICIALIZAÇÃO SUPREMA ---
static void __attribute__((constructor)) init() {
    NSLog(@"[MartinsGod] ATIVANDO LOBOTOMIA NO FILZA...");

    // Engana o hardware e o sistema
    MSHookFunction((void *)sysctlbyname, (void *)new_sysctlbyname, (void **)&old_sysctlbyname);
    MSHookMessageEx([NSProcessInfo class], @selector(environment), (IMP)new_environment, (IMP *)&old_environment);
    
    // Bloqueia o fechamento forçado
    MSHookFunction((void *)exit, (void *)new_exit, NULL);
    MSHookFunction((void *)abort, (void *)new_abort, NULL);

    // Hook no UIDevice para fingir iOS 14.0 (muito mais estável para o Filza)
    MSHookMessageEx([UIDevice class], @selector(systemVersion), (IMP)^NSString *(id self){ return @"14.0"; }, NULL);
}
