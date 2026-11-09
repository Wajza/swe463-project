import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/badge_config.dart';
import 'package:souq_skills/models/app_settings.dart';
import 'package:souq_skills/models/dispute_case.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/models/message.dart';
import 'package:souq_skills/models/notification.dart';
import 'package:souq_skills/models/review.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/models/trade_session.dart';
import 'package:souq_skills/models/transaction.dart';
import 'package:souq_skills/models/user.dart';

const _me = User.currentUserId;
const _sami = 'm-sami';
const _lina = 'm-lina';
const _omar = 'm-omar';
const _noura = 'm-noura';
const _faisal = 'm-faisal';

/// The sample data behind this front-end-only build.
class SeedData {
  const SeedData({
    required this.currentUser,
    required this.members,
    required this.listings,
    required this.groupTrades,
    required this.reviews,
    required this.notifications,
    required this.transactions,
    this.messages = const [],
    this.proposals = const [],
    this.trades = const [],
    this.sessions = const [],
    this.disputes = const [],
    this.awardedBadgeIds = const {},
    this.blockedMemberIds = const {},
    this.settings = const AppSettings(),
  });

  final User currentUser;
  final List<User> members;
  final List<SkillListing> listings;
  final List<Message> messages;
  final List<TradeProposal> proposals;
  final List<Trade> trades;
  final List<TradeSession> sessions;
  final List<GroupTrade> groupTrades;
  final List<AppNotification> notifications;
  final List<WalletTransaction> transactions;
  final List<Review> reviews;
  final List<DisputeCase> disputes;
  final Set<String> awardedBadgeIds;
  final Set<String> blockedMemberIds;
  final AppSettings settings;

  static const welcomeCredits = 120;

  /// Community data only, for someone who just created an account.
  factory SeedData.newMember(User user) {
    final demo = SeedData.demo();
    final now = DateTime.now();
    return SeedData(
      currentUser: user,
      members: demo.members,
      listings: demo.listings
          .where((item) => item.ownerId != _me)
          .map((item) => item.copyWith(isSaved: false))
          .toList(),
      groupTrades: demo.groupTrades
          .where((group) => group.ownerId != _me)
          .map(
            (group) => group.copyWith(
              memberIds: group.memberIds.where((id) => id != _me).toList(),
              invitedIds: const [],
            ),
          )
          .toList(),
      reviews: demo.reviews
          .where((item) => item.authorId != _me && item.subjectId != _me)
          .toList(),
      transactions: [
        WalletTransaction(
          id: 'tx-welcome',
          title: 'Welcome credits',
          subtitle: 'A gift for joining Souq Skills',
          amount: welcomeCredits,
          date: now,
        ),
      ],
      notifications: [
        AppNotification(
          id: 'n-welcome',
          title: 'Welcome to Souq Skills',
          message: 'Post your first skill to start trading.',
          createdAt: now,
          route: AppRoutes.createListing,
        ),
      ],
    );
  }

