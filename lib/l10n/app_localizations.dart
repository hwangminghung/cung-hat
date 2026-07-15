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

  /// No description provided for @onbConsentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how Cùng Hát uses your data'**
  String get onbConsentSubtitle;

  /// No description provided for @onbRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get onbRequired;

  /// No description provided for @onbConsentContinue.
  ///
  /// In en, this message translates to:
  /// **'Agree & continue'**
  String get onbConsentContinue;

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
  /// **'Set up your profile'**
  String get onbStepProfile;

  /// No description provided for @onbProfileQuestion.
  ///
  /// In en, this message translates to:
  /// **'What would you like everyone to call you?'**
  String get onbProfileQuestion;

  /// No description provided for @onbStepTaste.
  ///
  /// In en, this message translates to:
  /// **'Music taste'**
  String get onbStepTaste;

  /// No description provided for @onbTasteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a few things you listen to'**
  String get onbTasteSubtitle;

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
  /// **'Store and show profile photos'**
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
  /// **'I agree to the Privacy Policy, Terms, and data storage in Singapore'**
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

  /// No description provided for @discoveryDeckTitle.
  ///
  /// In en, this message translates to:
  /// **'Singing pairs'**
  String get discoveryDeckTitle;

  /// No description provided for @discoveryDeckSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Music-compatible suggestions at a safe distance.'**
  String get discoveryDeckSubtitle;

  /// No description provided for @discoveryRewind.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get discoveryRewind;

  /// No description provided for @discoveryPass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get discoveryPass;

  /// No description provided for @discoverySuperLike.
  ///
  /// In en, this message translates to:
  /// **'Super like'**
  String get discoverySuperLike;

  /// No description provided for @discoveryLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get discoveryLike;

  /// No description provided for @discoveryExploreTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore by music taste'**
  String get discoveryExploreTitle;

  /// No description provided for @discoveryExploreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a mood and meet someone on your wavelength.'**
  String get discoveryExploreSubtitle;

  /// No description provided for @discoveryExploreOpen.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get discoveryExploreOpen;

  /// No description provided for @discoveryExploreLiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count} people singing'**
  String discoveryExploreLiveCount(int count);

  /// No description provided for @discoveryExploreBrand.
  ///
  /// In en, this message translates to:
  /// **'CÙNG HÁT'**
  String get discoveryExploreBrand;

  /// No description provided for @tabChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get tabChat;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @shellTileLikes.
  ///
  /// In en, this message translates to:
  /// **'Who liked you'**
  String get shellTileLikes;

  /// No description provided for @shellTileLikesSub.
  ///
  /// In en, this message translates to:
  /// **'See everyone who sent you a heart'**
  String get shellTileLikesSub;

  /// No description provided for @shellTileUpgradeSub.
  ///
  /// In en, this message translates to:
  /// **'Pro, keo boosts and advanced filters'**
  String get shellTileUpgradeSub;

  /// No description provided for @shellTilePhotos.
  ///
  /// In en, this message translates to:
  /// **'Profile photos'**
  String get shellTilePhotos;

  /// No description provided for @shellTilePhotosSub.
  ///
  /// In en, this message translates to:
  /// **'Add up to 6 photos to your profile'**
  String get shellTilePhotosSub;

  /// No description provided for @shellTilePrompts.
  ///
  /// In en, this message translates to:
  /// **'Prompt cards'**
  String get shellTilePrompts;

  /// No description provided for @shellTilePromptsSub.
  ///
  /// In en, this message translates to:
  /// **'Pick up to 3 prompts to spark conversations'**
  String get shellTilePromptsSub;

  /// No description provided for @shellTileSettingsSub.
  ///
  /// In en, this message translates to:
  /// **'Privacy, data and legal'**
  String get shellTileSettingsSub;

  /// No description provided for @shellProfileSub.
  ///
  /// In en, this message translates to:
  /// **'Manage likes, upgrades and settings.'**
  String get shellProfileSub;

  /// No description provided for @completionPercent.
  ///
  /// In en, this message translates to:
  /// **'Profile {percent}% complete'**
  String completionPercent(int percent);

  /// No description provided for @completionAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add your first photo → get seen way more'**
  String get completionAddPhoto;

  /// No description provided for @completionThreePhotos.
  ///
  /// In en, this message translates to:
  /// **'3 photos → 2x more views'**
  String get completionThreePhotos;

  /// No description provided for @completionWriteBio.
  ///
  /// In en, this message translates to:
  /// **'Write a bio → +25% matches'**
  String get completionWriteBio;

  /// No description provided for @completionPickGenres.
  ///
  /// In en, this message translates to:
  /// **'Pick 3 genres → sharper suggestions'**
  String get completionPickGenres;

  /// No description provided for @completionAddArtist.
  ///
  /// In en, this message translates to:
  /// **'Add a favourite artist'**
  String get completionAddArtist;

  /// No description provided for @completionAddBaitu.
  ///
  /// In en, this message translates to:
  /// **'Add 3 go-to songs → easier to join a keo'**
  String get completionAddBaitu;

  /// No description provided for @completionAnswerPrompts.
  ///
  /// In en, this message translates to:
  /// **'Answer 2 prompts → instant icebreakers'**
  String get completionAnswerPrompts;

  /// No description provided for @upsellCta.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upsellCta;

  /// No description provided for @upsellLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get upsellLater;

  /// No description provided for @upsellAllProPerks.
  ///
  /// In en, this message translates to:
  /// **'Plus every other Pro perk'**
  String get upsellAllProPerks;

  /// No description provided for @upsellBoostTitle.
  ///
  /// In en, this message translates to:
  /// **'Boost your profile'**
  String get upsellBoostTitle;

  /// No description provided for @upsellBoostB1.
  ///
  /// In en, this message translates to:
  /// **'One 30-minute Boost every day'**
  String get upsellBoostB1;

  /// No description provided for @upsellBoostB2.
  ///
  /// In en, this message translates to:
  /// **'Jump to the top of nearby decks'**
  String get upsellBoostB2;

  /// No description provided for @upsellRewindTitle.
  ///
  /// In en, this message translates to:
  /// **'Rewind your swipe'**
  String get upsellRewindTitle;

  /// No description provided for @upsellRewindB1.
  ///
  /// In en, this message translates to:
  /// **'Passed by mistake? Undo your last swipe'**
  String get upsellRewindB1;

  /// No description provided for @upsellRewindB2.
  ///
  /// In en, this message translates to:
  /// **'Unlimited rewinds'**
  String get upsellRewindB2;

  /// No description provided for @upsellSeeLikesTitle.
  ///
  /// In en, this message translates to:
  /// **'See who liked you'**
  String get upsellSeeLikesTitle;

  /// No description provided for @upsellSeeLikesB1.
  ///
  /// In en, this message translates to:
  /// **'Unlock the list of people who liked you'**
  String get upsellSeeLikesB1;

  /// No description provided for @upsellSeeLikesB2.
  ///
  /// In en, this message translates to:
  /// **'Match instantly — no lucky swipe needed'**
  String get upsellSeeLikesB2;

  /// No description provided for @upsellKeoCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your own keo'**
  String get upsellKeoCreateTitle;

  /// No description provided for @upsellKeoCreateB1.
  ///
  /// In en, this message translates to:
  /// **'Host it your way: venue, time, members'**
  String get upsellKeoCreateB1;

  /// No description provided for @upsellKeoCreateB2.
  ///
  /// In en, this message translates to:
  /// **'Open or approval-only — you decide'**
  String get upsellKeoCreateB2;

  /// No description provided for @upsellKeoJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join multiple keo at once'**
  String get upsellKeoJoinTitle;

  /// No description provided for @upsellKeoJoinB1.
  ///
  /// In en, this message translates to:
  /// **'Free accounts get 1 active keo'**
  String get upsellKeoJoinB1;

  /// No description provided for @upsellKeoJoinB2.
  ///
  /// In en, this message translates to:
  /// **'Pro joins unlimited keo'**
  String get upsellKeoJoinB2;

  /// No description provided for @upsellLikeQuotaTitle.
  ///
  /// In en, this message translates to:
  /// **'Out of likes for today'**
  String get upsellLikeQuotaTitle;

  /// No description provided for @upsellLikeQuotaB1.
  ///
  /// In en, this message translates to:
  /// **'Pro gets unlimited daily likes'**
  String get upsellLikeQuotaB1;

  /// No description provided for @upsellLikeQuotaB2.
  ///
  /// In en, this message translates to:
  /// **'5 Super Likes every day'**
  String get upsellLikeQuotaB2;

  /// No description provided for @upsellSuperQuotaTitle.
  ///
  /// In en, this message translates to:
  /// **'Out of Super Likes for today'**
  String get upsellSuperQuotaTitle;

  /// No description provided for @upsellSuperQuotaB1.
  ///
  /// In en, this message translates to:
  /// **'Pro gets 5 Super Likes a day'**
  String get upsellSuperQuotaB1;

  /// No description provided for @upsellSuperQuotaB2.
  ///
  /// In en, this message translates to:
  /// **'Super Likes make you 3x more visible'**
  String get upsellSuperQuotaB2;

  /// No description provided for @onbLoadRetrySub.
  ///
  /// In en, this message translates to:
  /// **'Try again in a few minutes.'**
  String get onbLoadRetrySub;

  /// No description provided for @onbTasteEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No music data yet'**
  String get onbTasteEmptyTitle;

  /// No description provided for @onbTasteEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Check the seed data or try reloading in a few minutes.'**
  String get onbTasteEmptySub;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get commonCheckConnection;

  /// No description provided for @commonSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the setting, try again.'**
  String get commonSaveError;

  /// No description provided for @deckErrorLikeLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'re out of likes for today. Upgrade to Pro for unlimited likes.'**
  String get deckErrorLikeLimit;

  /// No description provided for @deckErrorSuperLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'re out of Super Likes for today.'**
  String get deckErrorSuperLimit;

  /// No description provided for @deckErrorProRequired.
  ///
  /// In en, this message translates to:
  /// **'This feature is for Pro members.'**
  String get deckErrorProRequired;

  /// No description provided for @deckErrorBoostActive.
  ///
  /// In en, this message translates to:
  /// **'You already have a boost running.'**
  String get deckErrorBoostActive;

  /// No description provided for @deckErrorBoostLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used today\'s boost. Try again tomorrow.'**
  String get deckErrorBoostLimit;

  /// No description provided for @deckErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your swipe. Try again later.'**
  String get deckErrorUnknown;

  /// No description provided for @candidateFallbackName.
  ///
  /// In en, this message translates to:
  /// **'New singer'**
  String get candidateFallbackName;

  /// No description provided for @commonReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get commonReport;

  /// No description provided for @candidateViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get candidateViewProfile;

  /// No description provided for @candidateOnlineToday.
  ///
  /// In en, this message translates to:
  /// **'Online today'**
  String get candidateOnlineToday;

  /// No description provided for @candidateDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'{band} km away'**
  String candidateDistanceKm(String band);

  /// No description provided for @candidateSharedBaitu.
  ///
  /// In en, this message translates to:
  /// **'{count} shared go-to songs'**
  String candidateSharedBaitu(int count);

  /// No description provided for @candidateNoSharedGenres.
  ///
  /// In en, this message translates to:
  /// **'No shared genres yet'**
  String get candidateNoSharedGenres;

  /// No description provided for @candidateNoBio.
  ///
  /// In en, this message translates to:
  /// **'No bio yet — ask them when you match!'**
  String get candidateNoBio;

  /// No description provided for @candidatePhotoQuote.
  ///
  /// In en, this message translates to:
  /// **'This photo is so cool! '**
  String get candidatePhotoQuote;

  /// No description provided for @candidateReplyPhoto.
  ///
  /// In en, this message translates to:
  /// **'Reply to this photo'**
  String get candidateReplyPhoto;

  /// No description provided for @candidateSharedGenresTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared music taste'**
  String get candidateSharedGenresTitle;

  /// No description provided for @candidateNoSharedGenresDot.
  ///
  /// In en, this message translates to:
  /// **'No overlapping genres yet.'**
  String get candidateNoSharedGenresDot;

  /// No description provided for @candidateSharedBaituTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared go-to songs'**
  String get candidateSharedBaituTitle;

  /// No description provided for @candidateNoSharedBaitu.
  ///
  /// In en, this message translates to:
  /// **'No shared songs yet — room to explore!'**
  String get candidateNoSharedBaitu;

  /// No description provided for @candidateSongQuote.
  ///
  /// In en, this message translates to:
  /// **'About your song \"{title}\": '**
  String candidateSongQuote(String title);

  /// No description provided for @candidateReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get candidateReply;

  /// No description provided for @candidatePromptQuote.
  ///
  /// In en, this message translates to:
  /// **'You said \"{answer}\" — tell me more: '**
  String candidatePromptQuote(String answer);

  /// No description provided for @candidateReportBlock.
  ///
  /// In en, this message translates to:
  /// **'Report / Block'**
  String get candidateReportBlock;

  /// No description provided for @exploreFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get exploreFallbackTitle;

  /// No description provided for @deckLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load suggestions'**
  String get deckLoadErrorTitle;

  /// No description provided for @deckPromoSeeKeo.
  ///
  /// In en, this message translates to:
  /// **'SEE KEO'**
  String get deckPromoSeeKeo;

  /// No description provided for @deckExploreTooltip.
  ///
  /// In en, this message translates to:
  /// **'Explore by music taste'**
  String get deckExploreTooltip;

  /// No description provided for @deckRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get deckRefreshTooltip;

  /// No description provided for @deckSearching100.
  ///
  /// In en, this message translates to:
  /// **'Searching within 100 km'**
  String get deckSearching100;

  /// No description provided for @deckBoostingUntil.
  ///
  /// In en, this message translates to:
  /// **'Boosting until {time}'**
  String deckBoostingUntil(String time);

  /// No description provided for @deckBoostTooltip.
  ///
  /// In en, this message translates to:
  /// **'Boost profile'**
  String get deckBoostTooltip;

  /// No description provided for @deckBoostStarted.
  ///
  /// In en, this message translates to:
  /// **'Boosting for 30 minutes — your profile is prioritized nearby.'**
  String get deckBoostStarted;

  /// No description provided for @celebrateYouFallback.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get celebrateYouFallback;

  /// No description provided for @deckExhausted100.
  ///
  /// In en, this message translates to:
  /// **'Searched everything within 100 km'**
  String get deckExhausted100;

  /// No description provided for @deckEmptyNearby.
  ///
  /// In en, this message translates to:
  /// **'No singers nearby yet'**
  String get deckEmptyNearby;

  /// No description provided for @deckExpand100.
  ///
  /// In en, this message translates to:
  /// **'Expand search to 100 km'**
  String get deckExpand100;

  /// No description provided for @deckRefreshSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Refresh suggestions'**
  String get deckRefreshSuggestions;

  /// No description provided for @deckAutoExpandTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-expand when you run out'**
  String get deckAutoExpandTitle;

  /// No description provided for @deckAutoExpandSub.
  ///
  /// In en, this message translates to:
  /// **'Automatically search 100 km once 50 km is empty'**
  String get deckAutoExpandSub;

  /// No description provided for @filterApplied.
  ///
  /// In en, this message translates to:
  /// **'Filters applied.'**
  String get filterApplied;

  /// No description provided for @filterSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save, try again.'**
  String get filterSaveError;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filterTitle;

  /// No description provided for @filterRadius.
  ///
  /// In en, this message translates to:
  /// **'Search radius'**
  String get filterRadius;

  /// No description provided for @filterAutoExpandSub.
  ///
  /// In en, this message translates to:
  /// **'Search 100 km when suggestions run out'**
  String get filterAutoExpandSub;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApply;

  /// No description provided for @promoKeoNearby.
  ///
  /// In en, this message translates to:
  /// **'🎤 Keo near you'**
  String get promoKeoNearby;

  /// No description provided for @promoSeats.
  ///
  /// In en, this message translates to:
  /// **'{filled}/{target} seats'**
  String promoSeats(int filled, int target);

  /// No description provided for @promoDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'{band} km away'**
  String promoDistanceKm(String band);

  /// No description provided for @promoSwipeRight.
  ///
  /// In en, this message translates to:
  /// **'Swipe right to view the keo →'**
  String get promoSwipeRight;

  /// No description provided for @likesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No likes yet'**
  String get likesEmptyTitle;

  /// No description provided for @likesEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Keep singing your heart out — the right people will come.'**
  String get likesEmptySub;

  /// No description provided for @likesAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get likesAnonymous;

  /// No description provided for @likesLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock to see who liked you'**
  String get likesLockedTitle;

  /// No description provided for @teaserLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the list'**
  String get teaserLoadError;

  /// No description provided for @teaserEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to get seen more.'**
  String get teaserEmptySub;

  /// No description provided for @teaserCount.
  ///
  /// In en, this message translates to:
  /// **'{count} people liked you'**
  String teaserCount(int count);

  /// No description provided for @teaserUnlockCta.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Pro — see who likes you'**
  String get teaserUnlockCta;

  /// No description provided for @celebrateTitle.
  ///
  /// In en, this message translates to:
  /// **'It\'s a match!'**
  String get celebrateTitle;

  /// No description provided for @celebrateBody.
  ///
  /// In en, this message translates to:
  /// **'You and {name} liked each other'**
  String celebrateBody(String name);

  /// No description provided for @celebrateSharedBaitu.
  ///
  /// In en, this message translates to:
  /// **'Shared songs: {songs}'**
  String celebrateSharedBaitu(String songs);

  /// No description provided for @celebrateChatNow.
  ///
  /// In en, this message translates to:
  /// **'Chat now'**
  String get celebrateChatNow;

  /// No description provided for @celebrateContinue.
  ///
  /// In en, this message translates to:
  /// **'Keep exploring'**
  String get celebrateContinue;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report: {reason}'**
  String reportTitle(String reason);

  /// No description provided for @reportBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Block this user'**
  String get reportBlockUser;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent.'**
  String get reportSent;

  /// No description provided for @reportSendError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the report.'**
  String get reportSendError;

  /// No description provided for @reportBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked.'**
  String get reportBlocked;

  /// No description provided for @reportBlockError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t block.'**
  String get reportBlockError;

  /// No description provided for @exploreOpenSemantics.
  ///
  /// In en, this message translates to:
  /// **'Open {title}'**
  String exploreOpenSemantics(String title);
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
