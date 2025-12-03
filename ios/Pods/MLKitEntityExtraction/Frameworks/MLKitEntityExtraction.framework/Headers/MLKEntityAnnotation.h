#import <Foundation/Foundation.h>

@class MLKEntity;

NS_ASSUME_NONNULL_BEGIN

/** An object that contains the possible entities associated with a piece of the text. */
NS_SWIFT_NAME(EntityAnnotation)
@interface MLKEntityAnnotation : NSObject

/** The range of the annotation in the given text. */
@property(nonatomic, readonly) NSRange range;

/**
 * A list of possible entities in the given span of text.
 */
@property(nonatomic, readonly) NSArray<MLKEntity *> *entities;

@end

NS_ASSUME_NONNULL_END
