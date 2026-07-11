import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Cùng Hát'**
  String get appTitle;

  /// No description provided for @tabDoi.
  ///
  /// In en, this message translates to:
  /// **'Đôi'**
  String get tabDoi;

  /// No description provided for @tabKeo.
  ///
  /// In en, this message translates to:
  /// **'Kèo'**
  String get tabKeo;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @authTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authTitle;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneLabel;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get otpTitle;

  /// No description provided for @otpLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get otpLabel;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get verify;

  /// No description provided for @onbDobTitle.
  ///
  /// In en, this message translates to:
  /// **'When were you born?'**
  String get onbDobTitle;

  /// No description provided for @onbUnder18.
  ///
  /// In en, this message translates to:
  /// **'You must be 18 or older to use the app.'**
  String get onbUnder18;

  /// No description provided for @onbConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get onbConsentTitle;

  /// No description provided for @onbNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get onbNameLabel;

  /// No description provided for @onbBioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get onbBioLabel;

  /// No description provided for @onbTasteGenres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get onbTasteGenres;

  /// No description provided for @onbTasteArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get onbTasteArtists;

  /// No description provided for @onbBaitu.
  ///
  /// In en, this message translates to:
  /// **'Signature songs'**
  String get onbBaitu;

  /// No description provided for @onbFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get onbFinish;

  /// No description provided for @onbConsentRequired.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the required permissions to continue.'**
  String get onbConsentRequired;

  /// No description provided for @onbSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your profile'**
  String get onbSetupTitle;

  /// No description provided for @onbStepDob.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get onbStepDob;

  /// No description provided for @onbStepProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get onbStepProfile;

  /// No description provided for @onbStepTaste.
  ///
  /// In en, this message translates to:
  /// **'Music taste'**
  String get onbStepTaste;

  /// No description provided for @onbProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {step}/4'**
  String onbProgress(int step);

  /// No description provided for @onbDobDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get onbDobDay;

  /// No description provided for @onbDobMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get onbDobMonth;

  /// No description provided for @onbDobYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get onbDobYear;

  /// No description provided for @onbContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onbContinue;

  /// No description provided for @onbBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onbBack;

  /// No description provided for @onbLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load data.'**
  String get onbLoadError;

  /// No description provided for @onbSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get onbSubmitError;

  /// No description provided for @consentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use location to suggest people/outings near you'**
  String get consentLocation;

  /// No description provided for @consentPhotos.
  ///
  /// In en, this message translates to:
  /// **'Store & show profile photos (optional)'**
  String get consentPhotos;

  /// No description provided for @consentMatching.
  ///
  /// In en, this message translates to:
  /// **'Use music taste to match people'**
  String get consentMatching;

  /// No description provided for @consentMarketing.
  ///
  /// In en, this message translates to:
  /// **'Receive promotional notifications'**
  String get consentMarketing;

  /// No description provided for @consentCrossBorder.
  ///
  /// In en, this message translates to:
  /// **'Data stored in Singapore (cross-border transfer)'**
  String get consentCrossBorder;

  /// No description provided for @chatPromoteKeo.
  ///
  /// In en, this message translates to:
  /// **'Set up an outing'**
  String get chatPromoteKeo;

  /// No description provided for @sendThisTitle.
  ///
  /// In en, this message translates to:
  /// **'Send this message?'**
  String get sendThisTitle;

  /// No description provided for @sendThisBody.
  ///
  /// In en, this message translates to:
  /// **'This looks like it may share financial or contact info. Send anyway?'**
  String get sendThisBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyTitle;

  /// No description provided for @tosTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get tosTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Download my data'**
  String get exportData;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. Your account and data will be deleted.'**
  String get deleteConfirm;

  /// No description provided for @storeTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrades'**
  String get storeTitle;

  /// No description provided for @boostTitle.
  ///
  /// In en, this message translates to:
  /// **'Boost your outing'**
  String get boostTitle;

  /// No description provided for @seeLikesTitle.
  ///
  /// In en, this message translates to:
  /// **'See who liked you'**
  String get seeLikesTitle;

  /// No description provided for @filtersTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium filters'**
  String get filtersTitle;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @bookVenue.
  ///
  /// In en, this message translates to:
  /// **'Book the venue'**
  String get bookVenue;

  /// No description provided for @entitlementNeeded.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to use this feature'**
  String get entitlementNeeded;

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Connect through songs'**
  String get authTagline;

  /// No description provided for @authPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your phone number'**
  String get authPhoneTitle;

  /// No description provided for @authPhoneBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your number to receive an OTP. We only use it to keep your account safe.'**
  String get authPhoneBody;

  /// No description provided for @authPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'901 234 567'**
  String get authPhoneHint;

  /// No description provided for @authResponsibility.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to use Cùng Hát responsibly and respect others.'**
  String get authResponsibility;

  /// No description provided for @authSendOtpError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send the code'**
  String get authSendOtpError;

  /// No description provided for @authResendCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String authResendCountdown(int seconds);

  /// No description provided for @authResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authResend;

  /// No description provided for @authCheckMessages.
  ///
  /// In en, this message translates to:
  /// **'Check your messages'**
  String get authCheckMessages;

  /// No description provided for @authOtpSentPrefix.
  ///
  /// In en, this message translates to:
  /// **'Code sent to '**
  String get authOtpSentPrefix;

  /// No description provided for @authOtpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {phone}'**
  String authOtpSentTo(String phone);

  /// No description provided for @authPhoneFallback.
  ///
  /// In en, this message translates to:
  /// **'your phone number'**
  String get authPhoneFallback;

  /// No description provided for @authOtpHelp.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get a code? Go back and check your phone number.'**
  String get authOtpHelp;

  /// No description provided for @authOtpError.
  ///
  /// In en, this message translates to:
  /// **'That OTP code isn\'t correct'**
  String get authOtpError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
