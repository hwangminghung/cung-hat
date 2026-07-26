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
      'Store my data on servers located in Singapore';

  @override
  String get chatPromoteKeo => 'Set up an outing';

  @override
  String get sendThisTitle => 'Send this message?';

  @override
  String get sendThisBody =>
      'This message looks money- or personal-info-related. Double-check before sending.';

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
  String get bookVenue => 'Pay at the venue via MoMo/ZaloPay';

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
  String get authErrorSendFailed =>
      'Couldn\'t send the OTP code. Check your phone number and try again.';

  @override
  String get authErrorOtpInvalid =>
      'The OTP code is incorrect or has expired. Please try again.';

  @override
  String get authErrorNetwork =>
      'Can\'t connect. Check your network and try again.';

  @override
  String get authErrorGeneric => 'Something went wrong. Please try again.';

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
  String get tabChat => 'Messages';

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
  String get upsellKeoCreateTitle => 'Host unlimited keos';

  @override
  String get upsellKeoCreateB1 =>
      'Free keeps 1 open keo — Pro hosts as many as you like';

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
  String get profileLoadErrorTitle => 'Couldn\'t load your profile';

  @override
  String get profileLoadErrorSub =>
      'Your profile is safe. Check your connection and try again.';

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
  String get keoErrorFreeHostLimit =>
      'Free keeps 1 open keo at a time. Cancel it or upgrade to Pro to host more.';

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

  @override
  String get chatShareSongTooltip => 'Send a go-to song';

  @override
  String get chatComposerHint => 'Say something...';

  @override
  String get chatSendError => 'Couldn\'t send the message. Try again later.';

  @override
  String get chatProfileError => 'Couldn\'t open the profile. Try again later.';

  @override
  String get chatProfileGone => 'Profile no longer available.';

  @override
  String get chatUnmatchTitle => 'Unmatch?';

  @override
  String get chatUnmatchBody =>
      'You two won\'t be able to message each other anymore.';

  @override
  String get chatUnmatchCta => 'Unmatch';

  @override
  String get chatUnmatchError => 'Couldn\'t unmatch, try again later';

  @override
  String get chatEmptyMatch =>
      'No messages yet. Break the ice with a go-to song.';

  @override
  String get chatEmptyKeo =>
      'No messages yet. Open with one of your go-to songs.';

  @override
  String get chatHistoryError => 'Couldn\'t load messages';

  @override
  String get chatGroupTitle => 'Group chat';

  @override
  String get chatGroupRules => 'Group rules';

  @override
  String get chatGroupRulesBody =>
      'No filming/photos without consent · Split costs clearly · Respect privacy';

  @override
  String get chatKeoNotOpen =>
      'Group chat isn\'t open yet. Everyone must confirm joining first.';

  @override
  String get chatToday => 'Today';

  @override
  String get songShareEmpty =>
      'You haven\'t picked any go-to songs. Add some in your Profile.';

  @override
  String get inboxTitle => 'Messages';

  @override
  String get inboxSubtitle => 'Where conversations live once you match.';

  @override
  String get inboxSectionKeo => 'Your keo';

  @override
  String get inboxSectionMatches => 'Direct messages';

  @override
  String get inboxTurnFirst => 'Say hi first';

  @override
  String get inboxTurnYours => 'Your turn';

  @override
  String get inboxReady => 'Ready for a karaoke invite';

  @override
  String get inboxEmptyTitle => 'No conversations yet';

  @override
  String get inboxEmptySub => 'Join a kèo to start chatting with new friends.';

  @override
  String get inboxFindKeo => 'Find a kèo';

  @override
  String get inboxLoadError => 'Couldn\'t load conversations';

  @override
  String get keoStateOpen => 'Open';

  @override
  String get keoStateFull => 'Full';

  @override
  String get keoStatePlanning => 'Planning';

  @override
  String get keoStateConfirmed => 'Confirmed';

  @override
  String get bookingPickGateway => 'Pick a payment gateway';

  @override
  String get bookingNotConfigured => 'Payment gateway not configured yet';

  @override
  String get bookingCreateError => 'Couldn\'t create the payment';

  @override
  String get planStatusConfirmed => 'Confirmed';

  @override
  String get planStatusProposed => 'Awaiting approval';

  @override
  String get planVenuePicked => 'Chosen venue';

  @override
  String get planTitle => 'Plan';

  @override
  String get planLoadError => 'Couldn\'t load the plan';

  @override
  String get planNoVenuesTitle => 'No venue suggestions yet';

  @override
  String get planNoVenuesSub =>
      'Once venue data arrives from Places or seed, the map will show markers to pick a meeting spot.';

  @override
  String get planReload => 'Reload';

  @override
  String get planVenuesLoadError => 'Couldn\'t load the venue list';

  @override
  String planTime(String time) {
    return 'Time: $time';
  }

  @override
  String planStatus(String status) {
    return 'Status: $status';
  }

  @override
  String get planConfirmCta => 'Approve the plan';

  @override
  String get planCancelCta => 'Cancel plan';

  @override
  String get planCancelConfirmTitle => 'Cancel this plan?';

  @override
  String get planCancelConfirmBody =>
      'The group returns to venue planning so you can propose again.';

  @override
  String get planCancelError => 'Couldn\'t cancel the plan';

  @override
  String planConfirmedCount(int n, int total) {
    return 'Confirmed $n/$total';
  }

  @override
  String get planConfirmError => 'Couldn\'t approve';

  @override
  String get planMapError => 'Couldn\'t open the map';

  @override
  String get planDirections => 'Directions';

  @override
  String planSuggestReason(String band) {
    return 'Suggested for being near the group midpoint · $band km away';
  }

  @override
  String get planPickVenue => 'Pick this venue';

  @override
  String get planProposed => 'Plan proposed';

  @override
  String get planProposeError => 'Couldn\'t propose';

  @override
  String get planPickSchedule => 'Pick a singing time';

  @override
  String get planOtherTime => 'Another time';

  @override
  String get planProposeCta => 'Propose the plan';

  @override
  String get safetyShare => 'Share with friends';

  @override
  String safetyShareMessage(String link) {
    return 'I\'m going karaoke, here\'s the plan: $link';
  }

  @override
  String get safetyShareError => 'Couldn\'t create the share link';

  @override
  String get safetyArrived => 'I\'ve arrived';

  @override
  String get safetyArrivedOk => 'Arrival recorded';

  @override
  String get safetyArrivedError => 'Couldn\'t record it';

  @override
  String get planSharedTitle => 'Shared plan';

  @override
  String get planSharedNotFound => 'Plan not found';

  @override
  String get planMidpointMarker => 'Group midpoint';

  @override
  String get planTomorrow => 'Tmrw';

  @override
  String get planWeekdaysShort => 'Mon,Tue,Wed,Thu,Fri,Sat,Sun';

  @override
  String get settingsSectionPrivacy => 'Privacy';

  @override
  String get settingsSectionData => 'My data';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSectionSafety => 'Safety';

  @override
  String get settingsBlocked => 'Blocked users';

  @override
  String get settingsAdmin => 'Moderation';

  @override
  String get blockedEmptyTitle => 'No blocked users';

  @override
  String get blockedEmptySubtitle => 'People you block will appear here.';

  @override
  String get blockedUnblock => 'Unblock';

  @override
  String get blockedUnblockError => 'Couldn\'t unblock. Please try again.';

  @override
  String get blockedLoadError => 'Couldn\'t load the list. Please try again.';

  @override
  String get settingsSectionLegal => 'Legal';

  @override
  String get settingsTerms => 'Terms';

  @override
  String get settingsExportError =>
      'Couldn\'t export your data. Please try again.';

  @override
  String get settingsDeleteError => 'Couldn\'t delete the account, try again.';

  @override
  String get commonDelete => 'Delete';

  @override
  String get storeProDesc =>
      'Create keo, join without limits and unlock every paid feature.';

  @override
  String get storeBoostDesc =>
      'Put your keo at the top of the board for 24 hours.';

  @override
  String get storeSeeLikesDesc => 'Unlock the list of people who liked you.';

  @override
  String get storeFiltersDesc =>
      'Filter by music taste, age, area and activity.';

  @override
  String get storeHeroSub =>
      'Unlock tools that fill your keo faster with the right people.';

  @override
  String get storeOpenError => 'Couldn\'t open the store. Try again later.';

  @override
  String get storeLoadError => 'Couldn\'t load the store';

  @override
  String get photoLoadError => 'Couldn\'t load photos. Try again.';

  @override
  String get photoDeleteTitle => 'Delete this photo?';

  @override
  String get photoDeleteBody => 'It will be removed from your profile.';

  @override
  String get photoDeleteError => 'Couldn\'t delete the photo. Try again.';

  @override
  String photoSubMax(int max) {
    return 'Add up to $max photos to make your profile stand out.';
  }

  @override
  String get photoConsentNeeded =>
      'Enable the photo consent to add profile photos.';

  @override
  String get photoConsentCta => 'Enable in Settings';

  @override
  String promptMax(int max) {
    return 'Up to $max prompts';
  }

  @override
  String promptSubMax(int max) {
    return 'Pick up to $max prompts to spark conversations.';
  }

  @override
  String get promptAnswerHint => 'Your answer…';

  @override
  String get adminActionFailed => 'Action failed';

  @override
  String get adminTitle => 'Moderation';

  @override
  String get adminEmpty => 'No reports';

  @override
  String get adminHide => 'Hide';

  @override
  String get adminRemove => 'Remove';

  @override
  String get adminDismiss => 'Dismiss';

  @override
  String get adminLoadError => 'Couldn\'t load reports';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLangSystem => 'Default (Vietnamese)';

  @override
  String get locationPermissionTitle => 'Location permission needed';

  @override
  String get locationPermissionSub =>
      'Allow location access so we can find singers and keos near you.';

  @override
  String get locationOpenSettings => 'Open settings';

  @override
  String get locationServiceOffTitle => 'Location is turned off';

  @override
  String get locationServiceOffSub => 'Turn on location (GPS), then try again.';

  @override
  String get locationNoFixTitle => 'Couldn\'t get your location';

  @override
  String get locationNoFixSub => 'No location fix — try again in a moment.';

  @override
  String get locationPushFailedTitle => 'Couldn\'t send your location';

  @override
  String get onbPhotosTitle => 'Add photos';

  @override
  String get onbPhotosSubOptional =>
      'Optional — you can add or change photos any time from your Profile.';

  @override
  String get onbPhotosDone => 'Done';

  @override
  String get onbPhotosSkip => 'Later';

  @override
  String get onbConsentAll => 'Agree to all';

  @override
  String get deckCoachSwipe =>
      'Swipe right to like\nSwipe left to pass\nSwipe up to Super Like';

  @override
  String get deckCoachTap => 'Start';

  @override
  String get storeBuy => 'Buy';

  @override
  String get storeOwned => 'Owned';

  @override
  String get storeTermOneTime => 'One-time purchase · permanent';

  @override
  String get storeTermBoost => 'One-time purchase · lasts 24 hours';

  @override
  String get storeNoAutoRenew =>
      'All items are one-time purchases. This is not a subscription and nothing auto-renews. Refunds are handled by your App Store or Google Play account.';

  @override
  String get storeRestore => 'Restore purchases';

  @override
  String get storeRestoreStarted => 'Checking your previous purchases…';

  @override
  String get storeRestoreError => 'Could not reach the store. Try again later.';

  @override
  String get storeRestored => 'Purchases restored.';

  @override
  String get storePending => 'Waiting for payment confirmation…';

  @override
  String get storeSuccess => 'Purchase complete. Feature unlocked.';

  @override
  String get storeFailed =>
      'Payment did not go through. You have not been charged.';

  @override
  String get storeDeliveryFailed =>
      'Paid, but the feature is not unlocked yet. We will retry automatically — contact support if it persists.';

  @override
  String get storeLegalIntro => 'By purchasing you accept:';

  @override
  String get safetyReportTooltip => 'Report or block';

  @override
  String get safetyPickMember => 'Who do you want to report?';

  @override
  String get safetyBlockedRemoved =>
      'Blocked. You will no longer see each other.';

  @override
  String get safetyProfileUnavailable =>
      'Could not load this profile, but you can still report or block.';

  @override
  String get keoMatchNext => 'See another suggestion';

  @override
  String get keoMatchCounterLabel => 'Suggestion';

  @override
  String get keoMatchNoMore =>
      'No other suggestions right now. Try creating your own group.';

  @override
  String get keoMatchViewDetail => 'View group details';

  @override
  String get keoMatchMembersLabel => 'Already in';

  @override
  String get onbTasteMinGenres =>
      'Pick at least 3 genres so we can match you with the right people.';

  @override
  String get onbTasteSelectedLabel => 'Selected';

  @override
  String get onbTasteSearch => 'Search';

  @override
  String get onbTasteNoResult => 'Nothing matches that search.';

  @override
  String get consentRequiredHint =>
      'Each item below is required to use the app. Turn them on one by one.';

  @override
  String get consentCrossBorderTitle => 'Storing your data in Singapore';

  @override
  String get consentCrossBorderBody =>
      'Your account and chat data is stored on servers in Singapore. Vietnamese law treats this as a cross-border transfer, so we ask for it separately.';

  @override
  String get consentTosTitle => 'Terms of Service';

  @override
  String get consentPrivacyTitle => 'Privacy Policy';

  @override
  String get consentAcceptAllRequired => 'Accept all required';

  @override
  String get planPayOpenError =>
      'Could not open the payment app. Check that MoMo or ZaloPay is installed.';

  @override
  String get planPayNote =>
      'Payment happens inside the MoMo or ZaloPay app. Cùng Hát does not hold a table for you and does not handle refunds.';

  @override
  String get consentTosNotice =>
      'Continuing means you accept the Terms of Service and the Privacy Policy.';
}
