#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>
#import <mach-o/dyld.h>
#import <sys/mman.h> // ADICIONADO PARA CORRIGIR O ERRO PROT_READ

// --- CONFIGURAÇÕES DO SERVIDOR ---
#define API_URL @"http://187.127.45.32:5000/api/v1/check"

@interface MartinsMenu : UIView
@property (nonatomic, strong ) UIView *header;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UITextField *keyField;
@property (nonatomic, strong) UIButton *loginBtn;
@end

@implementation MartinsMenu

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLoginUI];
    }
    return self;
}

- (void)setupLoginUI {
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.9];
    self.layer.cornerRadius = 15;
    self.layer.borderWidth = 1.5;
    self.layer.borderColor = [UIColor redColor].CGColor;
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, self.frame.size.width, 30)];
    title.text = @"MARTINS MOD PRO";
    title.textColor = [UIColor redColor];
    title.textAlignment = NSTextAlignmentCenter;
    title.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
    [self addSubview:title];
    
    self.keyField = [[UITextField alloc] initWithFrame:CGRectMake(20, 60, self.frame.size.width - 40, 40)];
    self.keyField.placeholder = @"DIGITE SUA KEY";
    self.keyField.backgroundColor = [UIColor whiteColor];
    self.keyField.layer.cornerRadius = 5;
    self.keyField.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.keyField];
    
    self.loginBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 110, self.frame.size.width - 40, 40)];
    [self.loginBtn setTitle:@"ENTRAR" forState:UIControlStateNormal];
    self.loginBtn.backgroundColor = [UIColor redColor];
    self.loginBtn.layer.cornerRadius = 5;
    [self.loginBtn addTarget:self action:@selector(validateKey) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.loginBtn];
}

- (void)validateKey {
    NSString *key = self.keyField.text;
    if ([key length] == 0) return;
    
    NSURL *url = [NSURL URLWithString:API_URL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *body = @{@"key": key};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    [request setHTTPBody:jsonData];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([json[@"status"] isEqualToString:@"success"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setupHackUI];
                });
            }
        }
    }];
    [task resume];
}

- (void)setupHackUI {
    for (UIView *v in self.subviews) [v removeFromSuperview];
    
    self.frame = CGRectMake(50, 100, 260, 350);
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.85];
    self.layer.borderColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0].CGColor;
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 40)];
    title.text = @"MARTINS - MENU";
    title.textColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0];
    title.textAlignment = NSTextAlignmentCenter;
    title.font = [UIFont boldSystemFontOfSize:18];
    [self addSubview:title];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 40, self.frame.size.width, self.frame.size.height - 40)];
    [self addSubview:self.scrollView];
    
    [self addToggle:@"ESP ANTENNA" y:10];
    [self addToggle:@"ESP LINE" y:60];
    [self addToggle:@"AIMBOT" y:110];
    [self addToggle:@"NO RECOIL" y:160];
}

- (void)addToggle:(NSString *)name y:(int)y {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(10, y, self.frame.size.width - 20, 40)];
    row.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
    row.layer.cornerRadius = 8;
    [self.scrollView addSubview:row];
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 150, 40)];
    lbl.text = name;
    lbl.textColor = [UIColor whiteColor];
    [row addSubview:lbl];
    
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(row.frame.size.width - 60, 5, 0, 0)];
    sw.onTintColor = [UIColor redColor];
    [row addSubview:sw];
}

@end

// --- LÓGICA DE PATCH ---
void patch_memory(uint64_t address, const void *data, size_t size) {
    uint64_t page_start = address & ~0xFFF;
    mprotect((void *)page_start, 0x1000, PROT_READ | PROT_WRITE | PROT_EXEC);
    memcpy((void *)address, data, size);
    mprotect((void *)page_start, 0x1000, PROT_READ | PROT_EXEC);
}

static void __attribute__((constructor)) init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *windowScene in [UIApplication sharedApplication].connectedScenes) {
                if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                    window = windowScene.windows.firstObject;
                    break;
                }
            }
        } else {
            window = [UIApplication sharedApplication].keyWindow;
        }
        
        if (window) {
            MartinsMenu *menu = [[MartinsMenu alloc] initWithFrame:CGRectMake(50, 150, 240, 180)];
            [window addSubview:menu];
        }
    });
}
