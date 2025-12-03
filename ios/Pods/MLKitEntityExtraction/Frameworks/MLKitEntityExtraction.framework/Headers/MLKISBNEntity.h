#import "MLKEntity.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** An ISBN entity extracted from text. */
NS_SWIFT_NAME(ISBNEntity)
@interface MLKISBNEntity : NSObject

/** The full ISBN number in canonical form. For example, `9780007547999`. */
@property(nonatomic, readonly) NSString *ISBN;

/** Unavailable. */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
