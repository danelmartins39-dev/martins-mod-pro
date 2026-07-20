#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>
#import <mach-o/dyld.h>
#import <sys/mman.h>

// --- CONFIGURAÇÕES DO SERVIDOR ---
#define API_URL @"http://187.127.45.32:5000/api/v1/check"
#define MENU_TITLE @"MARTINS MOD 👑"

@interface MartinsMenuV2 : UIView <UITextFieldDelegate>
@property (nonatomic, strong ) UIView *header;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIScrollView *contentView;
@property (nonatomic, strong) UITextField *keyField;
@property (nonatomic, strong) UIButton *actionBtn;
@property (nonatomic, strong) UIView *loginContainer;
@property (nonatomic, strong) UIView *hackContainer;
@end

@implementation MartinsMenuV2

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 20;
        self.layer.masksToBounds = YES;
        self.layer.borderWidth = 2.0;
        self.layer.borderColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0].CGColor; // Dourado Premium
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.92];
        
        // Efeito de Brilho Neon
        self.layer.shadowColor = [UIColor redColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 0);
        self.layer.shadowOpacity = 0.8;
        self.layer.shadowRadius = 10;
        
        [self setupHeader];
        [self setupLoginUI];
        
        // Gesto para Arrastar o Menu
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:panGesture];
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
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 44, self.frame.size.width, 1)];
    line.backgroundColor = [UIColor redColor];
    [self.header addSubview:line];
}

- (void)setupLoginUI {
    self.loginContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 45, self.frame.size.width, self.frame.size.height - 45)];
    [self addSubview:self.loginContainer];
    
    self.keyField = [[UITextField alloc] initWithFrame:CGRectMake(20, 40, self.loginContainer.frame.size.width - 40, 45)];
    self.keyField.placeholder = @"INSIRA SUA CHAVE VIP";
    self.keyField.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
    self.keyField.textColor = [UIColor whiteColor];
    self.keyField.textAlignment = NSTextAlignmentCenter;
    self.keyField.layer.cornerRadius = 10;
    self.keyField.layer.borderWidth = 1;
    self.keyField.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3].CGColor;
    self.keyField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.keyField.placeholder attributes:@{NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent:0.5]}];
    [self.loginContainer addSubview:self.keyField];
    
    self.actionBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 105, self.loginContainer.frame.size.width - 40, 45)];
    [self.actionBtn setTitle:@"ATIVAR ACESSO" forState:UIControlStateNormal];
    [self.actionBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.actionBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.actionBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0];
    self.actionBtn.layer.cornerRadius = 10;
    [self.actionBtn addTarget:self action:@selector(validateKey) forControlEvents:UIControlEventTouchUpInside];
    [self.loginContainer addSubview:self.actionBtn];
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self.superview];
}

- (void)validateKey {
    NSString *key = self.keyField.text;
    if ([key length] == 0) return;
    
    [self.actionBtn setTitle:@"VERIFICANDO..." forState:UIControlStateNormal];
    
    NSURL *url = [NSURL URLWithString:API_URL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *body = @{@"key": key};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    [request setHTTPBody:jsonData];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if ([json[@"status"] isEqualToString:@"success"]) {
                    [self.loginContainer removeFromSuperview];
                    [self setupHackUI];
                } else {
                    [self.actionBtn setTitle:@"CHAVE INVÁLIDA!" forState:UIControlStateNormal];
                    self.actionBtn.backgroundColor = [UIColor redColor];
                }
            } else {
                [self.actionBtn setTitle:@"ERRO DE CONEXÃO" forState:UIControlStateNormal];
            }
        });
    }];
    [task resume];
}

- (void)setupHackUI {
    // Expandir o menu para mostrar as funções
    [UIView animateWithDuration:0.3 animations:^{
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, 280, 450);
    }];
    
    self.hackContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 45, self.frame.size.width, self.frame.size.height - 45)];
    [self addSubview:self.hackContainer];
    
    self.contentView = [[UIScrollView alloc] initWithFrame:self.hackContainer.bounds];
    self.contentView.contentSize = CGSizeMake(self.hackContainer.frame.size.width, 600);
    [self.hackContainer addSubview:self.contentView];
    
    [self addOption:@"ESP ANTENNA" y:20];
    [self addOption:@"ESP LINE" y:80];
    [self addOption:@"ESP BOX" y:140];
    [self addOption:@"ESP DISTANCE" y:200];
    [self addOption:@"AIMBOT 360" y:260];
    [self addOption:@"AUTO HEADSHOT" y:320];
    [self addOption:@"NO RECOIL" y:380];
    [self addOption:@"SPEED HACK" y:440];
}

- (void)addOption:(NSString *)name y:(int)y {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(15, y, self.frame.size.width - 30, 50)];
    row.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.05];
    row.layer.cornerRadius = 12;
    row.layer.borderWidth = 0.5;
    row.layer.borderColor = [[UIColor redColor] colorWithAlphaComponent:0.3].CGColor;
    [self.contentView addSubview:row];
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 160, 50)];
    lbl.text = name;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont fontWithName:@"AvenirNext-Medium" size:14];
    [row addSubview:lbl];
    
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(row.frame.size.width - 60, 10, 0, 0)];
    sw.onTintColor = [UIColor redColor];
    sw.thumbTintColor = [UIColor whiteColor];
    [row addSubview:sw];
}

@end

// --- INICIALIZAÇÃO DO MENU ---
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
        if (!window) window = [UIApplication sharedApplication].windows.firstObject;
        
        if (window) {
            MartinsMenuV2 *menu = [[MartinsMenuV2 alloc] initWithFrame:CGRectMake(50, 100, 280, 200)];
            [window addSubview:menu];
        }
    });
}
