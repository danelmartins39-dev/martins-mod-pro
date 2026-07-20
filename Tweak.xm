static void __attribute__((constructor)) init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                    window = ((UIWindowScene *)scene).windows.firstObject;
                    break;
                }
            }
        }
        
        // Se não encontrar via Scene, tenta o método tradicional (mas sem dar erro)
        if (!window) {
            window = [UIApplication sharedApplication].windows.firstObject;
        }
        
        if (window) {
            MartinsMenu *menu = [[MartinsMenu alloc] initWithFrame:CGRectMake(50, 150, 240, 180)];
            [window addSubview:menu];
        }
    });
}
