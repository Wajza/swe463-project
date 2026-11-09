import 'package:flutter/material.dart';

import 'core/app_routes.dart';
import 'core/app_store.dart';
import 'core/app_theme.dart';
import 'screens/auth/create_account_phone_screen.dart';
import 'screens/auth/create_account_profile_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/returning_user_sign_in_screen.dart';
import 'screens/chats/chats_screen.dart';
import 'screens/chats/counteroffer_screen.dart';
import 'screens/chats/direct_chat_screen.dart';
import 'screens/chats/proposal_details_screen.dart';
import 'screens/chats/proposal_inside_chat.dart';
import 'screens/group_trades/create_group_trade_screen.dart';
import 'screens/group_trades/edit_group_trade_screen.dart';
import 'screens/group_trades/group_trade_chat_screen.dart';
import 'screens/group_trades/group_trade_completion_screen.dart';
import 'screens/group_trades/group_trade_details_screen.dart';
import 'screens/group_trades/group_trade_invitation_screen.dart';
import 'screens/group_trades/group_trades_list_screen.dart';
import 'screens/home/category_filter_screen.dart';
import 'screens/home/city_filter_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/saved_searches_screen.dart';
import 'screens/home/saved_skills_screen.dart';
import 'screens/home/search_alerts_screen.dart';
import 'screens/home/search_results_screen.dart';
import 'screens/listings/edit_listing_screen.dart';
import 'screens/listings/listing_details_screen.dart';
import 'screens/listings/my_listings_screen.dart';
import 'screens/listings/public_skill_list_screen.dart';
import 'screens/listings/post_skill/listing_information_screen.dart';
import 'screens/listings/post_skill/listing_preview_screen.dart';
import 'screens/listings/post_skill/post_confirmation_screen.dart';
import 'screens/listings/post_skill/skill_category_screen.dart';
import 'screens/listings/post_skill/skill_details_screen.dart';
import 'screens/notifications/notification_details_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/profile/account_details_screen.dart';
import 'screens/profile/badge_details_screen.dart';
import 'screens/profile/badges_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/my_skills_screen.dart';
import 'screens/profile/my_trades_screen.dart' as profile_trades;
import 'screens/profile/profile_screen.dart';
import 'screens/profile/reviews_screen.dart';
import 'screens/profile/settings/about_screen.dart';
import 'screens/profile/settings/app_preferences_screen.dart';
import 'screens/profile/settings/blocked_members_screen.dart';
import 'screens/profile/settings/community_guidelines_screen.dart';
import 'screens/profile/settings/contact_support_screen.dart';
import 'screens/profile/settings/delete_account_screen.dart';
import 'screens/profile/settings/help_center_screen.dart';
import 'screens/profile/settings/location_permission_screen.dart';
import 'screens/profile/settings/notification_preferences_screen.dart';
import 'screens/profile/settings/privacy_policy_screen.dart';
import 'screens/profile/settings/privacy_settings_screen.dart';
import 'screens/profile/settings/settings_screen.dart';
import 'screens/profile/settings/terms_screen.dart';
import 'screens/safety/block_member_screen.dart';
import 'screens/safety/dispute_case_details_screen.dart';
import 'screens/safety/report_member_screen.dart';
import 'screens/safety/report_received_screen.dart';
import 'screens/safety/report_trade_screen.dart';
import 'screens/safety/safety_centre_screen.dart';
import 'screens/safety/support_messages_screen.dart';
import 'screens/trades/dispute_trade_screen.dart';
import 'screens/trades/my_trades_screen.dart' as direct_trades;
import 'screens/trades/rate_trade_screen.dart';
import 'screens/trades/schedule_session_screen.dart';
import 'screens/trades/trade_completion_screen.dart';
import 'screens/trades/trade_details_screen.dart';
import 'screens/trades/trade_history_screen.dart';
import 'screens/trades/trade_status_screen.dart';
import 'screens/utility/not_found_screen.dart';
import 'screens/utility/error_screen.dart';
import 'screens/utility/loading_screen.dart';
import 'screens/utility/notification_permission_screen.dart';
import 'screens/utility/offline_screen.dart';
import 'screens/utility/share_listing_screen.dart';
import 'screens/wallet/wallet_screen.dart';
import 'screens/wallet/transaction_details_screen.dart';
import 'widgets/app_bottom_navigation.dart';

