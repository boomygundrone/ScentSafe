
#import <MLKitCommon/MLKModelManager.h>

@class MLKEntityExtractionRemoteModel;

NS_ASSUME_NONNULL_BEGIN

/** Extensions to `ModelManager` for EntityExtraction-specific functionality. */
@interface MLKModelManager (EntityExtraction)

/**
 * A set of already-downloaded entity extraction models.
 * These models can be then deleted through `ModelManager`'s `deleteDownloadedModel(_:completion:)`
 * API to manage disk space.
 */
@property(nonatomic, readonly)
    NSSet<MLKEntityExtractionRemoteModel *> *downloadedEntityExtractionModels;

@end

NS_ASSUME_NONNULL_END
