import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/models/otp_request.dart';
import 'package:souq_skills/models/proposal_request.dart';
import 'package:souq_skills/models/saved_search.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/screens/auth/create_account_phone_screen.dart';
import 'package:souq_skills/screens/auth/create_account_profile_screen.dart';
import 'package:souq_skills/screens/auth/onboarding_screen.dart';
import 'package:souq_skills/screens/auth/otp_verification_screen.dart';
import 'package:souq_skills/screens/auth/returning_user_sign_in_screen.dart';
import 'package:souq_skills/screens/chats/counteroffer_screen.dart';
import 'package:souq_skills/screens/chats/direct_chat_screen.dart';
import 'package:souq_skills/screens/chats/proposal_details_screen.dart';
import 'package:souq_skills/screens/chats/proposal_inside_chat.dart';
import 'package:souq_skills/screens/group_trades/create_group_trade_screen.dart';
import 'package:souq_skills/screens/group_trades/edit_group_trade_screen.dart';
import 'package:souq_skills/screens/group_trades/group_trade_chat_screen.dart';
import 'package:souq_skills/screens/group_trades/group_trade_completion_screen.dart';
import 'package:souq_skills/screens/group_trades/group_trade_details_screen.dart';
import 'package:souq_skills/screens/group_trades/group_trade_invitation_screen.dart';
import 'package:souq_skills/screens/group_trades/group_trades_list_screen.dart';
import 'package:souq_skills/screens/home/category_filter_screen.dart';
import 'package:souq_skills/screens/home/city_filter_screen.dart';
import 'package:souq_skills/screens/home/saved_searches_screen.dart';
import 'package:souq_skills/screens/home/saved_skills_screen.dart';
import 'package:souq_skills/screens/home/search_alerts_screen.dart';
import 'package:souq_skills/screens/home/search_results_screen.dart';
import 'package:souq_skills/screens/listings/edit_listing_screen.dart';
import 'package:souq_skills/screens/listings/listing_details_screen.dart';
import 'package:souq_skills/screens/listings/my_listings_screen.dart';
import 'package:souq_skills/screens/listings/post_skill/listing_information_screen.dart';
import 'package:souq_skills/screens/listings/post_skill/listing_preview_screen.dart';
import 'package:souq_skills/screens/listings/post_skill/post_confirmation_screen.dart';
import 'package:souq_skills/screens/listings/post_skill/skill_category_screen.dart';
import 'package:souq_skills/screens/listings/post_skill/skill_details_screen.dart';
import 'package:souq_skills/screens/listings/public_skill_list_screen.dart';
import 'package:souq_skills/screens/notifications/notification_details_screen.dart';
import 'package:souq_skills/screens/notifications/notifications_screen.dart';
import 'package:souq_skills/screens/profile/account_details_screen.dart';
import 'package:souq_skills/screens/profile/badge_details_screen.dart';
import 'package:souq_skills/screens/profile/badges_screen.dart';
import 'package:souq_skills/screens/profile/edit_profile_screen.dart';
import 'package:souq_skills/screens/profile/my_skills_screen.dart';
import 'package:souq_skills/screens/profile/public_member_profile_screen.dart';
import 'package:souq_skills/screens/profile/reviews_screen.dart';
import 'package:souq_skills/screens/profile/settings/about_screen.dart';
import 'package:souq_skills/screens/profile/settings/app_preferences_screen.dart';
import 'package:souq_skills/screens/profile/settings/blocked_members_screen.dart';
import 'package:souq_skills/screens/profile/settings/community_guidelines_screen.dart';
import 'package:souq_skills/screens/profile/settings/contact_support_screen.dart';
import 'package:souq_skills/screens/profile/settings/delete_account_screen.dart';
import 'package:souq_skills/screens/profile/settings/help_center_screen.dart';
import 'package:souq_skills/screens/profile/settings/location_permission_screen.dart';
import 'package:souq_skills/screens/profile/settings/notification_preferences_screen.dart';
import 'package:souq_skills/screens/profile/settings/privacy_policy_screen.dart';
import 'package:souq_skills/screens/profile/settings/privacy_settings_screen.dart';
import 'package:souq_skills/screens/profile/settings/settings_screen.dart';
import 'package:souq_skills/screens/profile/settings/terms_screen.dart';
import 'package:souq_skills/screens/safety/block_member_screen.dart';
import 'package:souq_skills/screens/safety/dispute_case_details_screen.dart';
import 'package:souq_skills/screens/safety/report_member_screen.dart';
import 'package:souq_skills/screens/safety/report_received_screen.dart';
import 'package:souq_skills/screens/safety/report_trade_screen.dart';
import 'package:souq_skills/screens/safety/safety_centre_screen.dart';
import 'package:souq_skills/screens/safety/support_messages_screen.dart';
import 'package:souq_skills/screens/shell/main_shell.dart';
import 'package:souq_skills/screens/trades/dispute_trade_screen.dart';
import 'package:souq_skills/screens/trades/my_trades_screen.dart';
import 'package:souq_skills/screens/trades/rate_trade_screen.dart';
import 'package:souq_skills/screens/trades/schedule_session_screen.dart';
import 'package:souq_skills/screens/trades/trade_completion_screen.dart';
import 'package:souq_skills/screens/trades/trade_details_screen.dart';
import 'package:souq_skills/screens/trades/trade_history_screen.dart';
import 'package:souq_skills/screens/trades/trade_status_screen.dart';
import 'package:souq_skills/screens/utility/error_screen.dart';
import 'package:souq_skills/screens/utility/loading_screen.dart';
import 'package:souq_skills/screens/utility/not_found_screen.dart';
import 'package:souq_skills/screens/utility/notification_permission_screen.dart';
import 'package:souq_skills/screens/utility/offline_screen.dart';
import 'package:souq_skills/screens/utility/share_listing_screen.dart';
import 'package:souq_skills/screens/wallet/transaction_details_screen.dart';