class SouqSkillsApp extends StatelessWidget {
  const SouqSkillsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (context, _) => MaterialApp(
        title: 'Souq Skills',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        initialRoute: AppRoutes.welcome,
        onGenerateRoute: AppRouteRegistry.onGenerateRoute,
        onUnknownRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => const NotFoundScreen(),
        ),
      ),
    );
  }
}

class AppRouteRegistry {
  const AppRouteRegistry._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.welcome:
        return _page(const OnboardingScreen(), settings);
      case AppRoutes.signIn:
        return _page(const ReturningUserSignInScreen(), settings);
      case AppRoutes.createAccount:
        return _page(const CreateAccountPhoneScreen(), settings);
      case AppRoutes.otpVerification:
        return _page(const OtpVerificationScreen(), settings);
      case AppRoutes.createAccountProfile:
        return _page(const CreateAccountProfileScreen(), settings);
      case AppRoutes.home:
        return _page(const MainShell(initialIndex: 0), settings);
      case AppRoutes.chats:
        return _page(const MainShell(initialIndex: 1), settings);
      case AppRoutes.postSkill:
        return _page(const MainShell(initialIndex: 2), settings);
      case AppRoutes.wallet:
        return _page(const MainShell(initialIndex: 3), settings);
      case AppRoutes.profile:
        return _page(const MainShell(initialIndex: 4), settings);
      case AppRoutes.skillCategory:
        return _page(const SkillCategoryScreen(), settings);
      case AppRoutes.skillDetails:
        return _page(const SkillDetailsScreen(), settings);
      case AppRoutes.listingInformation:
        return _page(const ListingInformationScreen(), settings);
      case AppRoutes.listingPreview:
        return _page(const ListingPreviewScreen(), settings);
      case AppRoutes.postConfirmation:
        return _page(const PostConfirmationScreen(), settings);
      case AppRoutes.searchResults:
        return _page(const SearchResultsScreen(), settings);
      case AppRoutes.categoryFilter:
        return _page(const CategoryFilterScreen(), settings);
      case AppRoutes.cityFilter:
        return _page(const CityFilterScreen(), settings);
      case AppRoutes.savedSkills:
        return _page(const SavedSkillsScreen(), settings);
      case AppRoutes.savedSkillDetails:
        return _page(const SavedSkillsScreen(), settings);
      case AppRoutes.savedSearches:
        return _page(const SavedSearchesScreen(), settings);
      case AppRoutes.searchAlerts:
        return _page(const SearchAlertsScreen(), settings);
      case AppRoutes.listingDetails:
        return _page(const ListingDetailsScreen(), settings);
      case AppRoutes.editListing:
        return _page(const EditListingScreen(), settings);
      case AppRoutes.myListings:
        return _page(const MyListingsScreen(), settings);
      case AppRoutes.publicSkillList:
        return _page(const PublicSkillListScreen(), settings);
      case AppRoutes.memberProfile:
        return _page(const PublicSkillListScreen(), settings);
      case AppRoutes.chat:
        return _page(const DirectChatScreen(), settings);
      case AppRoutes.proposalInsideChat:
        return _page(const ProposalInsideChat(), settings);
      case AppRoutes.counteroffer:
        return _page(const CounterofferScreen(), settings);
      case AppRoutes.proposalDetails:
        return _page(const ProposalDetailsScreen(), settings);
      case AppRoutes.groupChat:
        return _page(const GroupTradeChatScreen(), settings);
      case AppRoutes.myTrades:
        return _page(const direct_trades.MyTradesScreen(), settings);
      case AppRoutes.tradeDetails:
        return _page(const TradeDetailsScreen(), settings);
      case AppRoutes.tradeStatus:
        return _page(const TradeStatusScreen(), settings);
      case AppRoutes.tradeHistory:
        return _page(const TradeHistoryScreen(), settings);
      case AppRoutes.scheduleSession:
        return _page(const ScheduleSessionScreen(), settings);
      case AppRoutes.tradeCompletion:
        return _page(const TradeCompletionScreen(), settings);
      case AppRoutes.rateTrade:
        return _page(const RateTradeScreen(), settings);
      case AppRoutes.disputeTrade:
        return _page(const DisputeTradeScreen(), settings);
      case AppRoutes.groupTrades:
        return _page(const GroupTradesListScreen(), settings);
      case AppRoutes.createGroupTrade:
        return _page(const CreateGroupTradeScreen(), settings);
      case AppRoutes.groupTradeDetails:
        return _page(const GroupTradeDetailsScreen(), settings);
      case AppRoutes.editGroupTrade:
        return _page(const EditGroupTradeScreen(), settings);
      case AppRoutes.groupTradeInvitation:
        return _page(const GroupTradeInvitationScreen(), settings);
      case AppRoutes.groupTradeCompletion:
        return _page(const GroupTradeCompletionScreen(), settings);
      case AppRoutes.transactionDetails:
        return _page(const TransactionDetailsScreen(), settings);
      case AppRoutes.accountDetails:
        return _page(const AccountDetailsScreen(), settings);
      case AppRoutes.editProfile:
        return _page(const EditProfileScreen(), settings);
      case AppRoutes.mySkills:
        return _page(const MySkillsScreen(), settings);
      case AppRoutes.profileTrades:
        return _page(const profile_trades.ProfileMyTradesScreen(), settings);
      case AppRoutes.reviews:
        return _page(const ReviewsScreen(), settings);
      case AppRoutes.badges:
        return _page(const BadgesScreen(), settings);
      case AppRoutes.badgeDetails:
        return _page(const BadgeDetailsScreen(), settings);
      case AppRoutes.settings:
        return _page(const SettingsScreen(), settings);
      case AppRoutes.appPreferences:
        return _page(const AppPreferencesScreen(), settings);
      case AppRoutes.privacySettings:
        return _page(const PrivacySettingsScreen(), settings);
      case AppRoutes.notificationPreferences:
        return _page(const NotificationPreferencesScreen(), settings);
      case AppRoutes.blockedMembers:
        return _page(const BlockedMembersScreen(), settings);
      case AppRoutes.locationPermission:
        return _page(const LocationPermissionScreen(), settings);
      case AppRoutes.help:
        return _page(const HelpCenterScreen(), settings);
      case AppRoutes.terms:
        return _page(const TermsScreen(), settings);
      case AppRoutes.privacyPolicy:
        return _page(const PrivacyPolicyScreen(), settings);
      case AppRoutes.communityGuidelines:
        return _page(const CommunityGuidelinesScreen(), settings);
      case AppRoutes.about:
        return _page(const AboutScreen(), settings);
      case AppRoutes.contactSupport:
        return _page(const ContactSupportScreen(), settings);
      case AppRoutes.deleteAccount:
        return _page(const DeleteAccountScreen(), settings);
      case AppRoutes.notifications:
        return _page(const NotificationsScreen(), settings);
      case AppRoutes.notificationDetails:
        return _page(const NotificationDetailsScreen(), settings);
      case AppRoutes.safety:
        return _page(const SafetyCentreScreen(), settings);
      case AppRoutes.reportMember:
        return _page(const ReportMemberScreen(), settings);
      case AppRoutes.blockMember:
        return _page(const BlockMemberScreen(), settings);
      case AppRoutes.reportTrade:
        return _page(const ReportTradeScreen(), settings);
      case AppRoutes.reportReceived:
        return _page(const ReportReceivedScreen(), settings);
      case AppRoutes.disputeCaseDetails:
        return _page(const DisputeCaseDetailsScreen(), settings);
      case AppRoutes.supportMessages:
        return _page(const SupportMessagesScreen(), settings);
      case AppRoutes.review:
        return _page(const RateTradeScreen(), settings);
      case AppRoutes.notificationPermission:
        return _page(const NotificationPermissionScreen(), settings);
      case AppRoutes.loading:
        return _page(const LoadingScreen(), settings);
      case AppRoutes.error:
        return _page(const ErrorScreen(), settings);
      case AppRoutes.offline:
        return _page(const OfflineScreen(), settings);
      case AppRoutes.shareListing:
        return _page(const ShareListingScreen(), settings);
      default:
        return _page(const NotFoundScreen(), settings);
    }
  }

  static MaterialPageRoute<T> _page<T>(Widget child, RouteSettings settings) {
    return MaterialPageRoute<T>(
      settings: settings,
      builder: (_) => child,
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({this.initialIndex = 0, super.key});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int selectedIndex = widget.initialIndex.clamp(0, 4).toInt();

  static const pages = <Widget>[
    HomeScreen(),
    ChatsScreen(),
    SkillCategoryScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: AppBottomNavigation(
        index: selectedIndex,
        onChanged: (index) => setState(() => selectedIndex = index),
      ),
    );
  }
}