  factory SeedData.demo() {
    final now = DateTime.now();
    DateTime hoursAgo(int hours) => now.subtract(Duration(hours: hours));
    DateTime daysAgo(int days) => now.subtract(Duration(days: days));

    return SeedData(
      currentUser: const User(
        id: _me,
        firstName: 'Yara',
        lastName: 'Alghamdi',
        username: 'yara',
        city: 'Riyadh',
        phone: '501234567',
        isVerified: true,
        bio: 'Product designer who loves teaching and learning languages.',
        skillsOffered: ['UI design', 'Figma', 'English tutoring'],
        skillsWanted: ['Arabic calligraphy', 'Photography'],
        availability: 'Weekday evenings',
      ),
      members: const [
        User(
          id: _sami,
          firstName: 'Sami',
          lastName: 'Alharbi',
          username: 'sami',
          city: 'Riyadh',
          isVerified: true,
          bio: 'Software engineer and weekend photographer.',
          skillsOffered: ['Flutter', 'Photography'],
          skillsWanted: ['UI design'],
          availability: 'Weekends',
        ),
        User(
          id: _lina,
          firstName: 'Lina',
          lastName: 'Alqahtani',
          username: 'lina',
          city: 'Jeddah',
          isVerified: true,
          bio: 'Arabic calligrapher and art teacher.',
          skillsOffered: ['Arabic calligraphy', 'Drawing'],
          skillsWanted: ['English tutoring'],
          availability: 'Afternoons',
        ),
        User(
          id: _omar,
          firstName: 'Omar',
          lastName: 'Aziz',
          username: 'omar',
          city: 'Dammam',
          isVerified: true,
          bio: 'Home chef and small business owner.',
          skillsOffered: ['Saudi cooking', 'Bookkeeping'],
          skillsWanted: ['Social media'],
          availability: 'Evenings',
        ),
        User(
          id: _noura,
          firstName: 'Noura',
          lastName: 'Alotaibi',
          username: 'noura',
          city: 'Riyadh',
          isVerified: true,
          bio: 'Personal trainer focused on women’s fitness.',
          skillsOffered: ['Fitness coaching'],
          skillsWanted: ['Figma'],
          availability: 'Mornings',
        ),
        User(
          id: _faisal,
          firstName: 'Faisal',
          lastName: 'Alshehri',
          username: 'faisal',
          city: 'Makkah',
          bio: 'Oud player who repairs instruments.',
          skillsOffered: ['Oud lessons', 'Instrument repair'],
          skillsWanted: ['Website building'],
          availability: 'Flexible',
        ),
      ],
      listings: const [
        SkillListing(
          id: 'l-flutter',
          ownerId: _sami,
          title: 'Build your first Flutter app',
          category: 'Technology',
          offers: 'Flutter',
          wants: 'UI design',
          distance: '2 km',
          description:
              'Hands-on sessions that take you from setup to a working app.',
          availability: 'Weekends',
          sessionsMinutes: 90,
          onlineOnly: true,
          isSaved: true,
        ),
        SkillListing(
          id: 'l-photo',
          ownerId: _sami,
          title: 'Portrait photography basics',
          category: 'Photography',
          offers: 'Photography',
          wants: 'Figma',
          distance: '2 km',
          description: 'Learn light, framing, and editing with your own phone.',
          availability: 'Saturday mornings',
        ),
        SkillListing(
          id: 'l-calligraphy',
          ownerId: _lina,
          title: 'Arabic calligraphy for beginners',
          category: 'Design',
          offers: 'Arabic calligraphy',
          wants: 'English tutoring',
          distance: '950 km',
          city: 'Jeddah',
          description: 'Practise Naskh and Diwani scripts step by step.',
          availability: 'Afternoons',
          sessionsMinutes: 45,
          onlineOnly: true,
          womenOnly: true,
        ),
        SkillListing(
          id: 'l-cooking',
          ownerId: _omar,
          title: 'Traditional Saudi cooking',
          category: 'Cooking',
          offers: 'Saudi cooking',
          wants: 'Social media',
          distance: '400 km',
          city: 'Dammam',
          description: 'Cook kabsa and jareesh together, spice by spice.',
          availability: 'Evenings',
          sessionsMinutes: 120,
        ),
        SkillListing(
          id: 'l-fitness',
          ownerId: _noura,
          title: 'Home strength coaching',
          category: 'Fitness',
          offers: 'Fitness coaching',
          wants: 'Figma',
          distance: '5 km',
          description: 'A simple strength plan you can follow at home.',
          availability: 'Mornings',
          sessionsMinutes: 45,
          womenOnly: true,
        ),
        SkillListing(
          id: 'l-oud',
          ownerId: _faisal,
          title: 'Oud lessons from scratch',
          category: 'Music',
          offers: 'Oud lessons',
          wants: 'Website building',
          distance: '870 km',
          city: 'Makkah',
          description: 'Tuning, first maqams, and your first complete song.',
          availability: 'Flexible',
          onlineOnly: true,
        ),
        SkillListing(
          id: 'l-yara-ui',
          ownerId: _me,
          title: 'UI design mentoring',
          category: 'Design',
          offers: 'UI design',
          wants: 'Arabic calligraphy',
          description: 'Portfolio reviews and practical Figma walkthroughs.',
          availability: 'Weekday evenings',
          onlineOnly: true,
        ),
        SkillListing(
          id: 'l-yara-english',
          ownerId: _me,
          title: 'Conversational English',
          category: 'Languages',
          offers: 'English tutoring',
          wants: 'Photography',
          description: 'Relaxed speaking practice for everyday confidence.',
          availability: 'Weekday evenings',
          sessionsMinutes: 45,
          onlineOnly: true,
        ),
      ],
      proposals: const [
        TradeProposal(
          id: 'p-omar',
          tradeId: 't-omar',
          senderId: _me,
          receiverId: _omar,
          offeredSkill: 'UI design',
          requestedSkill: 'Bookkeeping',
          status: ProposalStatus.accepted,
        ),
        TradeProposal(
          id: 'p-lina',
          tradeId: 't-lina',
          senderId: _lina,
          receiverId: _me,
          offeredSkill: 'Arabic calligraphy',
          requestedSkill: 'English tutoring',
          sessionsMinutes: 45,
          status: ProposalStatus.accepted,
        ),
        TradeProposal(
          id: 'p-sami',
          tradeId: 't-sami',
          senderId: _me,
          receiverId: _sami,
          offeredSkill: 'UI design',
          requestedSkill: 'Photography',
          status: ProposalStatus.accepted,
        ),
        TradeProposal(
          id: 'p-faisal',
          tradeId: 't-faisal',
          senderId: _me,
          receiverId: _faisal,
          offeredSkill: 'Figma',
          requestedSkill: 'Oud lessons',
          status: ProposalStatus.accepted,
        ),
        TradeProposal(
          id: 'p-noura',
          tradeId: 't-noura',
          senderId: _noura,
          receiverId: _me,
          offeredSkill: 'Fitness coaching',
          requestedSkill: 'Figma',
          sessionsMinutes: 45,
          deliveryMethod: 'In person',
          notes: 'Could we start next week?',
        ),
        TradeProposal(
          id: 'p-declined',
          tradeId: 't-declined',
          senderId: _me,
          receiverId: _faisal,
          offeredSkill: 'English tutoring',
          requestedSkill: 'Instrument repair',
          status: ProposalStatus.declined,
        ),
      ],
      trades: const [
        Trade(
          id: 't-omar',
          proposalId: 'p-omar',
          otherMemberId: _omar,
          offeredSkill: 'UI design',
          requestedSkill: 'Bookkeeping',
          status: TradeStatus.completed,
          sessionId: 's-omar',
        ),
        Trade(
          id: 't-lina',
          proposalId: 'p-lina',
          otherMemberId: _lina,
          offeredSkill: 'English tutoring',
          requestedSkill: 'Arabic calligraphy',
          sessionsMinutes: 45,
          status: TradeStatus.completed,
          sessionId: 's-lina',
        ),
        Trade(
          id: 't-sami',
          proposalId: 'p-sami',
          otherMemberId: _sami,
          offeredSkill: 'UI design',
          requestedSkill: 'Photography',
          status: TradeStatus.accepted,
          sessionId: 's-sami',
        ),
        Trade(
          id: 't-faisal',
          proposalId: 'p-faisal',
          otherMemberId: _faisal,
          offeredSkill: 'Figma',
          requestedSkill: 'Oud lessons',
          status: TradeStatus.accepted,
        ),
        Trade(
          id: 't-noura',
          proposalId: 'p-noura',
          otherMemberId: _noura,
          offeredSkill: 'Figma',
          requestedSkill: 'Fitness coaching',
          sessionsMinutes: 45,
        ),
        Trade(
          id: 't-declined',
          proposalId: 'p-declined',
          otherMemberId: _faisal,
          offeredSkill: 'English tutoring',
          requestedSkill: 'Instrument repair',
          status: TradeStatus.declined,
        ),
      ],
      sessions: [
        TradeSession(
          id: 's-omar',
          tradeId: 't-omar',
          scheduledAt: daysAgo(12),
          method: 'Online',
          isCompleted: true,
        ),
        TradeSession(
          id: 's-lina',
          tradeId: 't-lina',
          scheduledAt: daysAgo(2),
          method: 'Online',
          isCompleted: true,
        ),
        TradeSession(
          id: 's-sami',
          tradeId: 't-sami',
          scheduledAt: now.add(const Duration(days: 1)),
          method: 'In person',
          locationOrLink: 'King Fahad Library, Riyadh',
        ),
      ],
      groupTrades: const [
        GroupTrade(
          id: 'g-design',
          title: 'Design and code circle',
          ownerId: _sami,
          memberIds: [_sami, _lina, _me],
          skills: ['Flutter', 'UI design', 'Calligraphy'],
          description: 'Members teach each other one craft every week.',
          sessionsMinutes: 90,
        ),
        GroupTrade(
          id: 'g-food',
          title: 'Riyadh food swap',
          ownerId: _omar,
          memberIds: [_omar, _noura],
          invitedIds: [_me],
          skills: ['Saudi cooking', 'Nutrition'],
          status: GroupTradeStatus.negotiating,
          description: 'Share healthy recipes and cook together.',
          sessionsMinutes: 120,
        ),
        GroupTrade(
          id: 'g-language',
          title: 'Language exchange club',
          ownerId: _me,
          memberIds: [_me, _lina],
          skills: ['English', 'Arabic'],
          description: 'Weekly conversation swaps between English and Arabic.',
          sessionsMinutes: 45,
        ),
      ],
      messages: [
        Message(
          id: 'msg-1',
          conversationId: _sami,
          text: 'Looking forward to our session tomorrow!',
          senderName: 'Sami Alharbi',
          createdAt: hoursAgo(5),
          isRead: false,
        ),
        Message(
          id: 'msg-2',
          conversationId: _lina,
          text: 'Thank you, that was a lovely lesson.',
          senderName: 'Lina Alqahtani',
          createdAt: daysAgo(2),
        ),
        Message(
          id: 'msg-3',
          conversationId: _noura,
          text: 'Hi Yara, I sent you a proposal.',
          senderName: 'Noura Alotaibi',
          createdAt: hoursAgo(9),
          isRead: false,
        ),
        Message(
          id: 'msg-4',
          conversationId: _noura,
          text: 'Trade proposal',
          senderName: 'Noura Alotaibi',
          createdAt: hoursAgo(9),
          isRead: false,
          proposalId: 'p-noura',
        ),
        Message(
          id: 'msg-5',
          conversationId: _faisal,
          text: 'When would you like to start the oud lessons?',
          senderName: 'Faisal Alshehri',
          createdAt: daysAgo(1),
        ),
        Message(
          id: 'msg-6',
          conversationId: 'group:g-design',
          text: 'Next meetup is on Thursday, everyone.',
          senderName: 'Sami Alharbi',
          createdAt: hoursAgo(20),
        ),
      ],
      notifications: [
        AppNotification(
          id: 'n-proposal',
          title: 'New trade proposal',
          message: 'Noura wants to trade fitness coaching for Figma.',
          type: NotificationType.trade,
          createdAt: hoursAgo(9),
          route: AppRoutes.proposalDetails,
          routeArgument: 'p-noura',
        ),
        AppNotification(
          id: 'n-rate',
          title: 'How was your exchange?',
          message: 'Rate your trade with Lina to share your experience.',
          type: NotificationType.review,
          createdAt: daysAgo(2),
          route: AppRoutes.rateTrade,
          routeArgument: 't-lina',
        ),
        AppNotification(
          id: 'n-invite',
          title: 'Group trade invitation',
          message: 'Omar invited you to the Riyadh food swap.',
          type: NotificationType.groupTrade,
          createdAt: daysAgo(3),
          route: AppRoutes.groupTradeDetails,
          routeArgument: 'g-food',
        ),
      ],
      transactions: [
        WalletTransaction(
          id: 'tx-welcome',
          title: 'Welcome credits',
          subtitle: 'A gift for joining Souq Skills',
          amount: welcomeCredits,
          date: daysAgo(40),
        ),
        WalletTransaction(
          id: 'tx-omar',
          title: 'Trade completed',
          subtitle: 'UI design ⇄ Bookkeeping',
          amount: 10,
          date: daysAgo(12),
          tradeId: 't-omar',
          participantName: 'Omar Aziz',
        ),
        WalletTransaction(
          id: 'tx-lina',
          title: 'Trade completed',
          subtitle: 'English tutoring ⇄ Arabic calligraphy',
          amount: 10,
          date: daysAgo(2),
          tradeId: 't-lina',
          participantName: 'Lina Alqahtani',
        ),
        WalletTransaction(
          id: 'tx-boost',
          title: 'Listing boost',
          subtitle: 'UI design mentoring',
          amount: -15,
          date: daysAgo(6),
          type: TransactionType.spent,
        ),
      ],
      reviews: [
        Review(
          id: 'r-1',
          authorId: _omar,
          subjectId: _me,
          contextId: 't-omar',
          skillTitle: 'UI design',
          rating: 5,
          comment: 'Clear, kind, and very well prepared.',
          date: daysAgo(11),
        ),
        Review(
          id: 'r-2',
          authorId: _lina,
          subjectId: _me,
          contextId: 't-lina',
          skillTitle: 'English tutoring',
          rating: 4.5,
          comment: 'My confidence improved after just one session.',
          date: daysAgo(2),
        ),
        Review(
          id: 'r-3',
          authorId: _sami,
          subjectId: _me,
          skillTitle: 'Figma',
          rating: 5,
          comment: 'Yara explains design decisions brilliantly.',
          date: daysAgo(20),
        ),
        Review(
          id: 'r-4',
          authorId: _noura,
          subjectId: _me,
          skillTitle: 'UI design',
          rating: 4,
          comment: 'Great advice for my portfolio.',
          date: daysAgo(30),
        ),
        Review(
          id: 'r-5',
          authorId: _me,
          subjectId: _omar,
          contextId: 't-omar',
          skillTitle: 'Bookkeeping',
          rating: 4,
          comment: 'Practical tips I could use straight away.',
          date: daysAgo(11),
        ),
        Review(
          id: 'r-6',
          authorId: _lina,
          subjectId: _sami,
          skillTitle: 'Flutter',
          rating: 5,
          comment: 'Patient teacher with great examples.',
          date: daysAgo(14),
        ),
        Review(
          id: 'r-7',
          authorId: _noura,
          subjectId: _lina,
          skillTitle: 'Arabic calligraphy',
          rating: 4.5,
          comment: 'Beautiful technique and calm teaching.',
          date: daysAgo(16),
        ),
        Review(
          id: 'r-8',
          authorId: _sami,
          subjectId: _noura,
          skillTitle: 'Fitness coaching',
          rating: 4.5,
          comment: 'The plan was easy to follow.',
          date: daysAgo(18),
        ),
      ],
      disputes: [
        DisputeCase(
          id: 'c-seed',
          caseNumber: 'SQ-1000',
          kind: CaseKind.tradeReport,
          reason: 'Member did not attend',
          tradeId: 't-declined',
          status: DisputeStatus.underReview,
          createdAt: daysAgo(5),
        ),
      ],
      awardedBadgeIds: const {
        BadgeConfig.firstExchange,
        BadgeConfig.topRated,
        BadgeConfig.communityBuilder,
      },
    );
  }
}
