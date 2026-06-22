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
}
