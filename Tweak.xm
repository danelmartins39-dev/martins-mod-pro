#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>

// --- CONFIGURAÇÕES ---
#define API_URL @"https://secretariat-bestsellers-economies-implemented.trycloudflare.com/api/v1/check"
#define MENU_TITLE @"MARTINS MOD 👑"

// --- ANTI-DETECTION SUPREMO ---
MSHook(void, _exit, int status ) {
    // Impede o jogo de fechar ao detectar
    return;
}

@interface MartinsMenuV2 : UIView <NSURLSessionDelegate>
@property (nonatomic, strong) UIView *header;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIScrollView *contentView;
@property (nonatomic, strong) UIView *loginContainer;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) NSString *expiryDate;
@end

@implementation MartinsMenuV2

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 20;
        self.layer.masksToBounds = YES;
        self.layer.borderWidth = 2.0;
        self.layer.borderColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0].CGColor;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.95];
        
        [self setupHeader];
        [self setupLoginUI];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:panGesture];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self checkClipboardAndLogin];
        });
    }
    return self;
}

- (void)setupHeader {
    self.header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 45)];
    self.header.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0];
    [self addSubview:self.header];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:self.header.bounds];
    self.titleLabel.text = MENU_TITLE;
    self.titleLabel.textColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Bold" size:18];
    [self.header addSubview:self.titleLabel];
}

- (void)setupLoginUI {
    self.loginContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 45, self.frame.size.width, self.frame.size.height - 45)];
    [self addSubview:self.loginContainer];
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 40, self.frame.size.width - 20, 60)];
    self.statusLabel.text = @"COPIE SUA KEY E ABRA O JOGO\nPARA LOGIN AUTOMÁTICO";
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [self.loginContainer addSubview:self.statusLabel];
}

- (void)checkClipboardAndLogin {
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    NSString *key = pb.string;
    if (key && key.length > 5) {
        [self validateKey:key];
    }
}

- (void)validateKey:(NSString *)key {
    self.statusLabel.text = @"VERIFICANDO ACESSO...";
    NSURL *url = [NSURL URLWithString:API_URL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:@{@"key": key} options:0 error:nil]];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if (json && [json[@"status"] isEqualToString:@"success"]) {
                    self.expiryDate = json[@"expiry"];
                    [self.loginContainer removeFromSuperview];
                    [self setupHackUI];
                } else {
                    self.statusLabel.text = @"KEY INVÁLIDA";
                }
            }
        });
    }] resume];
}

- (void)setupHackUI {
    [UIView animateWithDuration:0.3 animations:^{
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, 280, 480);
    }];
    UIView *hackView = [[UIView alloc] initWithFrame:CGRectMake(0, 45, self.frame.size.width, self.frame.size.height - 45)];
    [self addSubview:hackView];
    
    UILabel *expiryLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, self.frame.size.width, 20)];
    expiryLbl.text = [NSString stringWithFormat:@"VALIDADE: %@", [self formatExpiryDate:self.expiryDate]];
    expiryLbl.textColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0];
    expiryLbl.font = [UIFont boldSystemFontOfSize:10];
    expiryLbl.textAlignment = NSTextAlignmentCenter;
    [hackView addSubview:expiryLbl];
    
    self.contentView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 30, self.frame.size.width, hackView.frame.size.height - 30)];
    self.contentView.contentSize = CGSizeMake(self.frame.size.width, 500);
    [hackView addSubview:self.contentView];
    
    [self addOption:@"ESP ANTENNA" y:10];
    [self addOption:@"AIMBOT 360" y:70];
    [self addOption:@"AUTO HEADSHOT" y:130];
    [self addOption:@"SPEED HACK" y:190];
}

- (NSString *)formatExpiryDate:(NSString *)isoDate {
    if (!isoDate || isoDate.length < 10) return @"PERMANENTE";
    return [isoDate substringToIndex:10];
}

- (void)addOption:(NSString *)name y:(int)y {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(15, y, self.frame.size.width - 30, 50)];
    row.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.05];
    row.layer.cornerRadius = 12;
    [self.contentView addSubview:row];
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 160, 50)];
    lbl.text = name;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    [row addSubview:lbl];
    
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(row.frame.size.width - 60, 10, 0, 0)];
    sw.onTintColor = [UIColor redColor];
    [row addSubview:sw];
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self.superview];
}

@end

static MartinsMenuV2 *mainMenu;

@interface UIWindow (MartinsGesto)
@end

@implementation UIWindow (MartinsGesto)
- (void)martinsHandleTap:(UITapGestureRecognizer *)gesture {
    if (mainMenu) {
        mainMenu.hidden = !mainMenu.hidden;
    }
}
@end

static void __attribute__((constructor)) init() {
    // ANTI-DETECTION: Bypass exit
    MSHookFunction((void *)exit, (void *)_exit, (void **)&_exit);
    
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
        if (!window) window = [UIApplication sharedApplication].windows.firstObject;
        
        if (window) {
            mainMenu = [[MartinsMenuV2 alloc] initWithFrame:CGRectMake(50, 100, 280, 200)];
            [window addSubview:mainMenu];
            
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:window action:@selector(martinsHandleTap:)];
            tap.numberOfTapsRequired = 2;
            tap.numberOfTouchesRequired = 3;
            [window addGestureRecognizer:tap];
        }
    });
}
