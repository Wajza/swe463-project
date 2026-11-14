import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/models/listing_kind.dart';
import 'package:souq_skills/models/otp_request.dart';
import 'package:souq_skills/models/proposal_request.dart';
import 'package:souq_skills/screens/auth/app_gate.dart';
import 'package:souq_skills/screens/auth/create_account_profile_screen.dart';
import 'package:souq_skills/screens/auth/otp_verification_screen.dart';
import 'package:souq_skills/screens/auth/phone_screen.dart';
import 'package:souq_skills/screens/chats/direct_chat_screen.dart';
import 'package:souq_skills/screens/chats/proposal_details_screen.dart';
import 'package:souq_skills/screens/chats/proposal_inside_chat.dart';
import 'package:souq_skills/screens/group_trades/edit_group_trade_screen.dart';
import 'package:souq_skills/screens/group_trades/group_trade_chat_screen.dart';
import 'package:souq_skills/screens/group_trades/group_trade_details_screen.dart';
import 'package:souq_skills/screens/group_trades/group_trades_list_screen.dart';
import 'package:souq_skills/screens/home/saved_skills_screen.dart';
import 'package:souq_skills/screens/listings/edit_listing_screen.dart';
import 'package:souq_skills/screens/listings/listing_details_screen.dart';
import 'package:souq_skills/screens/listings/listing_reviews_screen.dart';
import 'package:souq_skills/screens/listings/my_listings_screen.dart';
import 'package:souq_skills/screens/listings/post_skill/post_skill_screen.dart';
import 'package:souq_skills/screens/listings/post_skill/published_screen.dart';
import 'package:souq_skills/screens/notifications/notifications_screen.dart';
import 'package:souq_skills/screens/profile/badges_screen.dart';
import 'package:souq_skills/screens/profile/edit_profile_screen.dart';
import 'package:souq_skills/screens/profile/my_skills_screen.dart';
import 'package:souq_skills/screens/profile/public_member_profile_screen.dart';
import 'package:souq_skills/screens/profile/reviews_screen.dart';
import 'package:souq_skills/screens/profile/settings/about_screen.dart';
import 'package:souq_skills/screens/profile/settings/blocked_members_screen.dart';
import 'package:souq_skills/screens/profile/settings/help_center_screen.dart';
import 'package:souq_skills/screens/profile/settings/settings_screen.dart';
import 'package:souq_skills/screens/safety/complaint_screen.dart';
import 'package:souq_skills/screens/safety/dispute_case_details_screen.dart';
import 'package:souq_skills/screens/safety/report_member_screen.dart';
import 'package:souq_skills/screens/safety/report_trade_screen.dart';
import 'package:souq_skills/screens/safety/safety_centre_screen.dart';
import 'package:souq_skills/screens/shell/main_shell.dart';
import 'package:souq_skills/screens/trades/dispute_trade_screen.dart';
import 'package:souq_skills/screens/trades/my_trades_screen.dart';
import 'package:souq_skills/screens/trades/rate_trade_screen.dart';
import 'package:souq_skills/screens/trades/schedule_session_screen.dart';
import 'package:souq_skills/screens/trades/trade_details_screen.dart';
import 'package:souq_skills/screens/utility/not_found_screen.dart';
import 'package:souq_skills/screens/utility/share_listing_screen.dart';
import 'package:souq_skills/screens/wallet/skill_credits_screen.dart';

typedef _PageBuilder = Widget Function(Object? arguments);

/// Maps every route name to its screen. A route that needs an argument falls
/// back to [NotFoundScreen] when the argument is missing or has the wrong type.
class AppRouter {
  const AppRouter._();

  static final Map<String, _PageBuilder> _pages = {
    AppRoutes.welcome: _page(const AppGate()),
    AppRoutes.phone: _page(const PhoneScreen()),
    AppRoutes.otpVerification: _withArg<OtpRequest>(
      (request) => OtpVerificationScreen(request: request),
    ),
    AppRoutes.createAccountProfile: _withArg<String>(
      (phone) => CreateAccountProfileScreen(phone: phone),
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
    AppRoutes.skillCredits: _page(const SkillCreditsScreen()),
    AppRoutes.savedSkills: _page(const SavedSkillsScreen()),
    AppRoutes.createListing: (arguments) => PostSkillScreen(
      initialKind: arguments is ListingKind ? arguments : ListingKind.solo,
    ),
    AppRoutes.listingDetails: _withArg<String>(
      (id) => ListingDetailsScreen(listingId: id),
    ),
    AppRoutes.listingReviews: _withArg<String>(
      (id) => ListingReviewsScreen(listingId: id),
    ),
    AppRoutes.listingPublished: _withArg<String>(
      (id) => PublishedScreen(listingId: id),
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
    AppRoutes.chat: _withArg<String>((id) => DirectChatScreen(memberId: id)),
    AppRoutes.groupChat: _withArg<String>(
      (id) => GroupTradeChatScreen(groupId: id),
    ),
    AppRoutes.proposalInsideChat: _withArg<ProposalRequest>(
      (request) => ProposalInsideChat(request: request),
    ),
    AppRoutes.proposalDetails: _withArg<String>(
      (id) => ProposalDetailsScreen(proposalId: id),
    ),
    AppRoutes.myTrades: _page(const MyTradesScreen()),
    AppRoutes.tradeDetails: _withArg<String>(
      (id) => TradeDetailsScreen(tradeId: id),
    ),
    AppRoutes.scheduleSession: _withArg<String>(
      (id) => ScheduleSessionScreen(tradeId: id),
    ),
    AppRoutes.disputeTrade: _withArg<String>(
      (id) => DisputeTradeScreen(tradeId: id),
    ),
    AppRoutes.rateTrade: _withArg<String>(
      (id) => RateTradeScreen(contextId: id),
    ),
    AppRoutes.groupTrades: _page(const GroupTradesListScreen()),
    AppRoutes.groupTradeDetails: _withArg<String>(
      (id) => GroupTradeDetailsScreen(groupId: id),
    ),
    AppRoutes.editGroupTrade: _withArg<String>(
      (id) => EditGroupTradeScreen(groupId: id),
    ),
    AppRoutes.editProfile: _page(const EditProfileScreen()),
    AppRoutes.mySkills: _page(const MySkillsScreen()),
    AppRoutes.reviews: _page(const ReviewsScreen()),
    AppRoutes.badges: _page(const BadgesScreen()),
    AppRoutes.settings: _page(const SettingsScreen()),
    AppRoutes.blockedMembers: _page(const BlockedMembersScreen()),
    AppRoutes.help: _page(const HelpCenterScreen()),
    AppRoutes.about: _page(const AboutScreen()),
    AppRoutes.notifications: _page(const NotificationsScreen()),
    AppRoutes.safety: _page(const SafetyCentreScreen()),
    AppRoutes.reportMember: _withArg<String>(
      (id) => ReportMemberScreen(memberId: id),
    ),
    AppRoutes.reportTrade: _withArg<String>(
      (id) => ReportTradeScreen(tradeId: id),
    ),
    AppRoutes.disputeCaseDetails: _withArg<String>(
      (id) => DisputeCaseDetailsScreen(caseId: id),
    ),
    AppRoutes.complaint: _page(const ComplaintScreen()),
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
