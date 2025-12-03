#import "MLKEntity.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @enum DateTimeGranularity
 * The precision of a timestamp that was extracted from text.
 *
 * For example, "tomorrow" has the granularity `.day`, while "12:51" has the granularity `.minute`.
 */
typedef NS_ENUM(NSInteger, MLKDateTimeGranularity) {
  /** The granularity of the `DateTimeEntity` is unknown. */
  MLKDateTimeGranularityUnknown = 0,
  /** The `DateTimeEntity` is precise to a specific year. */
  MLKDateTimeGranularityYear,
  /** The `DateTimeEntity` is precise to a specific month. */
  MLKDateTimeGranularityMonth,
  /** The `DateTimeEntity` is precise to a specific week. */
  MLKDateTimeGranularityWeek,
  /** The `DateTimeEntity` is precise to a specific day. */
  MLKDateTimeGranularityDay,
  /** The `DateTimeEntity` is precise to a specific hour. */
  MLKDateTimeGranularityHour,
  /** The `DateTimeEntity` is precise to a specific minute. */
  MLKDateTimeGranularityMinute,
  /** The `DateTimeEntity` is precise to a specific second. */
  MLKDateTimeGranularitySecond,
} NS_SWIFT_NAME(DateTimeGranularity);

/** A date and time entity extracted from text. */
NS_SWIFT_NAME(DateTimeEntity)
@interface MLKDateTimeEntity : NSObject

/** The parsed date and time. */
@property(nonatomic, readonly) NSDate *dateTime;

/** The granularity of the date and time. */
@property(nonatomic, readonly) MLKDateTimeGranularity dateTimeGranularity;

/** Unavailable. */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
