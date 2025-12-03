#import "MLKEntity.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** An IBAN entity extracted from text. */
NS_SWIFT_NAME(IBANEntity)
@interface MLKIBANEntity : NSObject

/** The full IBAN number in canonical form. For example, `CH9300762011623852957`. */
@property(nonatomic, readonly) NSString *IBAN;

/** The ISO 3166-1 alpha-2 country code (two letters). For example, `CH`. */
@property(nonatomic, readonly) NSString *countryCode;

/** Unavailable. */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
