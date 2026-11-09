class AppRoutes {
  const AppRoutes._();

  // Authentication
  static const welcome = '/';
  static const signIn = '/sign-in';
  static const createAccount = '/create-account';
  static const otpVerification = '/create-account/otp';
  static const createAccountProfile = '/create-account/profile';
  static const notificationPermission = '/notification-permission';

  // Main tabs
  static const home = '/home';
  static const chats = '/chats';
  static const postSkill = '/post';
  static const wallet = '/wallet';
  static const profile = '/profile';

  // Posting a skill
  static const skillCategory = '/post/category';
  static const skillDetails = '/post/details';
  static const listingInformation = '/post/information';
  static const listingPreview = '/post/preview';
  static const postConfirmation = '/post/confirmation';

  // Discovery
  static const searchResults = '/search';
  static const categoryFilter = '/filters/category';
  static const cityFilter = '/filters/city';
  static const savedSkills = '/saved';
  static const savedSearches = '/saved-searches';
  static const searchAlerts = '/search-alerts';

  // Listings and members
  static const listingDetails = '/listing';
  static const editListing = '/listing/edit';
  static const shareListing = '/listing/share';
  static const myListings = '/my-listings';
  static const memberProfile = '/member';
  static const publicSkillList = '/member/skills';

  // Chats and proposals
  static const chat = '/chat';
  static const groupChat = '/chat/group';
  static const proposalInsideChat = '/chat/proposal';
  static const counteroffer = '/chat/counteroffer';
  static const proposalDetails = '/proposal';

  // Trades
  static const myTrades = '/my-trades';
  static const tradeHistory = '/trade-history';
  static const tradeDetails = '/trade';
  static const tradeStatus = '/trade/status';
  static const scheduleSession = '/trade/schedule';
  static const tradeCompletion = '/trade/completion';
  static const disputeTrade = '/trade/dispute';
  static const rateTrade = '/rate';

  // Group trades
  static const groupTrades = '/group-trades';
  static const createGroupTrade = '/group-trades/new';
  static const groupTradeDetails = '/group-trades/details';
  static const editGroupTrade = '/group-trades/edit';
  static const groupTradeInvitation = '/group-trades/invitation';
  static const groupTradeCompletion = '/group-trades/completion';

  // Wallet
  static const transactionDetails = '/wallet/transaction';

  // Profile
  static const accountDetails = '/account-details';
  static const editProfile = '/edit-profile';
  static const mySkills = '/my-skills';
  static const reviews = '/reviews';
  static const badges = '/badges';
  static const badgeDetails = '/badges/details';

  // Settings
  static const settings = '/settings';
  static const appPreferences = '/settings/preferences';
  static const privacySettings = '/settings/privacy';
  static const notificationPreferences = '/settings/notifications';
  static const blockedMembers = '/settings/blocked-members';
  static const locationPermission = '/settings/location';
  static const help = '/settings/help';
  static const terms = '/settings/terms';
  static const privacyPolicy = '/settings/privacy-policy';
  static const communityGuidelines = '/settings/community-guidelines';
  static const about = '/settings/about';
  static const contactSupport = '/settings/contact-support';
  static const deleteAccount = '/settings/delete-account';

  // Notifications
  static const notifications = '/notifications';
  static const notificationDetails = '/notifications/details';

  // Safety
  static const safety = '/safety';
  static const reportMember = '/report/member';
  static const blockMember = '/block/member';
  static const reportTrade = '/report/trade';
  static const reportReceived = '/report/received';
  static const disputeCaseDetails = '/disputes';
  static const supportMessages = '/support/messages';

  // Screen states
  static const loading = '/loading';
  static const error = '/error';
  static const offline = '/offline';
  static const notFound = '/not-found';
}
