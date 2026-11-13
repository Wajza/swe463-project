import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/core/app_router.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/data/auth_repository.dart';
import 'package:souq_skills/data/chat_repository.dart';
import 'package:souq_skills/data/device_account_store.dart';
import 'package:souq_skills/data/group_trade_repository.dart';
import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/data/trade_repository.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/models/notification.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/screens/notifications/notifications_screen.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/chat_service.dart';
import 'package:souq_skills/services/group_trade_service.dart';
import 'package:souq_skills/services/notification_service.dart';
import 'package:souq_skills/services/online_groups.dart';
import 'package:souq_skills/services/online_trades.dart';
import 'package:souq_skills/services/online_wallet.dart';
import 'package:souq_skills/services/repository.dart';

import 'support/memory_data_source.dart';

const _maha = 'uid-maha';
const _sami = 'uid-sami';
const _lina = 'uid-lina';

final _tomorrow = DateTime.now().add(const Duration(days: 1));

/// Lets listeners, and the member names they wait for, catch up.
Future<void> _settle() async {
  for (var i = 0; i < 3; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

const _group = GroupTrade(
  title: 'Design skill circle',
  description: 'A group exchange around Figma.',
  skills: ['Figma'],
);

TradeProposal _draft({
  String from = _sami,
  String to = _maha,
  int credits = 0,
}) => TradeProposal(
  senderId: from,
  receiverId: to,
  offeredSkill: 'Baking',
  requestedSkill: 'Flutter',
  creditsOffered: credits,
);

/// The offline sign-in with a Firebase-like uid that can change.
class _Auth extends DemoAuthRepository {
  _Auth() : super(isKnownPhone: AuthService().isKnownPhone);

  String? currentUid = _maha;

  @override
  String? get uid => currentUid;
}

User _user(String first, String username) => User(
  id: User.currentUserId,
  firstName: first,
  lastName: 'Test',
  username: username,
  phone: '501234567',
  city: 'Jeddah',
  isVerified: true,
);

void main() {
  final repository = Repository.instance;
  final originalAuth = AuthService.repository;
  final blocks = <String, Set<String>>{};
  late _Auth auth;
  late DemoChatRepository chats;
  late DemoTradeRepository trades;
  late DemoGroupTradeRepository groups;

  setUp(() async {
    repository
      ..dataSource = MemoryDataSource()
      ..reset();
    auth = _Auth();
    AuthService.repository = auth;
    AuthService.deviceAccount = MemoryDeviceAccountStore(_maha);
    final profiles = DemoProfileRepository();
    await profiles.saveProfile(_maha, _user('Maha', 'maha_z'));
    await profiles.saveProfile(_sami, _user('Sami', 'sami_a'));
    await profiles.saveProfile(_lina, _user('Lina', 'lina_s'));
    AuthService.profiles = profiles;
    blocks.clear();
    bool hasBlocked(String uid, String other) =>
        blocks[uid]?.contains(other) ?? false;
    chats = DemoChatRepository(hasBlocked: hasBlocked);
    trades = DemoTradeRepository(hasBlocked: hasBlocked);
    groups = DemoGroupTradeRepository(
      hasBlocked: hasBlocked,
      wallets: trades.wallets,
    );
    ChatService.repository = chats;
    OnlineTrades.repository = trades;
    OnlineGroups.repository = groups;
    AuthService().signIn();
    await _settle();
    // The demo's own sample notifications are left out of each check.
    repository.notifications.clear();
  });

  tearDown(() {
    OnlineGroups.repository = null;
    OnlineTrades.repository = null;
    OnlineWallet.syncSession();
    ChatService.repository = null;
    AuthService.profiles = null;
    AuthService.deviceAccount = null;
    AuthService.repository = originalAuth;
  });

  List<String> titles([NotificationType? type]) => [
    for (final item in NotificationService().all())
      if (type == null || item.type == type) item.title,
  ];

  AppNotification only(String title) =>
      NotificationService().all().singleWhere((item) => item.title == title);

  void turnOff({bool messages = true, bool trades = true, bool groups = true}) {
    repository.updateSettings(
      repository.settings.copyWith(
        messageNotifications: messages,
        tradeNotifications: trades,
        groupNotifications: groups,
      ),
    );
  }

  group('group trades', () {
    /// Sami's group, with Maha invited.
    Future<String> samiInvitesMaha() async {
      final id = await groups.create(_sami, _group);
      await groups.invite(_sami, id, _maha);
      await _settle();
      return id;
    }

    test('an invitation is notified once, and opens the group', () async {
      final id = await samiInvitesMaha();

      final notice = only('Group trade invitation');
      expect(notice.message, 'Sami Test invited you to Design skill circle.');
      expect(notice.type, NotificationType.groupTrade);
      expect(notice.route, AppRoutes.groupTradeDetails);
      expect(notice.routeArgument, id);

      // Later changes to the same group do not notify it again.
      await groups.updateDetails(
        _sami,
        id,
        _group.copyWith(title: 'Renamed circle'),
      );
      await _settle();
      expect(titles(), ['Group trade invitation']);
    });

    test('creating or changing one\'s own group notifies nothing', () async {
      final id = await GroupTradeService().createGroup(_group);
      await groups.invite(_maha, id, _sami);
      await groups.respondToInvitation(_sami, id, accept: true);
      await _settle();
      expect(titles(), isEmpty);
    });

    test('a new group message is notified, but not one\'s own', () async {
      final id = await samiInvitesMaha();
      await GroupTradeService().acceptInvitation(id);
      await _settle();
      repository.notifications.clear();

      await ChatService().sendToGroup(id, 'Hello everyone');
      await _settle();
      expect(titles(), isEmpty);

      await groups.sendMessage(_sami, id, 'Hi Maha');
      await _settle();
      final notice = only('New message in Design skill circle');
      expect(notice.message, 'Sami Test: Hi Maha');
      expect(notice.type, NotificationType.message);
      expect(notice.route, AppRoutes.groupChat);
      expect(notice.routeArgument, id);
    });

    test(
      'messages in an open group chat, or from before, are not notified',
      () async {
        final id = await samiInvitesMaha();
        await groups.sendMessage(_sami, id, 'Sent before Maha joined');
        await GroupTradeService().acceptInvitation(id);
        await _settle();
        repository.notifications.clear();

        final chatId = ChatService.groupConversationId(id);
        ChatService().open(chatId);
        await groups.sendMessage(_sami, id, 'While the chat is open');
        await _settle();
        ChatService().close(chatId);
        expect(titles(), isEmpty);

        // Once the chat is closed, each new message is notified once.
        await groups.sendMessage(_sami, id, 'One');
        await groups.sendMessage(_sami, id, 'Two');
        await _settle();
        expect(
          NotificationService().all().map((item) => item.message),
          unorderedEquals(['Sami Test: One', 'Sami Test: Two']),
        );
      },
    );

    test('completion is notified when another member completes it', () async {
      final id = await samiInvitesMaha();
      await GroupTradeService().acceptInvitation(id);
      await GroupTradeService().complete(id);
      await _settle();
      repository.notifications.clear();

      await groups.confirmCompletion(_sami, id);
      await _settle();
      final notice = only('Group trade completed');
      expect(notice.message, contains('Each member gets 15 credits.'));
      expect(notice.routeArgument, id);
    });

    test('completing it oneself notifies nothing', () async {
      final id = await samiInvitesMaha();
      await GroupTradeService().acceptInvitation(id);
      await groups.confirmCompletion(_sami, id);
      await _settle();
      repository.notifications.clear();

      expect(await GroupTradeService().complete(id), isTrue);
      await _settle();
      expect(titles(), isEmpty);
    });

    test('blocked members and switched-off settings are respected', () async {
      repository.blockedMemberIds.add(_sami);
      await samiInvitesMaha();
      expect(titles(), isEmpty);

      repository.blockedMemberIds.clear();
      turnOff(groups: false);
      await samiInvitesMaha();
      expect(titles(), isEmpty);

      turnOff();
      final id = await samiInvitesMaha();
      await GroupTradeService().acceptInvitation(id);
      await _settle();
      repository.notifications.clear();
      turnOff(messages: false);
      await groups.sendMessage(_sami, id, 'Hi');
      await _settle();
      expect(titles(), isEmpty);
    });
  });

  group('one-to-one trades', () {
    Future<SentProposal> mahaProposes() async {
      final sent = await trades.sendProposal(
        _maha,
        _draft(from: _maha, to: _sami),
      );
      await _settle();
      return sent;
    }

    test('a new proposal and a counteroffer are notified', () async {
      final sent = await trades.sendProposal(_sami, _draft());
      await _settle();
      final notice = only('New trade proposal');
      expect(notice.message, 'Sami Test sent you a proposal.');
      expect(notice.route, AppRoutes.tradeDetails);
      expect(notice.routeArgument, sent.tradeId);

      // Maha counters: her own step is not notified.
      final counter = await trades.counterProposal(
        _maha,
        tradeId: sent.tradeId,
        proposalId: sent.proposalId,
        draft: _draft(from: _maha, to: _sami, credits: 10),
      );
      await _settle();
      expect(titles(), ['New trade proposal']);

      await trades.counterProposal(
        _sami,
        tradeId: sent.tradeId,
        proposalId: counter,
        draft: _draft(),
      );
      await _settle();
      expect(
        only('New counteroffer').message,
        'Sami Test sent you a counteroffer.',
      );
    });

    test('a proposal declined or cancelled by the other member', () async {
      final mine = await mahaProposes();
      expect(titles(), isEmpty, reason: 'her own proposal');
      await trades.respondToProposal(
        _sami,
        tradeId: mine.tradeId,
        proposalId: mine.proposalId,
        response: ProposalStatus.declined,
      );
      await _settle();
      expect(
        only('Proposal declined').message,
        'Sami Test declined your proposal.',
      );

      final theirs = await trades.sendProposal(_sami, _draft());
      await trades.respondToProposal(
        _sami,
        tradeId: theirs.tradeId,
        proposalId: theirs.proposalId,
        response: ProposalStatus.cancelled,
      );
      await _settle();
      expect(
        only('Proposal cancelled').message,
        'Sami Test cancelled their proposal.',
      );
    });

    test('a session booked and rescheduled by the other member', () async {
      final sent = await mahaProposes();
      await trades.respondToProposal(
        _sami,
        tradeId: sent.tradeId,
        proposalId: sent.proposalId,
        response: ProposalStatus.accepted,
      );
      Future<void> schedule(String uid, DateTime at) => trades.scheduleSession(
        uid,
        tradeId: sent.tradeId,
        scheduledAt: at,
        method: 'Online',
        locationOrLink: '',
        notes: '',
      );
      await schedule(_sami, _tomorrow);
      await _settle();
      expect(titles(), ['Session booked', 'Proposal accepted']);
      expect(
        only('Session booked').message,
        startsWith('Sami Test booked a session for '),
      );

      await schedule(_sami, _tomorrow.add(const Duration(days: 1)));
      await _settle();
      expect(
        only('Session rescheduled').message,
        startsWith('Sami Test changed the session to '),
      );

      // Maha's own rescheduling is not notified.
      await schedule(_maha, _tomorrow.add(const Duration(days: 2)));
      await _settle();
      expect(titles(), hasLength(3));
    });

    test('blocked members and the trades switch are respected', () async {
      repository.blockedMemberIds.add(_sami);
      await trades.sendProposal(_sami, _draft());
      await _settle();
      expect(titles(), isEmpty);

      repository.blockedMemberIds.clear();
      turnOff(trades: false);
      await trades.sendProposal(_sami, _draft());
      await _settle();
      expect(titles(), isEmpty);
    });

    test('a trade step in the chat is notified once, by the trade', () async {
      final sent = await trades.sendProposal(_sami, _draft());
      // Sami's app shows the proposal card in the chat too.
      await chats.sendMessage(
        _sami,
        ChatMessageDraft(
          memberId: _maha,
          text: 'Trade proposal',
          kind: ChatMessageKind.proposal,
          proposalId: sent.proposalId,
          tradeId: sent.tradeId,
        ),
      );
      await _settle();
      expect(titles(), ['New trade proposal']);

      // A message Sami types is still notified as a message.
      await chats.sendMessage(
        _sami,
        const ChatMessageDraft(memberId: _maha, text: 'Does Monday work?'),
      );
      await _settle();
      expect(titles(NotificationType.message), ['New message from Sami Test']);
    });
  });

  group('accounts', () {
    test('signing in does not notify what happened before', () async {
      final id = await groups.create(_sami, _group);
      await groups.invite(_sami, id, _lina);
      await trades.sendProposal(_sami, _draft(to: _lina));
      await _settle();
      expect(titles(), isEmpty, reason: 'nothing for Maha');

      auth.currentUid = _lina;
      OnlineTrades.syncSession();
      OnlineGroups.syncSession();
      ChatService.syncSession();
      await _settle();
      expect(titles(), isEmpty, reason: 'older events are only shown');
      expect(GroupTradeService().all().map((g) => g.id), contains(id));

      await trades.sendProposal(_sami, _draft(to: _lina));
      await _settle();
      expect(titles(), ['New trade proposal']);
    });

    test('a change for the previous account is never notified', () async {
      await trades.sendProposal(_sami, _draft());
      // Another account signs in before the change arrives.
      auth.currentUid = _lina;
      OnlineTrades.syncSession();
      await _settle();
      expect(titles(), isEmpty);
    });
  });

  testWidgets('tapping a notification marks it read and opens its screen', (
    tester,
  ) async {
    final id = await tester.runAsync(() async {
      final id = await groups.create(_sami, _group);
      await groups.invite(_sami, id, _maha);
      await _settle();
      return id;
    });
    await tester.pumpWidget(
      const MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: NotificationsScreen(),
      ),
    );
    expect(NotificationService().unreadCount(), 1);

    await tester.tap(find.text('Group trade invitation'));
    await tester.pumpAndSettle();

    expect(NotificationService().unreadCount(), 0);
    expect(only('Group trade invitation').isRead, isTrue);
    expect(find.text('Design skill circle'), findsWidgets);
    expect(find.text('Accept invitation'), findsOneWidget);
    expect(GroupTradeService().byId(id!), isNotNull);
  });

  testWidgets('mark all as read clears the unread count', (tester) async {
    await tester.runAsync(() async {
      await trades.sendProposal(_sami, _draft());
      await trades.sendProposal(_sami, _draft());
      await _settle();
    });
    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));
    expect(NotificationService().unreadCount(), 2);

    await tester.tap(find.byTooltip('Mark all as read'));
    await tester.pump();
    expect(NotificationService().unreadCount(), 0);
  });
}
