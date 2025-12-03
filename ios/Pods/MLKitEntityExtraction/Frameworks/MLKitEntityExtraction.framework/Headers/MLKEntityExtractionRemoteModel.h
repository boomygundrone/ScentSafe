#import <Foundation/Foundation.h>


#import <MLKitCommon/MLKRemoteModel.h>
#import <MLKitEntityExtraction/MLKEntityExtractorOptions.h>

@class MLKContext;
NS_ASSUME_NONNULL_BEGIN

/** An entity extraction model that is stored remotely on the server and downloaded on the device.
 */
NS_SWIFT_NAME(EntityExtractorRemoteModel)
@interface MLKEntityExtractionRemoteModel : MLKRemoteModel

/** The model identifier of this model. */
@property(nonatomic, readonly) MLKEntityExtractionModelIdentifier modelIdentifier;

/**
 * Gets an instance of `EntityExtractorRemoteModel` configured with the given model identifier.
 * This model can be used to trigger a download by calling the `download(_:)` API
 * from `ModelManager`.
 *
 * @discussion `EntityExtractorRemoteModel` uses `ModelManager` internally. When downloading
 * an `EntityExtractorRemoteModel`, there will be a notification posted for a `RemoteModel`.
 * To verify if such notifications belong to an `EntityExtractorRemoteModel`, check that the
 * `ModelDownloadUserInfoKeyRemoteModel` field in the user info dictionary contains an object
 * of type `EntityExtractorRemoteModel` .
 *
 * @param modelIdentifier The model identifier of the model.
 * @return A `EntityExtractorRemoteModel` instance.
 */
+ (MLKEntityExtractionRemoteModel *)entityExtractorRemoteModelWithIdentifier:
    (MLKEntityExtractionModelIdentifier)modelIdentifier
    NS_SWIFT_NAME(entityExtractorRemoteModel(identifier:));

/** Unavailable. */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
