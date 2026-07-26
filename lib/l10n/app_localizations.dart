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
  /// **'Store my data on servers located in Singapore'**
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
  /// **'This message looks money- or personal-info-related. Double-check before sending.'**
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
  /// **'Pay at the venue via MoMo/ZaloPay'**
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

  /// No description provided for @authErrorSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the OTP code. Check your phone number and try again.'**
  String get authErrorSendFailed;

  /// No description provided for @authErrorOtpInvalid.
  ///
  /// In en, this message translates to:
  /// **'The OTP code is incorrect or has expired. Please try again.'**
  String get authErrorOtpInvalid;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Can\'t connect. Check your network and try again.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorGeneric;

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
  /// **'Messages'**
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
  /// **'Host unlimited keos'**
  String get upsellKeoCreateTitle;

  /// No description provided for @upsellKeoCreateB1.
  ///
  /// In en, this message translates to:
  /// **'Free keeps 1 open keo — Pro hosts as many as you like'**
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

  /// No description provided for @profileLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your profile'**
  String get profileLoadErrorTitle;

  /// No description provided for @profileLoadErrorSub.
  ///
  /// In en, this message translates to:
  /// **'Your profile is safe. Check your connection and try again.'**
  String get profileLoadErrorSub;

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

  /// No description provided for @keoErrorProRequired.
  ///
  /// In en, this message translates to:
  /// **'You need Pro to create a keo.'**
  String get keoErrorProRequired;

  /// No description provided for @keoErrorFreeHostLimit.
  ///
  /// In en, this message translates to:
  /// **'Free keeps 1 open keo at a time. Cancel it or upgrade to Pro to host more.'**
  String get keoErrorFreeHostLimit;

  /// No description provided for @keoErrorFreeJoinLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'re already in 1 keo. Leave it or upgrade to Pro to join more.'**
  String get keoErrorFreeJoinLimit;

  /// No description provided for @keoErrorFull.
  ///
  /// In en, this message translates to:
  /// **'This keo is full.'**
  String get keoErrorFull;

  /// No description provided for @keoErrorAlreadyDeclined.
  ///
  /// In en, this message translates to:
  /// **'You were declined from this keo.'**
  String get keoErrorAlreadyDeclined;

  /// No description provided for @keoErrorNotOpen.
  ///
  /// In en, this message translates to:
  /// **'This keo is no longer open.'**
  String get keoErrorNotOpen;

  /// No description provided for @keoErrorBlocked.
  ///
  /// In en, this message translates to:
  /// **'You can\'t join this keo due to safety settings.'**
  String get keoErrorBlocked;

  /// No description provided for @keoErrorNoLocation.
  ///
  /// In en, this message translates to:
  /// **'Location is needed to match a keo. Turn on Location and try again.'**
  String get keoErrorNoLocation;

  /// No description provided for @keoErrorAgeNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Verify your age before matching a keo.'**
  String get keoErrorAgeNotVerified;

  /// No description provided for @keoErrorNoMatchableKeo.
  ///
  /// In en, this message translates to:
  /// **'No matching keo found yet, try again later.'**
  String get keoErrorNoMatchableKeo;

  /// No description provided for @keoErrorInvalidTimeWindow.
  ///
  /// In en, this message translates to:
  /// **'Invalid time window. Pick another slot.'**
  String get keoErrorInvalidTimeWindow;

  /// No description provided for @keoErrorInvalidGroupSize.
  ///
  /// In en, this message translates to:
  /// **'Invalid group size.'**
  String get keoErrorInvalidGroupSize;

  /// No description provided for @keoErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong, try again.'**
  String get keoErrorGeneric;

  /// No description provided for @keoModeOpen.
  ///
  /// In en, this message translates to:
  /// **'Open · join instantly'**
  String get keoModeOpen;

  /// No description provided for @keoModeApproval.
  ///
  /// In en, this message translates to:
  /// **'Approval needed'**
  String get keoModeApproval;

  /// No description provided for @keoCardDistance.
  ///
  /// In en, this message translates to:
  /// **'{band} km away'**
  String keoCardDistance(String band);

  /// No description provided for @keoCardPeople.
  ///
  /// In en, this message translates to:
  /// **'{filled}/{target} people'**
  String keoCardPeople(int filled, int target);

  /// No description provided for @keoBoardLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load keo list'**
  String get keoBoardLoadError;

  /// No description provided for @keoBoardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No keo nearby yet'**
  String get keoBoardEmptyTitle;

  /// No description provided for @keoBoardEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Tap match-me to find a fitting keo or create your own.'**
  String get keoBoardEmptySub;

  /// No description provided for @keoCreateCta.
  ///
  /// In en, this message translates to:
  /// **'Create keo'**
  String get keoCreateCta;

  /// No description provided for @keoBoardTitle.
  ///
  /// In en, this message translates to:
  /// **'Keo around you'**
  String get keoBoardTitle;

  /// No description provided for @keoBoardStoreTooltip.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get keoBoardStoreTooltip;

  /// No description provided for @keoBoardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find a singing group that fits your taste, nearby and on schedule.'**
  String get keoBoardSubtitle;

  /// No description provided for @keoBoardMatchMe.
  ///
  /// In en, this message translates to:
  /// **'Match me a group'**
  String get keoBoardMatchMe;

  /// No description provided for @keoBoardMatchMeSub.
  ///
  /// In en, this message translates to:
  /// **'Auto-suggest keo that fit your taste, location and time.'**
  String get keoBoardMatchMeSub;

  /// No description provided for @keoSharedTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared keo'**
  String get keoSharedTitle;

  /// No description provided for @keoSharedLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the keo'**
  String get keoSharedLoadError;

  /// No description provided for @keoSharedNotFound.
  ///
  /// In en, this message translates to:
  /// **'Keo not found'**
  String get keoSharedNotFound;

  /// No description provided for @keoSharedNotFoundSub.
  ///
  /// In en, this message translates to:
  /// **'The link is wrong or the keo was deleted.'**
  String get keoSharedNotFoundSub;

  /// No description provided for @keoSharedExpired.
  ///
  /// In en, this message translates to:
  /// **'Link expired'**
  String get keoSharedExpired;

  /// No description provided for @keoSharedSeats.
  ///
  /// In en, this message translates to:
  /// **'{filled}/{target} seats'**
  String keoSharedSeats(int filled, int target);

  /// No description provided for @keoSharedHost.
  ///
  /// In en, this message translates to:
  /// **'Host: {name}'**
  String keoSharedHost(String name);

  /// No description provided for @keoSharedAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get keoSharedAnonymous;

  /// No description provided for @keoSharedJoinCta.
  ///
  /// In en, this message translates to:
  /// **'View keo & ask to join'**
  String get keoSharedJoinCta;

  /// No description provided for @keoSharedLoginCta.
  ///
  /// In en, this message translates to:
  /// **'Sign in to ask to join'**
  String get keoSharedLoginCta;

  /// No description provided for @keoStatusConfirmedMember.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get keoStatusConfirmedMember;

  /// No description provided for @keoStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get keoStatusApproved;

  /// No description provided for @keoStatusRequested.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get keoStatusRequested;

  /// No description provided for @keoStatusLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get keoStatusLeft;

  /// No description provided for @keoStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get keoStatusDeclined;

  /// No description provided for @keoDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Keo details'**
  String get keoDetailTitle;

  /// No description provided for @keoDetailShareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share keo'**
  String get keoDetailShareTooltip;

  /// No description provided for @keoDetailShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Keo \"{title}\" is looking for singers — join on Cùng Hát: {link}'**
  String keoDetailShareMessage(String title, String link);

  /// No description provided for @keoDetailShareError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the link, try again.'**
  String get keoDetailShareError;

  /// No description provided for @keoDetailMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get keoDetailMembers;

  /// No description provided for @keoDetailApproveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t approve'**
  String get keoDetailApproveError;

  /// No description provided for @keoDetailDeclineError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t decline'**
  String get keoDetailDeclineError;

  /// No description provided for @keoDetailConfirmError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t confirm'**
  String get keoDetailConfirmError;

  /// No description provided for @keoDetailLeaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t leave the keo'**
  String get keoDetailLeaveError;

  /// No description provided for @keoDetailMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count} people in this keo'**
  String keoDetailMemberCount(int count);

  /// No description provided for @keoDetailHostChip.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get keoDetailHostChip;

  /// No description provided for @keoDetailApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get keoDetailApprove;

  /// No description provided for @keoDetailDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get keoDetailDecline;

  /// No description provided for @keoDetailRequestJoin.
  ///
  /// In en, this message translates to:
  /// **'Ask to join'**
  String get keoDetailRequestJoin;

  /// No description provided for @keoDetailConfirmJoin.
  ///
  /// In en, this message translates to:
  /// **'Confirm joining'**
  String get keoDetailConfirmJoin;

  /// No description provided for @keoDetailConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Joining confirmed'**
  String get keoDetailConfirmed;

  /// No description provided for @keoDetailOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Open group chat'**
  String get keoDetailOpenChat;

  /// No description provided for @keoDetailPickVenue.
  ///
  /// In en, this message translates to:
  /// **'Pick the venue'**
  String get keoDetailPickVenue;

  /// No description provided for @keoDetailViewPlan.
  ///
  /// In en, this message translates to:
  /// **'View plan'**
  String get keoDetailViewPlan;

  /// No description provided for @keoDetailLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave keo'**
  String get keoDetailLeave;

  /// No description provided for @keoCreatePick.
  ///
  /// In en, this message translates to:
  /// **'Pick'**
  String get keoCreatePick;

  /// No description provided for @keoCreateNameMissing.
  ///
  /// In en, this message translates to:
  /// **'Enter a keo name'**
  String get keoCreateNameMissing;

  /// No description provided for @keoCreateTimeMissing.
  ///
  /// In en, this message translates to:
  /// **'Pick start and end times'**
  String get keoCreateTimeMissing;

  /// No description provided for @keoCreateTimeOrder.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get keoCreateTimeOrder;

  /// No description provided for @keoCreateNoLocation.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your location. Turn on Location and try again.'**
  String get keoCreateNoLocation;

  /// No description provided for @keoCreateHeadline.
  ///
  /// In en, this message translates to:
  /// **'Invite a group to sing'**
  String get keoCreateHeadline;

  /// No description provided for @keoCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the time, music taste and how members join.'**
  String get keoCreateSubtitle;

  /// No description provided for @keoCreateNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Keo name'**
  String get keoCreateNameLabel;

  /// No description provided for @keoCreateNameHint.
  ///
  /// In en, this message translates to:
  /// **'V-Pop tonight'**
  String get keoCreateNameHint;

  /// No description provided for @keoCreateAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get keoCreateAreaLabel;

  /// No description provided for @keoCreateAreaHint.
  ///
  /// In en, this message translates to:
  /// **'District 1, Ho Chi Minh City'**
  String get keoCreateAreaHint;

  /// No description provided for @keoCreateVenueLater.
  ///
  /// In en, this message translates to:
  /// **'Pick the venue after creating'**
  String get keoCreateVenueLater;

  /// No description provided for @keoCreateVenueLaterSub.
  ///
  /// In en, this message translates to:
  /// **'The host picks the venue on the Plan screen.'**
  String get keoCreateVenueLaterSub;

  /// No description provided for @keoCreateStart.
  ///
  /// In en, this message translates to:
  /// **'Start: {time}'**
  String keoCreateStart(String time);

  /// No description provided for @keoCreateEnd.
  ///
  /// In en, this message translates to:
  /// **'End: {time}'**
  String keoCreateEnd(String time);

  /// No description provided for @keoCreateSize.
  ///
  /// In en, this message translates to:
  /// **'Group size'**
  String get keoCreateSize;

  /// No description provided for @keoCreateSizeN.
  ///
  /// In en, this message translates to:
  /// **'{n} people'**
  String keoCreateSizeN(int n);

  /// No description provided for @keoCreateGenres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get keoCreateGenres;

  /// No description provided for @keoCreateGenresError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load genres'**
  String get keoCreateGenresError;

  /// No description provided for @keoCreateJoinMode.
  ///
  /// In en, this message translates to:
  /// **'Join mode'**
  String get keoCreateJoinMode;

  /// No description provided for @keoCreateModeApproval.
  ///
  /// In en, this message translates to:
  /// **'Approval'**
  String get keoCreateModeApproval;

  /// No description provided for @keoCreateModeOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get keoCreateModeOpen;

  /// No description provided for @keoMatchNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No matching keo found yet. Try again later.'**
  String get keoMatchNoneFound;

  /// No description provided for @keoMatchExistingTitle.
  ///
  /// In en, this message translates to:
  /// **'A keo that fits you'**
  String get keoMatchExistingTitle;

  /// No description provided for @keoMatchNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Found a matching group'**
  String get keoMatchNewTitle;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @keoMatchReasonSharedGenres.
  ///
  /// In en, this message translates to:
  /// **'Shared taste'**
  String get keoMatchReasonSharedGenres;

  /// No description provided for @keoMatchReasonNearYou.
  ///
  /// In en, this message translates to:
  /// **'Near you'**
  String get keoMatchReasonNearYou;

  /// No description provided for @keoMatchReasonEveningSlot.
  ///
  /// In en, this message translates to:
  /// **'Great time slot'**
  String get keoMatchReasonEveningSlot;

  /// No description provided for @keoMatchReasonOpenJoin.
  ///
  /// In en, this message translates to:
  /// **'Instant join'**
  String get keoMatchReasonOpenJoin;

  /// No description provided for @keoMatchReasonAvailableSlots.
  ///
  /// In en, this message translates to:
  /// **'Seats left'**
  String get keoMatchReasonAvailableSlots;

  /// No description provided for @keoMatchReasonActiveHost.
  ///
  /// In en, this message translates to:
  /// **'Host online'**
  String get keoMatchReasonActiveHost;

  /// No description provided for @chatShareSongTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send a go-to song'**
  String get chatShareSongTooltip;

  /// No description provided for @chatComposerHint.
  ///
  /// In en, this message translates to:
  /// **'Say something...'**
  String get chatComposerHint;

  /// No description provided for @chatSendError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the message. Try again later.'**
  String get chatSendError;

  /// No description provided for @chatProfileError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the profile. Try again later.'**
  String get chatProfileError;

  /// No description provided for @chatProfileGone.
  ///
  /// In en, this message translates to:
  /// **'Profile no longer available.'**
  String get chatProfileGone;

  /// No description provided for @chatUnmatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Unmatch?'**
  String get chatUnmatchTitle;

  /// No description provided for @chatUnmatchBody.
  ///
  /// In en, this message translates to:
  /// **'You two won\'t be able to message each other anymore.'**
  String get chatUnmatchBody;

  /// No description provided for @chatUnmatchCta.
  ///
  /// In en, this message translates to:
  /// **'Unmatch'**
  String get chatUnmatchCta;

  /// No description provided for @chatUnmatchError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t unmatch, try again later'**
  String get chatUnmatchError;

  /// No description provided for @chatEmptyMatch.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Break the ice with a go-to song.'**
  String get chatEmptyMatch;

  /// No description provided for @chatEmptyKeo.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Open with one of your go-to songs.'**
  String get chatEmptyKeo;

  /// No description provided for @chatHistoryError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load messages'**
  String get chatHistoryError;

  /// No description provided for @chatGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Group chat'**
  String get chatGroupTitle;

  /// No description provided for @chatGroupRules.
  ///
  /// In en, this message translates to:
  /// **'Group rules'**
  String get chatGroupRules;

  /// No description provided for @chatGroupRulesBody.
  ///
  /// In en, this message translates to:
  /// **'No filming/photos without consent · Split costs clearly · Respect privacy'**
  String get chatGroupRulesBody;

  /// No description provided for @chatKeoNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Group chat isn\'t open yet. Everyone must confirm joining first.'**
  String get chatKeoNotOpen;

  /// No description provided for @chatToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chatToday;

  /// No description provided for @songShareEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t picked any go-to songs. Add some in your Profile.'**
  String get songShareEmpty;

  /// No description provided for @inboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get inboxTitle;

  /// No description provided for @inboxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where conversations live once you match.'**
  String get inboxSubtitle;

  /// No description provided for @inboxSectionKeo.
  ///
  /// In en, this message translates to:
  /// **'Your keo'**
  String get inboxSectionKeo;

  /// No description provided for @inboxSectionMatches.
  ///
  /// In en, this message translates to:
  /// **'Direct messages'**
  String get inboxSectionMatches;

  /// No description provided for @inboxTurnFirst.
  ///
  /// In en, this message translates to:
  /// **'Say hi first'**
  String get inboxTurnFirst;

  /// No description provided for @inboxTurnYours.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get inboxTurnYours;

  /// No description provided for @inboxReady.
  ///
  /// In en, this message translates to:
  /// **'Ready for a karaoke invite'**
  String get inboxReady;

  /// No description provided for @inboxEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get inboxEmptyTitle;

  /// No description provided for @inboxEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Join a kèo to start chatting with new friends.'**
  String get inboxEmptySub;

  /// No description provided for @inboxFindKeo.
  ///
  /// In en, this message translates to:
  /// **'Find a kèo'**
  String get inboxFindKeo;

  /// No description provided for @inboxLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load conversations'**
  String get inboxLoadError;

  /// No description provided for @keoStateOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get keoStateOpen;

  /// No description provided for @keoStateFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get keoStateFull;

  /// No description provided for @keoStatePlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get keoStatePlanning;

  /// No description provided for @keoStateConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get keoStateConfirmed;

  /// No description provided for @bookingPickGateway.
  ///
  /// In en, this message translates to:
  /// **'Pick a payment gateway'**
  String get bookingPickGateway;

  /// No description provided for @bookingNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Payment gateway not configured yet'**
  String get bookingNotConfigured;

  /// No description provided for @bookingCreateError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the payment'**
  String get bookingCreateError;

  /// No description provided for @planStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get planStatusConfirmed;

  /// No description provided for @planStatusProposed.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval'**
  String get planStatusProposed;

  /// No description provided for @planVenuePicked.
  ///
  /// In en, this message translates to:
  /// **'Chosen venue'**
  String get planVenuePicked;

  /// No description provided for @planTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planTitle;

  /// No description provided for @planLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the plan'**
  String get planLoadError;

  /// No description provided for @planNoVenuesTitle.
  ///
  /// In en, this message translates to:
  /// **'No venue suggestions yet'**
  String get planNoVenuesTitle;

  /// No description provided for @planNoVenuesSub.
  ///
  /// In en, this message translates to:
  /// **'Once venue data arrives from Places or seed, the map will show markers to pick a meeting spot.'**
  String get planNoVenuesSub;

  /// No description provided for @planReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get planReload;

  /// No description provided for @planVenuesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the venue list'**
  String get planVenuesLoadError;

  /// No description provided for @planTime.
  ///
  /// In en, this message translates to:
  /// **'Time: {time}'**
  String planTime(String time);

  /// No description provided for @planStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String planStatus(String status);

  /// No description provided for @planConfirmCta.
  ///
  /// In en, this message translates to:
  /// **'Approve the plan'**
  String get planConfirmCta;

  /// No description provided for @planCancelCta.
  ///
  /// In en, this message translates to:
  /// **'Cancel plan'**
  String get planCancelCta;

  /// No description provided for @planCancelConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this plan?'**
  String get planCancelConfirmTitle;

  /// No description provided for @planCancelConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The group returns to venue planning so you can propose again.'**
  String get planCancelConfirmBody;

  /// No description provided for @planCancelError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t cancel the plan'**
  String get planCancelError;

  /// No description provided for @planConfirmedCount.
  ///
  /// In en, this message translates to:
  /// **'Confirmed {n}/{total}'**
  String planConfirmedCount(int n, int total);

  /// No description provided for @planConfirmError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t approve'**
  String get planConfirmError;

  /// No description provided for @planMapError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the map'**
  String get planMapError;

  /// No description provided for @planDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get planDirections;

  /// No description provided for @planSuggestReason.
  ///
  /// In en, this message translates to:
  /// **'Suggested for being near the group midpoint · {band} km away'**
  String planSuggestReason(String band);

  /// No description provided for @planPickVenue.
  ///
  /// In en, this message translates to:
  /// **'Pick this venue'**
  String get planPickVenue;

  /// No description provided for @planProposed.
  ///
  /// In en, this message translates to:
  /// **'Plan proposed'**
  String get planProposed;

  /// No description provided for @planProposeError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t propose'**
  String get planProposeError;

  /// No description provided for @planPickSchedule.
  ///
  /// In en, this message translates to:
  /// **'Pick a singing time'**
  String get planPickSchedule;

  /// No description provided for @planOtherTime.
  ///
  /// In en, this message translates to:
  /// **'Another time'**
  String get planOtherTime;

  /// No description provided for @planProposeCta.
  ///
  /// In en, this message translates to:
  /// **'Propose the plan'**
  String get planProposeCta;

  /// No description provided for @safetyShare.
  ///
  /// In en, this message translates to:
  /// **'Share with friends'**
  String get safetyShare;

  /// No description provided for @safetyShareMessage.
  ///
  /// In en, this message translates to:
  /// **'I\'m going karaoke, here\'s the plan: {link}'**
  String safetyShareMessage(String link);

  /// No description provided for @safetyShareError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the share link'**
  String get safetyShareError;

  /// No description provided for @safetyArrived.
  ///
  /// In en, this message translates to:
  /// **'I\'ve arrived'**
  String get safetyArrived;

  /// No description provided for @safetyArrivedOk.
  ///
  /// In en, this message translates to:
  /// **'Arrival recorded'**
  String get safetyArrivedOk;

  /// No description provided for @safetyArrivedError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t record it'**
  String get safetyArrivedError;

  /// No description provided for @planSharedTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared plan'**
  String get planSharedTitle;

  /// No description provided for @planSharedNotFound.
  ///
  /// In en, this message translates to:
  /// **'Plan not found'**
  String get planSharedNotFound;

  /// No description provided for @planMidpointMarker.
  ///
  /// In en, this message translates to:
  /// **'Group midpoint'**
  String get planMidpointMarker;

  /// No description provided for @planTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tmrw'**
  String get planTomorrow;

  /// No description provided for @planWeekdaysShort.
  ///
  /// In en, this message translates to:
  /// **'Mon,Tue,Wed,Thu,Fri,Sat,Sun'**
  String get planWeekdaysShort;

  /// No description provided for @settingsSectionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsSectionPrivacy;

  /// No description provided for @settingsSectionData.
  ///
  /// In en, this message translates to:
  /// **'My data'**
  String get settingsSectionData;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSectionAccount;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @settingsSectionSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get settingsSectionSafety;

  /// No description provided for @settingsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get settingsBlocked;

  /// No description provided for @settingsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get settingsAdmin;

  /// No description provided for @blockedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get blockedEmptyTitle;

  /// No description provided for @blockedEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'People you block will appear here.'**
  String get blockedEmptySubtitle;

  /// No description provided for @blockedUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get blockedUnblock;

  /// No description provided for @blockedUnblockError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t unblock. Please try again.'**
  String get blockedUnblockError;

  /// No description provided for @blockedLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the list. Please try again.'**
  String get blockedLoadError;

  /// No description provided for @settingsSectionLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get settingsSectionLegal;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get settingsTerms;

  /// No description provided for @settingsExportError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t export your data. Please try again.'**
  String get settingsExportError;

  /// No description provided for @settingsDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the account, try again.'**
  String get settingsDeleteError;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @storeProDesc.
  ///
  /// In en, this message translates to:
  /// **'Create keo, join without limits and unlock every paid feature.'**
  String get storeProDesc;

  /// No description provided for @storeBoostDesc.
  ///
  /// In en, this message translates to:
  /// **'Put your keo at the top of the board for 24 hours.'**
  String get storeBoostDesc;

  /// No description provided for @storeSeeLikesDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock the list of people who liked you.'**
  String get storeSeeLikesDesc;

  /// No description provided for @storeFiltersDesc.
  ///
  /// In en, this message translates to:
  /// **'Filter by music taste, age, area and activity.'**
  String get storeFiltersDesc;

  /// No description provided for @storeHeroSub.
  ///
  /// In en, this message translates to:
  /// **'Unlock tools that fill your keo faster with the right people.'**
  String get storeHeroSub;

  /// No description provided for @storeOpenError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the store. Try again later.'**
  String get storeOpenError;

  /// No description provided for @storeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the store'**
  String get storeLoadError;

  /// No description provided for @photoLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load photos. Try again.'**
  String get photoLoadError;

  /// No description provided for @photoDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this photo?'**
  String get photoDeleteTitle;

  /// No description provided for @photoDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from your profile.'**
  String get photoDeleteBody;

  /// No description provided for @photoDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the photo. Try again.'**
  String get photoDeleteError;

  /// No description provided for @photoSubMax.
  ///
  /// In en, this message translates to:
  /// **'Add up to {max} photos to make your profile stand out.'**
  String photoSubMax(int max);

  /// No description provided for @photoConsentNeeded.
  ///
  /// In en, this message translates to:
  /// **'Enable the photo consent to add profile photos.'**
  String get photoConsentNeeded;

  /// No description provided for @photoConsentCta.
  ///
  /// In en, this message translates to:
  /// **'Enable in Settings'**
  String get photoConsentCta;

  /// No description provided for @promptMax.
  ///
  /// In en, this message translates to:
  /// **'Up to {max} prompts'**
  String promptMax(int max);

  /// No description provided for @promptSubMax.
  ///
  /// In en, this message translates to:
  /// **'Pick up to {max} prompts to spark conversations.'**
  String promptSubMax(int max);

  /// No description provided for @promptAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Your answer…'**
  String get promptAnswerHint;

  /// No description provided for @adminActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed'**
  String get adminActionFailed;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get adminTitle;

  /// No description provided for @adminEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reports'**
  String get adminEmpty;

  /// No description provided for @adminHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get adminHide;

  /// No description provided for @adminRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get adminRemove;

  /// No description provided for @adminDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get adminDismiss;

  /// No description provided for @adminLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load reports'**
  String get adminLoadError;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLangSystem.
  ///
  /// In en, this message translates to:
  /// **'Default (Vietnamese)'**
  String get settingsLangSystem;

  /// No description provided for @locationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location permission needed'**
  String get locationPermissionTitle;

  /// No description provided for @locationPermissionSub.
  ///
  /// In en, this message translates to:
  /// **'Allow location access so we can find singers and keos near you.'**
  String get locationPermissionSub;

  /// No description provided for @locationOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get locationOpenSettings;

  /// No description provided for @locationServiceOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off'**
  String get locationServiceOffTitle;

  /// No description provided for @locationServiceOffSub.
  ///
  /// In en, this message translates to:
  /// **'Turn on location (GPS), then try again.'**
  String get locationServiceOffSub;

  /// No description provided for @locationNoFixTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your location'**
  String get locationNoFixTitle;

  /// No description provided for @locationNoFixSub.
  ///
  /// In en, this message translates to:
  /// **'No location fix — try again in a moment.'**
  String get locationNoFixSub;

  /// No description provided for @locationPushFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send your location'**
  String get locationPushFailedTitle;

  /// No description provided for @onbPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get onbPhotosTitle;

  /// No description provided for @onbPhotosSubOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional — you can add or change photos any time from your Profile.'**
  String get onbPhotosSubOptional;

  /// No description provided for @onbPhotosDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get onbPhotosDone;

  /// No description provided for @onbPhotosSkip.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get onbPhotosSkip;

  /// No description provided for @onbConsentAll.
  ///
  /// In en, this message translates to:
  /// **'Agree to all'**
  String get onbConsentAll;

  /// No description provided for @deckCoachSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe right to like\nSwipe left to pass\nSwipe up to Super Like'**
  String get deckCoachSwipe;

  /// No description provided for @deckCoachTap.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get deckCoachTap;

  /// No description provided for @storeBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get storeBuy;

  /// No description provided for @storeOwned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get storeOwned;

  /// No description provided for @storeTermOneTime.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase · permanent'**
  String get storeTermOneTime;

  /// No description provided for @storeTermBoost.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase · lasts 24 hours'**
  String get storeTermBoost;

  /// No description provided for @storeNoAutoRenew.
  ///
  /// In en, this message translates to:
  /// **'All items are one-time purchases. This is not a subscription and nothing auto-renews. Refunds are handled by your App Store or Google Play account.'**
  String get storeNoAutoRenew;

  /// No description provided for @storeRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get storeRestore;

  /// No description provided for @storeRestoreStarted.
  ///
  /// In en, this message translates to:
  /// **'Checking your previous purchases…'**
  String get storeRestoreStarted;

  /// No description provided for @storeRestoreError.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the store. Try again later.'**
  String get storeRestoreError;

  /// No description provided for @storeRestored.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored.'**
  String get storeRestored;

  /// No description provided for @storePending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment confirmation…'**
  String get storePending;

  /// No description provided for @storeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Purchase complete. Feature unlocked.'**
  String get storeSuccess;

  /// No description provided for @storeFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment did not go through. You have not been charged.'**
  String get storeFailed;

  /// No description provided for @storeDeliveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Paid, but the feature is not unlocked yet. We will retry automatically — contact support if it persists.'**
  String get storeDeliveryFailed;

  /// No description provided for @storeLegalIntro.
  ///
  /// In en, this message translates to:
  /// **'By purchasing you accept:'**
  String get storeLegalIntro;

  /// No description provided for @safetyReportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Report or block'**
  String get safetyReportTooltip;

  /// No description provided for @safetyPickMember.
  ///
  /// In en, this message translates to:
  /// **'Who do you want to report?'**
  String get safetyPickMember;

  /// No description provided for @safetyBlockedRemoved.
  ///
  /// In en, this message translates to:
  /// **'Blocked. You will no longer see each other.'**
  String get safetyBlockedRemoved;

  /// No description provided for @safetyProfileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not load this profile, but you can still report or block.'**
  String get safetyProfileUnavailable;

  /// No description provided for @keoMatchNext.
  ///
  /// In en, this message translates to:
  /// **'See another suggestion'**
  String get keoMatchNext;

  /// No description provided for @keoMatchCounterLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get keoMatchCounterLabel;

  /// No description provided for @keoMatchNoMore.
  ///
  /// In en, this message translates to:
  /// **'No other suggestions right now. Try creating your own group.'**
  String get keoMatchNoMore;

  /// No description provided for @keoMatchViewDetail.
  ///
  /// In en, this message translates to:
  /// **'View group details'**
  String get keoMatchViewDetail;

  /// No description provided for @keoMatchMembersLabel.
  ///
  /// In en, this message translates to:
  /// **'Already in'**
  String get keoMatchMembersLabel;

  /// No description provided for @onbTasteMinGenres.
  ///
  /// In en, this message translates to:
  /// **'Pick at least 3 genres so we can match you with the right people.'**
  String get onbTasteMinGenres;

  /// No description provided for @onbTasteSelectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get onbTasteSelectedLabel;

  /// No description provided for @onbTasteSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get onbTasteSearch;

  /// No description provided for @onbTasteNoResult.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches that search.'**
  String get onbTasteNoResult;

  /// No description provided for @consentRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Each item below is required to use the app. Turn them on one by one.'**
  String get consentRequiredHint;

  /// No description provided for @consentCrossBorderTitle.
  ///
  /// In en, this message translates to:
  /// **'Storing your data in Singapore'**
  String get consentCrossBorderTitle;

  /// No description provided for @consentCrossBorderBody.
  ///
  /// In en, this message translates to:
  /// **'Your account and chat data is stored on servers in Singapore. Vietnamese law treats this as a cross-border transfer, so we ask for it separately.'**
  String get consentCrossBorderBody;

  /// No description provided for @consentTosTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get consentTosTitle;

  /// No description provided for @consentPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get consentPrivacyTitle;

  /// No description provided for @consentAcceptAllRequired.
  ///
  /// In en, this message translates to:
  /// **'Accept all required'**
  String get consentAcceptAllRequired;

  /// No description provided for @planPayOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the payment app. Check that MoMo or ZaloPay is installed.'**
  String get planPayOpenError;

  /// No description provided for @planPayNote.
  ///
  /// In en, this message translates to:
  /// **'Payment happens inside the MoMo or ZaloPay app. Cùng Hát does not hold a table for you and does not handle refunds.'**
  String get planPayNote;

  /// No description provided for @consentTosNotice.
  ///
  /// In en, this message translates to:
  /// **'Continuing means you accept the Terms of Service and the Privacy Policy.'**
  String get consentTosNotice;
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
