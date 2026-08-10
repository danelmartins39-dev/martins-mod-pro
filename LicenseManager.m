//
//  LicenseManager.m
//  Sistema de Licenciamento para iOS
//
//  Gerencia validação de licenças contra API remota
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>
#import <sys/sysctl.h>

static NSString * const kKeychainService = @"com.martinsmod.license";
static NSString * const kKeychainAccount = @"license_key";

// MARK: - Estrutura de Dados

typedef void (^LicenseCompletionHandler)(BOOL success, NSString * _Nullable error);
typedef void (^LicenseCheckHandler)(BOOL valid, NSString * _Nullable error);

// MARK: - Classe LicenseManager

@interface LicenseManager : NSObject
@property (nonatomic, strong) NSString *apiBaseURL;
@property (nonatomic, strong) NSTimer *verificationTimer;
@end

@implementation LicenseManager

static LicenseManager *sharedInstance = nil;

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[LicenseManager alloc] initWithAPIURL:@"https://187.127.45.32:3000"];
    });
    return sharedInstance;
}

- (instancetype)initWithAPIURL:(NSString *)apiURL {
    self = [super init];
    if (self) {
        self.apiBaseURL = apiURL;
        [self setupVerificationTimer];
    }
    return self;
}

// MARK: - Ativar Licença

- (void)activateLicense:(NSString *)key completion:(LicenseCompletionHandler)completion {
    if (![self isValidKeyFormat:key]) {
        if (completion) {
            completion(NO, @"Formato de chave inválido");
        }
        return;
    }
    
    NSString *deviceId = [self getDeviceIdentifier];
    NSString *appVersion = [self getAppVersion];
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    
    NSDictionary *requestBody = @{
        @"key": key,
        @"deviceId": deviceId,
        @"appVersion": appVersion,
        @"osVersion": osVersion
    };
    
    [self makeAPIRequestWithEndpoint:@"/api/license/activate"
                              method:@"POST"
                                body:requestBody
                          completion:^(NSDictionary *response, NSError *error) {
        if (error) {
            if (completion) {
                completion(NO, error.localizedDescription);
            }
            return;
        }
        
        NSNumber *valid = response[@"valid"];
        if (valid && [valid boolValue]) {
            [self storeKeyInKeychain:key];
            if (completion) {
                completion(YES, nil);
            }
        } else {
            NSString *errorCode = response[@"error"] ?: @"Erro desconhecido";
            if (completion) {
                completion(NO, errorCode);
            }
        }
    }];
}

// MARK: - Verificar Licença

- (void)checkLicenseWithCompletion:(LicenseCheckHandler)completion {
    NSString *key = [self retrieveKeyFromKeychain];
    if (!key) {
        if (completion) {
            completion(NO, @"LICENSE_NOT_FOUND");
        }
        return;
    }
    
    NSString *deviceId = [self getDeviceIdentifier];
    
    NSDictionary *requestBody = @{
        @"key": key,
        @"deviceId": deviceId
    };
    
    [self makeAPIRequestWithEndpoint:@"/api/license/check"
                              method:@"POST"
                                body:requestBody
                          completion:^(NSDictionary *response, NSError *error) {
        if (error) {
            if (completion) {
                completion(NO, error.localizedDescription);
            }
            return;
        }
        
        NSNumber *valid = response[@"valid"];
        if (valid && [valid boolValue]) {
            if (completion) {
                completion(YES, nil);
            }
        } else {
            NSString *errorCode = response[@"error"] ?: @"Erro desconhecido";
            if (completion) {
                completion(NO, errorCode);
            }
        }
    }];
}

// MARK: - Obter Informações

- (void)getRemainingSecondsWithCompletion:(void (^)(NSInteger seconds, NSString * _Nullable error))completion {
    NSString *key = [self retrieveKeyFromKeychain];
    if (!key) {
        if (completion) {
            completion(0, @"LICENSE_NOT_FOUND");
        }
        return;
    }
    
    NSString *deviceId = [self getDeviceIdentifier];
    
    NSDictionary *requestBody = @{
        @"key": key,
        @"deviceId": deviceId
    };
    
    [self makeAPIRequestWithEndpoint:@"/api/license/check"
                              method:@"POST"
                                body:requestBody
                          completion:^(NSDictionary *response, NSError *error) {
        if (error) {
            if (completion) {
                completion(0, error.localizedDescription);
            }
            return;
        }
        
        NSNumber *remainingSeconds = response[@"remainingSeconds"];
        if (remainingSeconds) {
            if (completion) {
                completion([remainingSeconds integerValue], nil);
            }
        } else {
            if (completion) {
                completion(0, @"Erro ao obter tempo restante");
            }
        }
    }];
}

