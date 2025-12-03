#import <Foundation/Foundation.h>


#import <MLKitObjectDetectionCommon/MLKCommonObjectDetectorOptions.h>

@class MLKCustomRemoteModel;
@class MLKLocalModel;

NS_ASSUME_NONNULL_BEGIN

/** Configurations for a custom-model object detector. */
NS_SWIFT_NAME(CustomObjectDetectorOptions)
@interface MLKCustomObjectDetectorOptions : MLKCommonObjectDetectorOptions

/**
 * The confidence threshold for labels returned by the object detector. Labels returned by the
 * object detector will have a confidence level higher or equal to the given threshold. The
 * threshold is a floating-point value and must be in range [0, 1]. If unset or an invalid value is
 * set, any classifier threshold specified by the model’s metadata will be used. If the model does
 * not contain any metadata or the metadata does not specify a classifier threshold, the default
 * threshold of `0.0` is used.
 */
@property(nonatomic, nullable) NSNumber *classificationConfidenceThreshold;

/**
 * The maximum number of labels to return for a detected object. Must be positive. If unset or an
 * invalid value is set, the default value of `10` is used.
 */
@property(nonatomic) NSInteger maxPerObjectLabelCount;

/**
 * Initializes a `CustomObjectDetectorOptions` instance using the given `LocalModel` with the
 * `classificationConfidenceThreshold` property set to `nil`. If that remains unset, it will use the
 * confidence threshold value included in the model metadata, if available. If that does not exist,
 * a value of `0.0` will be used instead.
 *
 * @param localModel A custom object classification model stored locally on the device.
 * @return A new instance of `CustomObjectDetectorOptions` with the given `LocalModel`.
 */
- (instancetype)initWithLocalModel:(MLKLocalModel *)localModel;

/**
 * Initializes a `CustomObjectDetectorOptions` instance using the given `CustomRemoteModel` with the
 * `classificationConfidenceThreshold` property set to `nil`. If that remains unset, it will use the
 * confidence threshold value included in the model metadata, if available. If that does not exist,
 * a value of `0.0` will be used instead.
 *
 * @param remoteModel A custom object classification model stored remotely on the server and
 *     downloaded to the device.
 * @return A new instance of `CustomObjectDetectorOptions` with the given `CustomRemoteModel`.
 */
- (instancetype)initWithRemoteModel:(MLKCustomRemoteModel *)remoteModel;

/** Unavailable. */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
