#import <Foundation/Foundation.h>

@class MLKEntityAnnotation;
@class MLKEntityExtractionParams;
@class MLKEntityExtractorOptions;
@class MLKModelDownloadConditions;

NS_ASSUME_NONNULL_BEGIN

/**
 * A block that handles an entity extraction result.
 *
 * @param result An array of annotations for the text or `nil` if there's an error.
 * @param error The error or `nil`.
 */
typedef void (^MLKEntityExtractorCallback)(NSArray<MLKEntityAnnotation *> *_Nullable result,
                                           NSError *_Nullable error)
    NS_SWIFT_NAME(EntityExtractorCallback);

/**
 * A block that is invoked when the entity extraction models are downloaded.
 *
 * @param error The error or `nil`.
 */
typedef void (^MLKEntityExtractorDownloadModelIfNeededCallback)(NSError *_Nullable error)
    NS_SWIFT_NAME(EntityExtractorDownloadModelIfNeededCallback);

/** A class that extracts entities from the given input text. */
NS_SWIFT_NAME(EntityExtractor)
@interface MLKEntityExtractor : NSObject

/**
 * Gets an `EntityExtractor` instance configured with the given options. This method is
 * thread safe.
 *
 * @param options The options for the entity extractor.
 * @return An `EntityExtractor` instance with the given options.
 */
+ (MLKEntityExtractor *)entityExtractorWithOptions:(MLKEntityExtractorOptions *)options
    NS_SWIFT_NAME(entityExtractor(options:));

/**
 * Annotates the given text with the default value for `EntityExtractionParams`.
 * Uses the current time as the reference time and device timezone as the reference timezone.
 * Annotates all supported entity types.
 *
 * @param text The text to be annotated.
 * @param completion Handler to call back on the main queue with the entity extraction result or
 *     error.
 */
- (void)annotateText:(NSString *)text
          completion:(MLKEntityExtractorCallback)completion
    NS_SWIFT_NAME(annotateText(_:completion:));

/**
 * Annotates the given text with the given parameters such as reference time, reference time zone
 * and entity types filter.
 *
 * @param text The text to be annotated.
 * @param params The entity extraction parameters to be used during entity extraction.
 * @param completion Handler to call back on the main queue with the entity extraction result or
 *     error.
 */
- (void)annotateText:(NSString *)text
          withParams:(MLKEntityExtractionParams *)params
          completion:(MLKEntityExtractorCallback)completion
    NS_SWIFT_NAME(annotateText(_:params:completion:));

/**
 * Downloads the model files required for entity extraction with the default download conditions
 * (cellular access allowed and background downloads disallowed). If model has already been
 * downloaded, completes without additional work.
 *
 * @param completion Handler to call back on the main queue with an error, if any.
 */
- (void)downloadModelIfNeededWithCompletion:
    (MLKEntityExtractorDownloadModelIfNeededCallback)completion;

/**
 * Downloads the model files required for entity extraction when the given conditions are met. If
 * model has already been downloaded, completes without additional work.
 *
 * @param conditions The downloading conditions for the translate model.
 * @param completion Handler to call back on the main queue with an error, if any.
 */
- (void)downloadModelIfNeededWithConditions:(MLKModelDownloadConditions *)conditions
                                 completion:
                                     (MLKEntityExtractorDownloadModelIfNeededCallback)completion;

/** Unavailable. */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
