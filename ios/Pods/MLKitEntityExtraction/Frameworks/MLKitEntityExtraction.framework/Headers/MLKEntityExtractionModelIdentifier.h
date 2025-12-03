#import <Foundation/Foundation.h>

#if defined __cplusplus
extern "C" {
#endif  // __cplusplus

NS_ASSUME_NONNULL_BEGIN


/** An enumeration of models supported by `EntityExtractor`. */
typedef NSString *MLKEntityExtractionModelIdentifier NS_TYPED_ENUM
    NS_SWIFT_NAME(EntityExtractionModelIdentifier);

/** Arabic. */
extern const MLKEntityExtractionModelIdentifier MLKEntityExtractionModelIdentifierArabic;
/** Chinese. */
extern const MLKEntityExtractionModelIdentifier MLKEntityExtractionModelIdentifierChinese;
/** Dutch. */
extern const MLKEntityExtractionModelIdentifier MLKEntityExtractionModelIdentifierDutch;
/** English. */
extern const MLKEntityExtractionModelIdentifier MLKEntityExtractionModelIdentifierEnglish;
/** French. */
extern const MLKEntityExtractionModelIdentifier MLKEntityExtractionModelIdentifierFrench;
/** German. */
extern const MLKEntityExtractionModelIdentifier MLKEntityExtractionModelIdentifierGerman;
/** Italian. */
extern const MLKEntityExtractionModelIdentifier MLKEntityExtractionModelIdentifierItalian;
/** Japanese. */
extern const MLKEntityExtractionModelIdentifier MLKEntityExtractionModelIdentifierJapanese;
/** Korean. */
extern const MLKEntityExtractionModelIdentifier MLKEntityExtractionModelIdentifierKorean;
/** Polish. */
extern const MLKEntityExtractionModelIdentifier MLKEntityExtractionModelIdentifierPolish;
/** Portuguese. */
extern const MLKEntityExtractionModelIdentifier MLKEntityExtractionModelIdentifierPortuguese;
/** Russian. */
extern const MLKEntityExtractionModelIdentifier MLKEntityExtractionModelIdentifierRussian;
/** Spanish. */
extern const MLKEntityExtractionModelIdentifier MLKEntityExtractionModelIdentifierSpanish;
/** Thai. */
extern const MLKEntityExtractionModelIdentifier MLKEntityExtractionModelIdentifierThai;
/** Turkish. */
extern const MLKEntityExtractionModelIdentifier MLKEntityExtractionModelIdentifierTurkish;



/**
 * Returns a set that contains `EntityExtractionModelIdentifier` values of all model identifiers
 * supported by the Entity Extraction API.
 */
NSSet<MLKEntityExtractionModelIdentifier> *MLKEntityExtractionAllModelIdentifiers(void)
    NS_SWIFT_NAME(EntityExtractionModelIdentifier.allModelIdentifiers());

/**
 * Returns the [BCP 47 language tag](https://tools.ietf.org/rfc/bcp/bcp47.txt) for this
 * `EntityExtractionModelIdentifier`.
 */
NSString *MLKEntityExtractionLanguageTagForModelIdentifier(
    MLKEntityExtractionModelIdentifier modelIdentifier)
    NS_SWIFT_NAME(EntityExtractionModelIdentifier.toLanguageTag(self:));

/**
 * Returns the `EntityExtractionModelIdentifier` for a given [BCP 47 language
 * tag](https://tools.ietf.org/rfc/bcp/bcp47.txt), or `nil` if the language tag is invalid or not
 * supported by the Entity Extraction API.
 */
_Nullable MLKEntityExtractionModelIdentifier MLKEntityExtractionModelIdentifierForLanguageTag(
    NSString *languageTag) NS_SWIFT_NAME(EntityExtractionModelIdentifier.fromLanguageTag(_:));

NS_ASSUME_NONNULL_END

#if defined __cplusplus
}
#endif  // __cplusplus
