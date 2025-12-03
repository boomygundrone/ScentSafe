#import "MLKEntity.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @enum PaymentCardNetwork
 * The supported payment card networks that can be detected.
 */
typedef NS_ENUM(NSInteger, MLKPaymentCardNetwork) {
  /** The payment card network is unknown. */
  MLKPaymentCardNetworkUnknown = 0,
  /** The payment card is part of the Amex network. */
  MLKPaymentCardNetworkAmex,
  /** The payment card is part of the DinersClub network. */
  MLKPaymentCardNetworkDinersClub,
  /** The payment card is part of the Discover network. */
  MLKPaymentCardNetworkDiscover,
  /** The payment card is part of the InterPayment network. */
  MLKPaymentCardNetworkInterPayment,
  /** The payment card is part of the JCB network. */
  MLKPaymentCardNetworkJCB,
  /** The payment card is part of the Maestro network. */
  MLKPaymentCardNetworkMaestro,
  /** The payment card is part of the Mastercard network. */
  MLKPaymentCardNetworkMastercard,
  /** The payment card is part of the Mir network. */
  MLKPaymentCardNetworkMir,
  /** The payment card is part of the Troy network. */
  MLKPaymentCardNetworkTroy,
  /** The payment card is part of the Unionpay network. */
  MLKPaymentCardNetworkUnionpay,
  /** The payment card is part of the Visa network. */
  MLKPaymentCardNetworkVisa,
} NS_SWIFT_NAME(PaymentCardNetwork);

/** A payment card entity extracted from text. */
@interface MLKPaymentCardEntity : NSObject

/** The payment card network. */
@property(nonatomic, readonly) MLKPaymentCardNetwork paymentCardNetwork;

/** The payment card number in canonical form. For example, `4111111111111111`. */
@property(nonatomic, readonly) NSString *paymentCardNumber;

/** Unavailable. */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
