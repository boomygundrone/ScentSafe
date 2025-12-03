#import <Foundation/Foundation.h>

#if defined __cplusplus
extern "C" {
#endif  // __cplusplus

@class MLKDateTimeEntity;
@class MLKFlightNumberEntity;
@class MLKIBANEntity;
@class MLKISBNEntity;
@class MLKMoneyEntity;
@class MLKPaymentCardEntity;
@class MLKTrackingNumberEntity;

NS_ASSUME_NONNULL_BEGIN

/**
 * @enum EntityExtractionEntityType
 * The type of an extracted entity.
 */
typedef NSString *MLKEntityExtractionEntityType NS_TYPED_ENUM NS_SWIFT_NAME(EntityType);

/** Identifies a physical address. */
extern MLKEntityExtractionEntityType const MLKEntityExtractionEntityTypeAddress;

/**
 * Identifies a time reference that includes a specific time. May be absolute such as "01/01/2000
 * 5:30pm" or relative like "tomorrow".
 */
extern MLKEntityExtractionEntityType const MLKEntityExtractionEntityTypeDateTime;

/** Identifies an e-mail address. */
extern MLKEntityExtractionEntityType const MLKEntityExtractionEntityTypeEmail;

/** Identifies a flight number in IATA format. */
extern MLKEntityExtractionEntityType const MLKEntityExtractionEntityTypeFlightNumber;

/** Identifies an International Bank Account Number (IBAN). */
extern MLKEntityExtractionEntityType const MLKEntityExtractionEntityTypeIBAN;

/** Identifies an International Standard Book Number (ISBN). */
extern MLKEntityExtractionEntityType const MLKEntityExtractionEntityTypeISBN;

/** Identifies an amount of money. */
extern MLKEntityExtractionEntityType const MLKEntityExtractionEntityTypeMoney;

/** Identifies a payment card. */
extern MLKEntityExtractionEntityType const MLKEntityExtractionEntityTypePaymentCard;

/** Identifies a phone number. */
extern MLKEntityExtractionEntityType const MLKEntityExtractionEntityTypePhone;

/** Identifies a shipment tracking number. */
extern MLKEntityExtractionEntityType const MLKEntityExtractionEntityTypeTrackingNumber;

/** Identifies a URL. */
extern MLKEntityExtractionEntityType const MLKEntityExtractionEntityTypeURL;

/**
 * Returns a set that contains `EntityType` codes of all entity types supported
 * by the entity extraction API.
 */
NSSet<MLKEntityExtractionEntityType> *MLKEntityExtractionEntityTypeAllEntityTypes(void)
    NS_SWIFT_NAME(EntityType.allEntityTypes());

/** An entity extracted from a substring of text. */
NS_SWIFT_NAME(Entity)
@interface MLKEntity : NSObject

/** The type of the extracted entity. */
@property(nonatomic, readonly) MLKEntityExtractionEntityType entityType;

/** The time reference entity containing a specific time or `nil` if not extracted from the text. */
@property(nonatomic, readonly, nullable) MLKDateTimeEntity *dateTimeEntity;

/** The flight number entity in IATA format or `nil` if not extracted from the text. */
@property(nonatomic, readonly, nullable) MLKFlightNumberEntity *flightNumberEntity;

/** The International Bank Account Number (IBAN) entity or `nil` if not extracted from the text. */
@property(nonatomic, readonly, nullable) MLKIBANEntity *IBANEntity;

/** The International Standard Book Number (ISBN) entity or `nil` if not extracted from the text. */
@property(nonatomic, readonly, nullable) MLKISBNEntity *ISBNEntity;

/** The entity representing an amount of money or `nil` if not extracted from the text. */
@property(nonatomic, readonly, nullable) MLKMoneyEntity *moneyEntity;

/** The payment card entity or `nil` if not extracted from the text. */
@property(nonatomic, readonly, nullable) MLKPaymentCardEntity *paymentCardEntity;

/** The tracking number entity for a shipment or `nil` if not extracted from the text. */
@property(nonatomic, readonly, nullable) MLKTrackingNumberEntity *trackingNumberEntity;

/** Unavailable. */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

#if defined __cplusplus
}
#endif  // __cplusplus
