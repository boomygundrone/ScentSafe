#import <Foundation/Foundation.h>

#import "MLKEntity.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(EntityExtractionParams)
/**
 * An object that contains various parameters that can be customized on each entity extraction
 * call.
 */
@interface MLKEntityExtractionParams : NSObject

/**
 * Reference time based on which relative dates (e.g. "tomorrow") should be interpreted, in
 * milliseconds from the epoch of 1970-01-01T00:00:00 (UTC timezone). A nil value means that the
 * current time (when entity extraction is invoked) should be used.
 */
@property(nonatomic, nullable) NSDate *referenceTime;

/**
 * Reference time zone based on which relative dates (e.g. "tomorrow") should be interpreted. If
 * this is not set, the current time zone (when entity extraction is invoked) will be used.
 */
@property(nonatomic, nullable) NSTimeZone *referenceTimeZone;

/**
 * A preferred locale that can be used to disambiguate potential values for date-time entities.
 * For example, "01/02/2000" is ambiguous and could refer to either January 2nd or February 1st,
 * but a locale preference could help pick the right one ('en-US' would pick the former, and 'en-UK'
 * the latter). The default value is the device's system locale.
 * The supported locales match the list of supported models. So any of (or a subset of):
 * {@code 'en-*'} ({@code 'en-US'}, {@code 'en-UK'}, {@code 'en-CA'}, ...), {@code 'ar-*'},
 * {@code 'de-*'}, {@code 'es-*'}, {@code 'fr-*'}, {@code 'it-*'}, {@code 'ja-*'}, {@code
 * 'ko-*'}, {@code 'nl-*'}, {@code 'pl-*'}, {@code 'pt-*'}, {@code 'ru-*'}, {@code 'th-*'},
 * {@code 'tr-*'}, {@code 'zh-*'}
 */
@property(nonatomic, null_resettable) NSLocale *preferredLocale;

/**
 * The subset of entity types (`EntityExtractionEntityType`) that will be detected by the
 * entity extractor. Types not present in the set will not be returned even if they are present
 * in the input text. `nil` sets will be reset to the default set returned by
 * `EntityType.allEntityTypes()`.
 */
@property(nonatomic, null_resettable, copy) NSSet<MLKEntityExtractionEntityType> *typesFilter;

/**
 * Initializes an allocated `EntityExtractionParams` instance with the default values.
 * Sets the referenceTime and referenceTimezone to `nil` and sets the typesFilter to a set
 * containing all values returned from `EntityType.allEntityTypes()`.
 */
- (instancetype)init NS_DESIGNATED_INITIALIZER;

@end
NS_ASSUME_NONNULL_END
