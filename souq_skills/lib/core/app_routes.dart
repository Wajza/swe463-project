class AppRoutes {
  const AppRoutes._();

  // Authentication
  static const welcome = '/';
  static const phone = '/phone';
  static const otpVerification = '/phone/otp';
  static const createAccountProfile = '/phone/profile';

  // Main tabs
  static const home = '/home';
  static const chats = '/chats';
  static const postSkill = '/post';
  static const wallet = '/wallet';
  static const profile = '/profile';

  // Discovery
  static const savedSkills = '/saved';

  // Listings and members
  static const createListing = '/listing/new';
  static const listingDetails = '/listing';
  static const editListing = '/listing/edit';
  static const shareListing = '/listing/share';
  static const myListings = '/my-listings';
  static const memberProfile = '/member';

  // Chats and proposals
  static const chat = '/chat';
  static const groupChat = '/chat/group';
  static const proposalInsideChat = '/chat/proposal';
  static const proposalDetails = '/proposal';

  // Trades
  static const myTrades = '/my-trades';
  static const tradeDetails = '/trade';
  static const scheduleSession = '/trade/schedule';
  static const disputeTrade = '/trade/dispute';
  static const rateTrade = '/rate';

  // Group trades
  static const groupTrades = '/group-trades';
  static const groupTradeDetails = '/group-trades/details';
  static const editGroupTrade = '/group-trades/edit';

  // Profile
  static const editProfile = '/edit-profile';
  static const mySkills = '/my-skills';
  static const reviews = '/reviews';
  static const badges = '/badges';

  // Settings and support
  static const settings = '/settings';
  static const blockedMembers = '/settings/blocked-members';
  static const help = '/settings/help';
  static const about = '/settings/about';
  static const notifications = '/notifications';
  static const safety = '/safety';
  static const reportMember = '/report/member';
  static const reportTrade = '/report/trade';
  static const disputeCaseDetails = '/disputes';
  static const complaint = '/complaint';

  static const notFound = '/not-found';
}