typedef _PageBuilder = Widget Function(Object? arguments);

/// Maps every route name to its screen. A route that needs an argument falls
/// back to [NotFoundScreen] when the argument is missing or has the wrong type.
class AppRouter {
  const AppRouter._();

  static final Map<String, _PageBuilder> _pages = {
    AppRoutes.welcome: _page(const OnboardingScreen()),
    AppRoutes.signIn: _page(const ReturningUserSignInScreen()),
    AppRoutes.createAccount: _page(const CreateAccountPhoneScreen()),
    AppRoutes.otpVerification: _withArg<OtpRequest>(
      (request) => OtpVerificationScreen(request: request),
    ),
    AppRoutes.createAccountProfile: _withArg<String>(
      (phone) => CreateAccountProfileScreen(phone: phone),
    ),
    AppRoutes.notificationPermission: _page(
      const NotificationPermissionScreen(),
    ),
    AppRoutes.home: _page(const MainShell(initialIndex: MainShell.homeTab)),
    AppRoutes.chats: _page(const MainShell(initialIndex: MainShell.chatsTab)),
    AppRoutes.postSkill: _page(
      const MainShell(initialIndex: MainShell.postTab),
    ),
    AppRoutes.wallet: _page(const MainShell(initialIndex: MainShell.walletTab)),
    AppRoutes.profile: _page(
      const MainShell(initialIndex: MainShell.profileTab),
    ),
    AppRoutes.skillCategory: _page(const SkillCategoryScreen()),
    AppRoutes.skillDetails: _withArg<SkillListing>(
      (draft) => SkillDetailsScreen(draft: draft),
    ),
    AppRoutes.listingInformation: _withArg<SkillListing>(
      (draft) => ListingInformationScreen(draft: draft),
    ),
    AppRoutes.listingPreview: _withArg<SkillListing>(
      (draft) => ListingPreviewScreen(draft: draft),
    ),
    AppRoutes.postConfirmation: _withArg<String>(
      (id) => PostConfirmationScreen(listingId: id),
    ),
    AppRoutes.searchResults: (arguments) => SearchResultsScreen(
      initial: arguments is SavedSearch ? arguments : const SavedSearch(),
    ),
    AppRoutes.categoryFilter: _page(const CategoryFilterScreen()),
    AppRoutes.cityFilter: _page(const CityFilterScreen()),
    AppRoutes.savedSkills: _page(const SavedSkillsScreen()),
    AppRoutes.savedSearches: _page(const SavedSearchesScreen()),
    AppRoutes.searchAlerts: _page(const SearchAlertsScreen()),
    AppRoutes.listingDetails: _withArg<String>(
      (id) => ListingDetailsScreen(listingId: id),
    ),
    AppRoutes.editListing: _withArg<String>(
      (id) => EditListingScreen(listingId: id),
    ),
    AppRoutes.shareListing: _withArg<String>(
      (id) => ShareListingScreen(listingId: id),
    ),
    AppRoutes.myListings: _page(const MyListingsScreen()),
    AppRoutes.memberProfile: _withArg<String>(
      (id) => PublicMemberProfileScreen(memberId: id),
    ),
    AppRoutes.publicSkillList: _withArg<String>(
      (id) => PublicSkillListScreen(memberId: id),
    ),
    AppRoutes.chat: _withArg<String>((id) => DirectChatScreen(memberId: id)),
    AppRoutes.groupChat: _withArg<String>(
      (id) => GroupTradeChatScreen(groupId: id),
    ),
    AppRoutes.proposalInsideChat: _withArg<ProposalRequest>(
      (request) => ProposalInsideChat(request: request),
    ),
    AppRoutes.counteroffer: _withArg<String>(
      (id) => CounterofferScreen(proposalId: id),
    ),
    AppRoutes.proposalDetails: _withArg<String>(
      (id) => ProposalDetailsScreen(proposalId: id),
    ),
    AppRoutes.myTrades: _page(const MyTradesScreen()),
    AppRoutes.tradeHistory: _page(const TradeHistoryScreen()),
    AppRoutes.tradeDetails: _withArg<String>(
      (id) => TradeDetailsScreen(tradeId: id),
    ),
    AppRoutes.tradeStatus: _withArg<String>(
      (id) => TradeStatusScreen(tradeId: id),
    ),
    AppRoutes.scheduleSession: _withArg<String>(
      (id) => ScheduleSessionScreen(tradeId: id),
    ),
    AppRoutes.tradeCompletion: _withArg<String>(
      (id) => TradeCompletionScreen(tradeId: id),
    ),
    AppRoutes.disputeTrade: _withArg<String>(
      (id) => DisputeTradeScreen(tradeId: id),
    ),
    AppRoutes.rateTrade: _withArg<String>(
      (id) => RateTradeScreen(contextId: id),
    ),
    AppRoutes.groupTrades: _page(const GroupTradesListScreen()),
    AppRoutes.createGroupTrade: _page(const CreateGroupTradeScreen()),
    AppRoutes.groupTradeDetails: _withArg<String>(
      (id) => GroupTradeDetailsScreen(groupId: id),
    ),
    AppRoutes.editGroupTrade: _withArg<String>(
      (id) => EditGroupTradeScreen(groupId: id),
    ),
    AppRoutes.groupTradeInvitation: _withArg<String>(
      (id) => GroupTradeInvitationScreen(groupId: id),
    ),
    AppRoutes.groupTradeCompletion: _withArg<String>(
      (id) => GroupTradeCompletionScreen(groupId: id),
    ),
    AppRoutes.transactionDetails: _withArg<String>(
      (id) => TransactionDetailsScreen(transactionId: id),
    ),
    AppRoutes.accountDetails: _page(const AccountDetailsScreen()),
    AppRoutes.editProfile: _page(const EditProfileScreen()),
    AppRoutes.mySkills: _page(const MySkillsScreen()),
    AppRoutes.reviews: _page(const ReviewsScreen()),
    AppRoutes.badges: _page(const BadgesScreen()),
    AppRoutes.badgeDetails: _withArg<String>(
      (id) => BadgeDetailsScreen(badgeId: id),
    ),
    AppRoutes.settings: _page(const SettingsScreen()),
    AppRoutes.appPreferences: _page(const AppPreferencesScreen()),
    AppRoutes.privacySettings: _page(const PrivacySettingsScreen()),
    AppRoutes.notificationPreferences: _page(
      const NotificationPreferencesScreen(),
    ),
    AppRoutes.blockedMembers: _page(const BlockedMembersScreen()),
    AppRoutes.locationPermission: _page(const LocationPermissionScreen()),
    AppRoutes.help: _page(const HelpCenterScreen()),
    AppRoutes.terms: _page(const TermsScreen()),
    AppRoutes.privacyPolicy: _page(const PrivacyPolicyScreen()),
    AppRoutes.communityGuidelines: _page(const CommunityGuidelinesScreen()),
    AppRoutes.about: _page(const AboutScreen()),
    AppRoutes.contactSupport: _page(const ContactSupportScreen()),
    AppRoutes.deleteAccount: _page(const DeleteAccountScreen()),
    AppRoutes.notifications: _page(const NotificationsScreen()),
    AppRoutes.notificationDetails: _withArg<String>(
      (id) => NotificationDetailsScreen(notificationId: id),
    ),
    AppRoutes.safety: _page(const SafetyCentreScreen()),
    AppRoutes.reportMember: _withArg<String>(
      (id) => ReportMemberScreen(memberId: id),
    ),
    AppRoutes.blockMember: _withArg<String>(
      (id) => BlockMemberScreen(memberId: id),
    ),
    AppRoutes.reportTrade: _withArg<String>(
      (id) => ReportTradeScreen(tradeId: id),
    ),
    AppRoutes.reportReceived: _withArg<String>(
      (id) => ReportReceivedScreen(caseId: id),
    ),
    AppRoutes.disputeCaseDetails: _withArg<String>(
      (id) => DisputeCaseDetailsScreen(caseId: id),
    ),
    AppRoutes.supportMessages: _page(const SupportMessagesScreen()),
    AppRoutes.loading: _page(const LoadingScreen()),
    AppRoutes.error: _page(const ErrorScreen()),
    AppRoutes.offline: _page(const OfflineScreen()),
    AppRoutes.notFound: _page(const NotFoundScreen()),
  };

  static Iterable<String> get routeNames => _pages.keys;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final builder = _pages[settings.name] ?? _pages[AppRoutes.notFound]!;
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => builder(settings.arguments),
    );
  }

  static _PageBuilder _page(Widget screen) =>
      (_) => screen;

  static _PageBuilder _withArg<T>(Widget Function(T argument) build) =>
      (arguments) => arguments is T ? build(arguments) : const NotFoundScreen();
}
