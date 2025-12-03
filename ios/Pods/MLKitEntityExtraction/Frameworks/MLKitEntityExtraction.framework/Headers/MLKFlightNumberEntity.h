#import "MLKEntity.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** A flight number entity extracted from text. */
NS_SWIFT_NAME(FlightNumberEntity)
@interface MLKFlightNumberEntity : NSObject

/** The IATA airline designator (two or three letters). */
@property(nonatomic, readonly) NSString *airlineCode;

/** The flight number (1 to 4 digit number). */
@property(nonatomic, readonly) NSString *flightNumber;

/** Unavailable. */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
