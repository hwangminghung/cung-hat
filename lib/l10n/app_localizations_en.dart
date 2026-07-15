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
  String get onbDobTitle => 'When were you born?';

  @override
  String get onbUnder18 => 'You must be 18 or older to use the app.';

  @override
  String get onbConsentTitle => 'Privacy';

  @override
  String get onbConsentSubtitle => 'Choose how Cùng Hát uses your data';

  @override
  String get onbRequired => 'Required';

  @override
  String get onbConsentContinue => 'Agree & continue';

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
  String get onbStepProfile => 'Set up your profile';

  @override
  String get onbProfileQuestion => 'What would you like everyone to call you?';

  @override
  String get onbStepTaste => 'Music taste';

  @override
  String get onbTasteSubtitle => 'Choose a few things you listen to';

  @override
  String onbProgress(int step) {
    return 'Step $step/4';
  }

  @override
  String get onbDobDay => 'Day';

  @override
  String get onbDobMonth => 'Month';

  @override
  String get onbDobYear => 'Year';

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
  String get consentPhotos => 'Store and show profile photos';

  @override
  String get consentMatching => 'Use music taste to match people';

  @override
  String get consentMarketing => 'Receive promotional notifications';

  @override
  String get consentCrossBorder =>
      'I agree to the Privacy Policy, Terms, and data storage in Singapore';

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
  String get authOtpSentPrefix => 'Code sent to ';

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

  @override
  String get discoveryDeckTitle => 'Singing pairs';

  @override
  String get discoveryDeckSubtitle =>
      'Music-compatible suggestions at a safe distance.';

  @override
  String get discoveryRewind => 'Undo';

  @override
  String get discoveryPass => 'Pass';

  @override
  String get discoverySuperLike => 'Super like';

  @override
  String get discoveryLike => 'Like';

  @override
  String get discoveryExploreTitle => 'Explore by music taste';

  @override
  String get discoveryExploreSubtitle =>
      'Pick a mood and meet someone on your wavelength.';

  @override
  String get discoveryExploreOpen => 'Open now';

  @override
  String discoveryExploreLiveCount(int count) {
    return '$count people singing';
  }

  @override
  String get discoveryExploreBrand => 'CÙNG HÁT';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabProfile => 'Profile';

  @override
  String get shellTileLikes => 'Who liked you';

  @override
  String get shellTileLikesSub => 'See everyone who sent you a heart';

  @override
  String get shellTileUpgradeSub => 'Pro, keo boosts and advanced filters';

  @override
  String get shellTilePhotos => 'Profile photos';

  @override
  String get shellTilePhotosSub => 'Add up to 6 photos to your profile';

  @override
  String get shellTilePrompts => 'Prompt cards';

  @override
  String get shellTilePromptsSub =>
      'Pick up to 3 prompts to spark conversations';

  @override
  String get shellTileSettingsSub => 'Privacy, data and legal';

  @override
  String get shellProfileSub => 'Manage likes, upgrades and settings.';

  @override
  String completionPercent(int percent) {
    return 'Profile $percent% complete';
  }

  @override
  String get completionAddPhoto => 'Add your first photo → get seen way more';

  @override
  String get completionThreePhotos => '3 photos → 2x more views';

  @override
  String get completionWriteBio => 'Write a bio → +25% matches';

  @override
  String get completionPickGenres => 'Pick 3 genres → sharper suggestions';

  @override
  String get completionAddArtist => 'Add a favourite artist';

  @override
  String get completionAddBaitu => 'Add 3 go-to songs → easier to join a keo';

  @override
  String get completionAnswerPrompts =>
      'Answer 2 prompts → instant icebreakers';

  @override
  String get upsellCta => 'Upgrade to Pro';

  @override
  String get upsellLater => 'Maybe later';

  @override
  String get upsellAllProPerks => 'Plus every other Pro perk';

  @override
  String get upsellBoostTitle => 'Boost your profile';

  @override
  String get upsellBoostB1 => 'One 30-minute Boost every day';

  @override
  String get upsellBoostB2 => 'Jump to the top of nearby decks';

  @override
  String get upsellRewindTitle => 'Rewind your swipe';

  @override
  String get upsellRewindB1 => 'Passed by mistake? Undo your last swipe';

  @override
  String get upsellRewindB2 => 'Unlimited rewinds';

  @override
  String get upsellSeeLikesTitle => 'See who liked you';

  @override
  String get upsellSeeLikesB1 => 'Unlock the list of people who liked you';

  @override
  String get upsellSeeLikesB2 => 'Match instantly — no lucky swipe needed';

  @override
  String get upsellKeoCreateTitle => 'Create your own keo';

  @override
  String get upsellKeoCreateB1 => 'Host it your way: venue, time, members';

  @override
  String get upsellKeoCreateB2 => 'Open or approval-only — you decide';

  @override
  String get upsellKeoJoinTitle => 'Join multiple keo at once';

  @override
  String get upsellKeoJoinB1 => 'Free accounts get 1 active keo';

  @override
  String get upsellKeoJoinB2 => 'Pro joins unlimited keo';

  @override
  String get upsellLikeQuotaTitle => 'Out of likes for today';

  @override
  String get upsellLikeQuotaB1 => 'Pro gets unlimited daily likes';

  @override
  String get upsellLikeQuotaB2 => '5 Super Likes every day';

  @override
  String get upsellSuperQuotaTitle => 'Out of Super Likes for today';

  @override
  String get upsellSuperQuotaB1 => 'Pro gets 5 Super Likes a day';

  @override
  String get upsellSuperQuotaB2 => 'Super Likes make you 3x more visible';

  @override
  String get onbLoadRetrySub => 'Try again in a few minutes.';

  @override
  String get onbTasteEmptyTitle => 'No music data yet';

  @override
  String get onbTasteEmptySub =>
      'Check the seed data or try reloading in a few minutes.';
}