- (void)getExpirationDateWithCompletion:(void (^)(NSDate * _Nullable date, NSString * _Nullable error))completion {
    NSString *key = [self retrieveKeyFromKeychain];
    if (!key) {
        if (completion) {
            completion(nil, @"LICENSE_NOT_FOUND");
        }
        return;
    }
    
    NSString *deviceId = [self getDeviceIdentifier];
    
    NSDictionary *requestBody = @{
        @"key": key,
        @"deviceId": deviceId
    };
    
    [self makeAPIRequestWithEndpoint:@"/api/license/check"
                              method:@"POST"
                                body:requestBody
                          completion:^(NSDictionary *response, NSError *error) {
        if (error) {
            if (completion) {
                completion(nil, error.localizedDescription);
            }
            return;
        }
        
        NSString *expiresAtString = response[@"expiresAt"];
        if (expiresAtString) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
            formatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
            NSDate *expiresAt = [formatter dateFromString:expiresAtString];
            
            if (completion) {
                completion(expiresAt, nil);
            }
        } else {
            if (completion) {
                completion(nil, @"Erro ao obter data de expiração");
            }
        }
    }];
}

// MARK: - Desativar Licença

- (void)deactivateLicense {
    [self removeKeyFromKeychain];
    [self stopVerificationTimer];
}

// MARK: - Propriedades

- (BOOL)isLicenseValid {
    NSString *key = [self retrieveKeyFromKeychain];
    return key != nil && [self isValidKeyFormat:key];
}

// MARK: - Verificação Periódica

- (void)setupVerificationTimer {
    NSTimeInterval interval = 6 * 60 * 60; // 6 horas
    self.verificationTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                              target:self
                                                            selector:@selector(verifyLicensePeriodically)
                                                            userInfo:nil
                                                             repeats:YES];
}

- (void)stopVerificationTimer {
    [self.verificationTimer invalidate];
    self.verificationTimer = nil;
}

- (void)verifyLicensePeriodically {
    [self checkLicenseWithCompletion:^(BOOL valid, NSString *error) {
        if (!valid) {
            NSLog(@"🚨 LICENÇA INVÁLIDA: %@", error);
            [self crashApp:error ?: @"Licença inválida"];
        }
    }];
}

// MARK: - Métodos Privados

- (BOOL)isValidKeyFormat:(NSString *)key {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$"
                                                                           options:0
                                                                             error:nil];
    NSRange range = NSMakeRange(0, key.length);
    return [regex numberOfMatchesInString:key options:0 range:range] > 0;
}

- (NSString *)getDeviceIdentifier {
    char buffer[256];
    size_t bufferSize = sizeof(buffer);
    int result = sysctlbyname("hw.machine", buffer, &bufferSize, NULL, 0);
    
    NSString *machine = @"unknown";
    if (result == 0) {
        machine = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
    }
    
    NSString *uuid = [[UIDevice currentDevice].identifierForVendor UUIDString] ?: @"unknown";
    NSString *combined = [NSString stringWithFormat:@"%@-%@", machine, uuid];
    
    return [self hashSHA256:combined];
}

- (NSString *)getAppVersion {
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    return version ?: @"1.0.0";
}

- (NSString *)hashSHA256:(NSString *)input {
    NSData *data = [input dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
    
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", digest[i]];
    }
    
    return result;
}

// MARK: - Keychain

- (void)storeKeyInKeychain:(NSString *)key {
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeychainService,
        (__bridge id)kSecAttrAccount: kKeychainAccount,
        (__bridge id)kSecValueData: keyData
    };
    
    SecItemDelete((__bridge CFDictionaryRef)query);
    SecItemAdd((__bridge CFDictionaryRef)query, NULL);
}

- (NSString *)retrieveKeyFromKeychain {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeychainService,
        (__bridge id)kSecAttrAccount: kKeychainAccount,
        (__bridge id)kSecReturnData: @YES
    };
    
    CFDataRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    
    if (status == errSecSuccess && result) {
        NSString *key = [[NSString alloc] initWithData:(__bridge NSData *)result encoding:NSUTF8StringEncoding];
        CFRelease(result);
        return key;
    }
    
    return nil;
}

- (void)removeKeyFromKeychain {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeychainService,
        (__bridge id)kSecAttrAccount: kKeychainAccount
    };
    
    SecItemDelete((__bridge CFDictionaryRef)query);
}

// MARK: - API

- (void)makeAPIRequestWithEndpoint:(NSString *)endpoint
                            method:(NSString *)method
                              body:(NSDictionary *)body
                        completion:(void (^)(NSDictionary *response, NSError *error))completion {
    NSString *urlString = [NSString stringWithFormat:@"%@%@", self.apiBaseURL, endpoint];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = method;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    if (body) {
        NSError *jsonError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];
        if (!jsonError) {
            request.HTTPBody = jsonData;
        }
    }
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        
        NSError *jsonError = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if (completion) {
            completion(json, jsonError);
        }
    }];
    
    [task resume];
}

// MARK: - Crash

- (void)crashApp:(NSString *)reason {
    NSLog(@"🚨 LICENÇA INVÁLIDA: %@", reason);
    
    NSException *exception = [NSException exceptionWithName:@"LicenseInvalidException"
                                                     reason:reason
                                                   userInfo:nil];
    @throw exception;
}

@end
