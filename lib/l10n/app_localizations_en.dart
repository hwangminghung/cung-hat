// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cùng Hát';

  @override
  String get tabDoi => 'Đôi';

  @override
  String get tabKeo => 'Kèo';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get authTitle => 'Sign in';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get otpTitle => 'Enter OTP';

  @override
  String get otpLabel => '6-digit code';

  @override
  String get verify => 'Confirm';

  @override
  String get onbDobTitle => 'When were you born? (must be 18+)';

  @override
  String get onbUnder18 => 'You must be 18 or older to use the app.';

  @override
  String get onbConsentTitle => 'Privacy';

  @override
  String get onbNameLabel => 'Display name';

  @override
  String get onbBioLabel => 'Bio';

  @override
  String get onbTasteGenres => 'Genres';

  @override
  String get onbTasteArtists => 'Artists';

  @override
  String get onbBaitu => 'Signature songs';

  @override
  String get onbFinish => 'Finish';

  @override
  String get onbConsentRequired =>
      'Please agree to the required permissions to continue.';

  @override
  String get onbSetupTitle => 'Set up your profile';

  @override
  String get onbStepDob => 'Date of birth';

  @override
  String get onbStepProfile => 'Profile';

  @override
  String get onbStepTaste => 'Music taste';

  @override
  String get onbContinue => 'Continue';

  @override
  String get onbBack => 'Back';

  @override
  String get onbLoadError => 'Couldn\'t load data.';

  @override
  String get onbSubmitError => 'Something went wrong. Please try again.';

  @override
  String get consentLocation =>
      'Use location to suggest people/outings near you';

  @override
  String get consentPhotos => 'Store & show profile photos (optional)';

  @override
  String get consentMatching => 'Use music taste to match people';

  @override
  String get consentMarketing => 'Receive promotional notifications';

  @override
  String get consentCrossBorder =>
      'Data stored in Singapore (cross-border transfer)';

  @override
  String get chatPromoteKeo => 'Set up an outing';

  @override
  String get sendThisTitle => 'Send this message?';

  @override
  String get sendThisBody =>
      'This looks like it may share financial or contact info. Send anyway?';

  @override
  String get cancel => 'Cancel';

  @override
  String get send => 'Send';

  @override
  String get privacyTitle => 'Privacy Policy';

  @override
  String get tosTitle => 'Terms of Service';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get exportData => 'Download my data';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteConfirm =>
      'This action cannot be undone. Your account and data will be deleted.';

  @override
  String get storeTitle => 'Upgrades';

  @override
  String get boostTitle => 'Boost your outing';

  @override
  String get seeLikesTitle => 'See who liked you';

  @override
  String get filtersTitle => 'Premium filters';

  @override
  String get buy => 'Buy';

  @override
  String get bookVenue => 'Book the venue';

  @override
  String get entitlementNeeded => 'Upgrade to use this feature';

  @override
  String get authTagline => 'Connect through songs';

  @override
  String get authPhoneTitle => 'Sign in with your phone number';

  @override
  String get authPhoneBody =>
      'Enter your number to receive an OTP. We only use it to keep your account safe.';

  @override
  String get authPhoneHint => '901 234 567';

  @override
  String get authResponsibility =>
      'By continuing, you agree to use Cùng Hát responsibly and respect others.';

  @override
  String get authSendOtpError => 'We couldn\'t send the code';

  @override
  String authResendCountdown(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get authResend => 'Resend code';

  @override
  String get authCheckMessages => 'Check your messages';

  @override
  String authOtpSentTo(String phone) {
    return 'Code sent to $phone';
  }

  @override
  String get authPhoneFallback => 'your phone number';

  @override
  String get authOtpHelp =>
      'Didn\'t get a code? Go back and check your phone number.';

  @override
  String get authOtpError => 'That OTP code isn\'t correct';
}
