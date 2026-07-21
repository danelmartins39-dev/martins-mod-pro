#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>

// --- MÁSCARA DE VERSÃO ---
// Hook para enganar o app fazendo-o pensar que está no iOS 15.0
static NSString *(*old_systemVersion)(id self, SEL _cmd);
static NSString *new_systemVersion(id self, SEL _cmd) {
    return @"15.0";
}

// --- BYPASS DE CRASH (ESCUDO) ---
// Impede que o app seja encerrado por erros de permissão
static void (*old_exit)(int status);
static void new_exit(int status) {
    NSLog(@"[MartinsBypass] Bloqueada tentativa de fechar (exit)");
    return;
}

static void (*old_abort)(void);
static void new_abort(void) {
    NSLog(@"[MartinsBypass] Bloqueada tentativa de abortar (abort)");
    return;
}

// --- REDIRECIONAMENTO DE SEGURANÇA ---
// Se o app tentar acessar pastas proibidas, nós o enviamos para um lugar seguro
static int (*old_open)(const char *path, int oflag, ...);
static int new_open(const char *path, int oflag, mode_t mode) {
    if (path && (strstr(path, "/var/root") || strstr(path, "/var/mobile/Library"))) {
        NSLog(@"[MartinsBypass] Redirecionando acesso sensível: %s", path);
        // Redireciona para a pasta temporária do próprio app
        return old_open("/tmp", oflag, mode);
    }
    return old_open(path, oflag, mode);
}

// --- INICIALIZAÇÃO DO ESCUDO ---
static void __attribute__((constructor)) init() {
    NSLog(@"[MartinsBypass] ATIVANDO ESCUDO SUPREMO NO iOS 27...");

    // Hook no UIDevice para mudar a versão do iOS
    MSHookMessageEx([UIDevice class], @selector(systemVersion), (IMP)new_systemVersion, (IMP *)&old_systemVersion);

    // Hook nas funções de sistema para evitar o crash
    MSHookFunction((void *)exit, (void *)new_exit, (void **)&old_exit);
    MSHookFunction((void *)abort, (void *)new_abort, (void **)&old_abort);
    MSHookFunction((void *)open, (void *)new_open, (void **)&old_open);
}
