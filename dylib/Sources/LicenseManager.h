//
//  LicenseManager.h
//  LicenseManager
//
//  Dylib para gerenciar licenças de aplicativos iOS
//

#ifndef LicenseManager_h
#define LicenseManager_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^LicenseCompletionHandler)(BOOL success, NSString * _Nullable error);
typedef void (^LicenseCheckHandler)(BOOL valid, NSString * _Nullable error);
typedef void (^LicenseInfoHandler)(NSString * _Nullable info, NSString * _Nullable error);

@interface LicenseManager : NSObject

+ (instancetype)sharedManager;
- (instancetype)initWithAPIURL:(NSString *)apiURL;

/**
 Ativa uma licença no dispositivo
 */
- (void)activateLicense:(NSString *)key completion:(LicenseCompletionHandler)completion;

/**
 Verifica se a licença é válida
 */
- (void)checkLicenseWithCompletion:(LicenseCheckHandler)completion;

/**
 Obtém o tempo restante em segundos
 */
- (void)getRemainingSecondsWithCompletion:(void (^)(NSInteger seconds, NSString * _Nullable error))completion;

/**
 Obtém a data de expiração
 */
- (void)getExpirationDateWithCompletion:(void (^)(NSDate * _Nullable date, NSString * _Nullable error))completion;

/**
 Desativa a licença
 */
- (void)deactivateLicense;

/**
 Verifica se a licença é válida localmente
 */
@property (nonatomic, readonly) BOOL isLicenseValid;

@end

NS_ASSUME_NONNULL_END

#endif /* LicenseManager_h */
