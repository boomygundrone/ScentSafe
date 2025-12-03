#import <Foundation/Foundation.h>


#import <MLKitEntityExtraction/MLKEntityExtractionModelIdentifier.h>

NS_ASSUME_NONNULL_BEGIN

/** Options for`EntityExtractor`. */
NS_SWIFT_NAME(EntityExtractorOptions)
@interface MLKEntityExtractorOptions : NSObject

/** The model to use when parsing entities in the text. */
@property(nonatomic, readonly) MLKEntityExtractionModelIdentifier modelIdentifier;

/** Unavailable. */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Creates a new instance of EntityExtractor options with the given model identifier.
 *
 * @param modelIdentifier The model to use when parsing addresses and phone numbers in
 * text.
 * @return A new instance of `EntityExtractorOptions` configured with the given model identifier.
 */
- (instancetype)initWithModelIdentifier:(MLKEntityExtractionModelIdentifier)modelIdentifier
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
