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

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonBack => 'Back';

  @override
  String get commonCheckConnection => 'Check your connection and try again.';

  @override
  String get commonSaveError => 'Couldn\'t save the setting, try again.';

  @override
  String get deckErrorLikeLimit =>
      'You\'re out of likes for today. Upgrade to Pro for unlimited likes.';

  @override
  String get deckErrorSuperLimit => 'You\'re out of Super Likes for today.';

  @override
  String get deckErrorProRequired => 'This feature is for Pro members.';

  @override
  String get deckErrorBoostActive => 'You already have a boost running.';

  @override
  String get deckErrorBoostLimit =>
      'You\'ve used today\'s boost. Try again tomorrow.';

  @override
  String get deckErrorUnknown => 'Couldn\'t save your swipe. Try again later.';

  @override
  String get candidateFallbackName => 'New singer';

  @override
  String get commonReport => 'Report';

  @override
  String get candidateViewProfile => 'View profile';

  @override
  String get candidateOnlineToday => 'Online today';

  @override
  String candidateDistanceKm(String band) {
    return '$band km away';
  }

  @override
  String candidateSharedBaitu(int count) {
    return '$count shared go-to songs';
  }

  @override
  String get candidateNoSharedGenres => 'No shared genres yet';

  @override
  String get candidateNoBio => 'No bio yet — ask them when you match!';

  @override
  String get candidatePhotoQuote => 'This photo is so cool! ';

  @override
  String get candidateReplyPhoto => 'Reply to this photo';

  @override
  String get candidateSharedGenresTitle => 'Shared music taste';

  @override
  String get candidateNoSharedGenresDot => 'No overlapping genres yet.';

  @override
  String get candidateSharedBaituTitle => 'Shared go-to songs';

  @override
  String get candidateNoSharedBaitu => 'No shared songs yet — room to explore!';

  @override
  String candidateSongQuote(String title) {
    return 'About your song \"$title\": ';
  }

  @override
  String get candidateReply => 'Reply';

  @override
  String candidatePromptQuote(String answer) {
    return 'You said \"$answer\" — tell me more: ';
  }

  @override
  String get candidateReportBlock => 'Report / Block';

  @override
  String get exploreFallbackTitle => 'Explore';

  @override
  String get deckLoadErrorTitle => 'Couldn\'t load suggestions';

  @override
  String get deckPromoSeeKeo => 'SEE KEO';

  @override
  String get deckExploreTooltip => 'Explore by music taste';

  @override
  String get deckRefreshTooltip => 'Refresh';

  @override
  String get deckSearching100 => 'Searching within 100 km';

  @override
  String deckBoostingUntil(String time) {
    return 'Boosting until $time';
  }

  @override
  String get deckBoostTooltip => 'Boost profile';

  @override
  String get deckBoostStarted =>
      'Boosting for 30 minutes — your profile is prioritized nearby.';

  @override
  String get celebrateYouFallback => 'You';

  @override
  String get deckExhausted100 => 'Searched everything within 100 km';

  @override
  String get deckEmptyNearby => 'No singers nearby yet';

  @override
  String get deckExpand100 => 'Expand search to 100 km';

  @override
  String get deckRefreshSuggestions => 'Refresh suggestions';

  @override
  String get deckAutoExpandTitle => 'Auto-expand when you run out';

  @override
  String get deckAutoExpandSub =>
      'Automatically search 100 km once 50 km is empty';

  @override
  String get filterApplied => 'Filters applied.';

  @override
  String get filterSaveError => 'Couldn\'t save, try again.';

  @override
  String get filterTitle => 'Filters';

  @override
  String get filterRadius => 'Search radius';

  @override
  String get filterAutoExpandSub => 'Search 100 km when suggestions run out';

  @override
  String get filterApply => 'Apply';

  @override
  String get promoKeoNearby => '🎤 Keo near you';

  @override
  String promoSeats(int filled, int target) {
    return '$filled/$target seats';
  }

  @override
  String promoDistanceKm(String band) {
    return '$band km away';
  }

  @override
  String get promoSwipeRight => 'Swipe right to view the keo →';

  @override
  String get likesEmptyTitle => 'No likes yet';

  @override
  String get likesEmptySub =>
      'Keep singing your heart out — the right people will come.';

  @override
  String get likesAnonymous => 'Anonymous';

  @override
  String get likesLockedTitle => 'Unlock to see who liked you';

  @override
  String get teaserLoadError => 'Couldn\'t load the list';

  @override
  String get teaserEmptySub => 'Complete your profile to get seen more.';

  @override
  String teaserCount(int count) {
    return '$count people liked you';
  }

  @override
  String get teaserUnlockCta => 'Unlock with Pro — see who likes you';

  @override
  String get celebrateTitle => 'It\'s a match!';

  @override
  String celebrateBody(String name) {
    return 'You and $name liked each other';
  }

  @override
  String celebrateSharedBaitu(String songs) {
    return 'Shared songs: $songs';
  }

  @override
  String get celebrateChatNow => 'Chat now';

  @override
  String get celebrateContinue => 'Keep exploring';

  @override
  String reportTitle(String reason) {
    return 'Report: $reason';
  }

  @override
  String get reportBlockUser => 'Block this user';

  @override
  String get reportSent => 'Report sent.';

  @override
  String get reportSendError => 'Couldn\'t send the report.';

  @override
  String get reportBlocked => 'Blocked.';

  @override
  String get reportBlockError => 'Couldn\'t block.';

  @override
  String exploreOpenSemantics(String title) {
    return 'Open $title';
  }

  @override
  String get keoErrorProRequired => 'You need Pro to create a keo.';

  @override
  String get keoErrorFreeJoinLimit =>
      'You\'re already in 1 keo. Leave it or upgrade to Pro to join more.';

  @override
  String get keoErrorFull => 'This keo is full.';

  @override
  String get keoErrorAlreadyDeclined => 'You were declined from this keo.';

  @override
  String get keoErrorNotOpen => 'This keo is no longer open.';

  @override
  String get keoErrorBlocked =>
      'You can\'t join this keo due to safety settings.';

  @override
  String get keoErrorNoLocation =>
      'Location is needed to match a keo. Turn on Location and try again.';

  @override
  String get keoErrorAgeNotVerified => 'Verify your age before matching a keo.';

  @override
  String get keoErrorNoMatchableKeo =>
      'No matching keo found yet, try again later.';

  @override
  String get keoErrorInvalidTimeWindow =>
      'Invalid time window. Pick another slot.';

  @override
  String get keoErrorInvalidGroupSize => 'Invalid group size.';

  @override
  String get keoErrorGeneric => 'Something went wrong, try again.';

  @override
  String get keoModeOpen => 'Open · join instantly';

  @override
  String get keoModeApproval => 'Approval needed';

  @override
  String keoCardDistance(String band) {
    return '$band km away';
  }

  @override
  String keoCardPeople(int filled, int target) {
    return '$filled/$target people';
  }

  @override
  String get keoBoardLoadError => 'Couldn\'t load keo list';

  @override
  String get keoBoardEmptyTitle => 'No keo nearby yet';

  @override
  String get keoBoardEmptySub =>
      'Tap match-me to find a fitting keo or create your own.';

  @override
  String get keoCreateCta => 'Create keo';

  @override
  String get keoBoardTitle => 'Keo around you';

  @override
  String get keoBoardStoreTooltip => 'Store';

  @override
  String get keoBoardSubtitle =>
      'Find a singing group that fits your taste, nearby and on schedule.';

  @override
  String get keoBoardMatchMe => 'Match me a group';

  @override
  String get keoBoardMatchMeSub =>
      'Auto-suggest keo that fit your taste, location and time.';

  @override
  String get keoSharedTitle => 'Shared keo';

  @override
  String get keoSharedLoadError => 'Couldn\'t load the keo';

  @override
  String get keoSharedNotFound => 'Keo not found';

  @override
  String get keoSharedNotFoundSub =>
      'The link is wrong or the keo was deleted.';

  @override
  String get keoSharedExpired => 'Link expired';

  @override
  String keoSharedSeats(int filled, int target) {
    return '$filled/$target seats';
  }

  @override
  String keoSharedHost(String name) {
    return 'Host: $name';
  }

  @override
  String get keoSharedAnonymous => 'Anonymous';

  @override
  String get keoSharedJoinCta => 'View keo & ask to join';

  @override
  String get keoSharedLoginCta => 'Sign in to ask to join';

  @override
  String get keoStatusConfirmedMember => 'Confirmed';

  @override
  String get keoStatusApproved => 'Approved';

  @override
  String get keoStatusRequested => 'Pending';

  @override
  String get keoStatusLeft => 'Left';

  @override
  String get keoStatusDeclined => 'Declined';

  @override
  String get keoDetailTitle => 'Keo details';

  @override
  String get keoDetailShareTooltip => 'Share keo';

  @override
  String keoDetailShareMessage(String title, String link) {
    return 'Keo \"$title\" is looking for singers — join on Cùng Hát: $link';
  }

  @override
  String get keoDetailShareError => 'Couldn\'t create the link, try again.';

  @override
  String get keoDetailMembers => 'Members';

  @override
  String get keoDetailApproveError => 'Couldn\'t approve';

  @override
  String get keoDetailDeclineError => 'Couldn\'t decline';

  @override
  String get keoDetailConfirmError => 'Couldn\'t confirm';

  @override
  String get keoDetailLeaveError => 'Couldn\'t leave the keo';

  @override
  String keoDetailMemberCount(int count) {
    return '$count people in this keo';
  }

  @override
  String get keoDetailHostChip => 'Host';

  @override
  String get keoDetailApprove => 'Approve';

  @override
  String get keoDetailDecline => 'Decline';

  @override
  String get keoDetailRequestJoin => 'Ask to join';

  @override
  String get keoDetailConfirmJoin => 'Confirm joining';

  @override
  String get keoDetailConfirmed => 'Joining confirmed';

  @override
  String get keoDetailOpenChat => 'Open group chat';

  @override
  String get keoDetailPickVenue => 'Pick the venue';

  @override
  String get keoDetailViewPlan => 'View plan';

  @override
  String get keoDetailLeave => 'Leave keo';

  @override
  String get keoCreatePick => 'Pick';

  @override
  String get keoCreateNameMissing => 'Enter a keo name';

  @override
  String get keoCreateTimeMissing => 'Pick start and end times';

  @override
  String get keoCreateTimeOrder => 'End time must be after start time';

  @override
  String get keoCreateNoLocation =>
      'Couldn\'t get your location. Turn on Location and try again.';

  @override
  String get keoCreateHeadline => 'Invite a group to sing';

  @override
  String get keoCreateSubtitle =>
      'Pick the time, music taste and how members join.';

  @override
  String get keoCreateNameLabel => 'Keo name';

  @override
  String get keoCreateNameHint => 'V-Pop tonight';

  @override
  String get keoCreateAreaLabel => 'Area';

  @override
  String get keoCreateAreaHint => 'District 1, Ho Chi Minh City';

  @override
  String get keoCreateVenueLater => 'Pick the venue after creating';

  @override
  String get keoCreateVenueLaterSub =>
      'The host picks the venue on the Plan screen.';

  @override
  String keoCreateStart(String time) {
    return 'Start: $time';
  }

  @override
  String keoCreateEnd(String time) {
    return 'End: $time';
  }

  @override
  String get keoCreateSize => 'Group size';

  @override
  String keoCreateSizeN(int n) {
    return '$n people';
  }

  @override
  String get keoCreateGenres => 'Genres';

  @override
  String get keoCreateGenresError => 'Couldn\'t load genres';

  @override
  String get keoCreateJoinMode => 'Join mode';

  @override
  String get keoCreateModeApproval => 'Approval';

  @override
  String get keoCreateModeOpen => 'Open';

  @override
  String get keoMatchNoneFound => 'No matching keo found yet. Try again later.';

  @override
  String get keoMatchExistingTitle => 'A keo that fits you';

  @override
  String get keoMatchNewTitle => 'Found a matching group';

  @override
  String get commonClose => 'Close';

  @override
  String get keoMatchReasonSharedGenres => 'Shared taste';

  @override
  String get keoMatchReasonNearYou => 'Near you';

  @override
  String get keoMatchReasonEveningSlot => 'Great time slot';

  @override
  String get keoMatchReasonOpenJoin => 'Instant join';

  @override
  String get keoMatchReasonAvailableSlots => 'Seats left';

  @override
  String get keoMatchReasonActiveHost => 'Host online';
}
