#import "MLKEntity.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @enum ParcelTrackingCarrier
 * The supported parcel tracking carriers that can be detected.
 */
typedef NS_ENUM(NSInteger, MLKParcelTrackingCarrier) {
  /** The parcel tracking carrier is unknown. */
  MLKParcelTrackingCarrierUnknown = 0,
  /** The parcel tracking carrier is FedEx. */
  MLKParcelTrackingCarrierFedEx,
  /** The parcel tracking carrier is UPS. */
  MLKParcelTrackingCarrierUPS,
  /** The parcel tracking carrier is DHL. */
  MLKParcelTrackingCarrierDHL,
  /** The parcel tracking carrier is USPS. */
  MLKParcelTrackingCarrierUSPS,
  /** The parcel tracking carrier is Ontrac. */
  MLKParcelTrackingCarrierOntrac,
  /** The parcel tracking carrier is Lasership. */
  MLKParcelTrackingCarrierLasership,
  /** The parcel tracking carrier is IsraelPost. */
  MLKParcelTrackingCarrierIsraelPost,
  /** The parcel tracking carrier is SwissPost. */
  MLKParcelTrackingCarrierSwissPost,
  /** The parcel tracking carrier is MSC. */
  MLKParcelTrackingCarrierMSC,
  /** The parcel tracking carrier is Amazon. */
  MLKParcelTrackingCarrierAmazon,
  /** The parcel tracking carrier is IParcel. */
  MLKParcelTrackingCarrierIParcel,
} NS_SWIFT_NAME(ParcelTrackingCarrier);

/** A tracking number extracted from text. */
NS_SWIFT_NAME(TrackingNumberEntity)
@interface MLKTrackingNumberEntity : NSObject

/** The parcel tracking carrier. */
@property(nonatomic, readonly) MLKParcelTrackingCarrier parcelCarrier;

/** The parcel tracking number in canonical form. For example, `1Z204E380338943508`. */
@property(nonatomic, readonly) NSString *parcelTrackingNumber;

/** Unavailable. */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
