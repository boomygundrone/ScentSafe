#import "MLKEntity.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** A money entity extracted from text. */
NS_SWIFT_NAME(MoneyEntity)
@interface MLKMoneyEntity : NSObject

/**
 * The currency part of the detected annotation. No formatting is applied so this will return a
 * subset of the initial string.
 */
@property(nonatomic, readonly) NSString *unnormalizedCurrency;

/**
 * The integer part of the detected annotation. This is the integer written to the left of the
 * decimal separator.
 */
@property(nonatomic, readonly) NSInteger integerPart;

/**
 * The fractional part of the detected annotation. This is the integer written to the right of the
 * decimal separator.
 */
@property(nonatomic, readonly) NSInteger fractionalPart;

/** Unavailable. */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
