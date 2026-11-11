import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/data/auth_repository.dart';
import 'package:souq_skills/data/chat_repository.dart';
import 'package:souq_skills/data/device_account_store.dart';
import 'package:souq_skills/data/group_trade_repository.dart';
import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/data/trade_repository.dart';
import 'package:souq_skills/data/wallet_repository.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/models/listing_kind.dart';
import 'package:souq_skills/models/skill_post.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/screens/group_trades/group_trade_details_screen.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/chat_service.dart';
import 'package:souq_skills/services/group_trade_service.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/services/online_groups.dart';
import 'package:souq_skills/services/online_trades.dart';
import 'package:souq_skills/services/online_wallet.dart';
import 'package:souq_skills/services/posting_service.dart';
import 'package:souq_skills/services/repository.dart';
import 'package:souq_skills/services/wallet_service.dart';

import 'support/memory_data_source.dart';

const _maha = 'uid-maha';
const _sami = 'uid-sami';
const _lina = 'uid-lina';
const _noura = 'uid-noura';
const _welcome = WalletDocument.welcomeCredits;
const _reward = WalletDocument.groupReward;

const _usernames = {'maha_z': _maha, 'sami_a': _sami, 'lina_s': _lina};

Future<void> _settle() => Future<void>.delayed(Duration.zero);

const _draft = GroupTrade(
  title: 'Design skill circle',
  description: 'A group exchange around Figma.',
  skills: ['Figma'],
);

/// Whether the local id `'me'` appears anywhere in stored [value].
bool _mentionsMe(Object? value) => switch (value) {
  String() => value == User.currentUserId,
  Map() => value.keys.any(_mentionsMe) || value.values.any(_mentionsMe),
  List() => value.any(_mentionsMe),
  _ => false,
};

/// The in-memory server, whose confirmations can be made to fail.
class _Groups extends DemoGroupTradeRepository {
  _Groups({super.uidOfUsername, super.wallets});

  GroupTradeException? failConfirmations;

  @override
  Future<bool> confirmCompletion(String uid, String groupId) {
    final error = failConfirmations;
    if (error != null) return Future.error(error);
    return super.confirmCompletion(uid, groupId);
  }
}

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
  group('group trades on the server', () {
    late DemoGroupTradeRepository server;
    late DemoWalletRepository wallets;
    final blocks = <String, Set<String>>{};

    setUp(() {
      blocks.clear();
      wallets = DemoWalletRepository();
      server = DemoGroupTradeRepository(
        isRealMember: (uid) => uid != 'uid-gone',
        hasBlocked: (uid, other) => blocks[uid]?.contains(other) ?? false,
        uidOfUsername: (key) => _usernames[key],
        wallets: wallets,
      );
    });

    Future<GroupTrade?> groupAs(String uid, String groupId) async {
      final groups = await server.watchGroups(uid).first;
      return groups.where((item) => item.id == groupId).firstOrNull;
    }

    /// An open group by Maha with Sami and Lina as members.
    Future<String> groupOfThree() async {
      final id = await server.create(_maha, _draft);
      for (final uid in [_sami, _lina]) {
        await server.invite(_maha, id, uid);
        await server.respondToInvitation(uid, id, accept: true);
      }
      return id;
    }

    test(
      'a group is stored by uid and seen only by members and invitees',
      () async {
        final id = await server.create(_maha, _draft);
        await server.invite(_maha, id, await server.findMember('@Sami_A'));

        final stored = server.storedGroup(id)!;
        expect(stored['ownerId'], _maha);
        expect(stored['invitedIds'], [_sami]);
        expect(_mentionsMe(stored), isFalse);

        final asSami = (await groupAs(_sami, id))!;
        expect(server.storedGroup(id)!['status'], 'open');
        expect(asSami.ownerId, _maha);
        expect(asSami.invitedIds, [User.currentUserId]);
        final asMaha = (await groupAs(_maha, id))!;
        expect(asMaha.ownerId, User.currentUserId);
        expect(asMaha.memberIds, [User.currentUserId]);
        expect(await groupAs(_lina, id), isNull);
      },
    );

    test('invitations are checked as the rules check them', () async {
      final id = await server.create(_maha, _draft);
      Future<void> invite(String uid, String member) =>
          server.invite(uid, id, member);

      await expectLater(
        server.findMember('nobody'),
        throwsA(GroupTradeException.unknownUsername),
      );
      await expectLater(
        server.findMember('a b'),
        throwsA(GroupTradeException.unknownUsername),
      );
      await expectLater(
        invite(_maha, _maha),
        throwsA(GroupTradeException.cannotInvite),
      );
      await expectLater(
        invite(_maha, 'uid-gone'),
        throwsA(GroupTradeException.notSaved),
      );
      blocks[_sami] = {_maha};
      await expectLater(
        invite(_maha, _sami),
        throwsA(GroupTradeException.notSaved),
      );
      blocks.clear();
      await invite(_maha, _sami);
      await expectLater(
        invite(_maha, _sami),
        throwsA(GroupTradeException.alreadyInGroup),
      );
      await server.respondToInvitation(_sami, id, accept: true);
      await expectLater(
        invite(_sami, _lina),
        throwsA(GroupTradeException.notSaved),
        reason: 'only the organizer invites',
      );
      for (var i = 0; i < GroupTradeDocument.maxSize - 2; i++) {
        await invite(_maha, 'uid-extra-$i');
      }
      await expectLater(
        invite(_maha, _lina),
        throwsA(GroupTradeException.groupFull),
      );
    });

    test('invitees accept or decline only their own invitation', () async {
      final id = await server.create(_maha, _draft);
      await server.invite(_maha, id, _sami);

      await expectLater(
        server.respondToInvitation(_lina, id, accept: true),
        throwsA(GroupTradeException.notFound),
      );
      await server.respondToInvitation(_sami, id, accept: false);
      expect(await groupAs(_sami, id), isNull);
      expect(server.storedGroup(id)!['memberIds'], [_maha]);
    });

    test('the group completes once every member has confirmed', () async {
      final id = await groupOfThree();

      expect(await server.confirmCompletion(_maha, id), isFalse);
      await expectLater(
        server.confirmCompletion(_maha, id),
        throwsA(GroupTradeException.alreadyConfirmed),
      );
      expect(await server.confirmCompletion(_sami, id), isFalse);
      expect((await groupAs(_maha, id))!.confirmedIds, hasLength(2));
      expect(await server.confirmCompletion(_lina, id), isTrue);
      expect(server.storedGroup(id)!['status'], 'completed');
      await expectLater(
        server.confirmCompletion(_noura, id),
        throwsA(isA<GroupTradeException>()),
      );
    });

    test('a group of one cannot complete', () async {
      final id = await server.create(_maha, _draft);
      await expectLater(
        server.confirmCompletion(_maha, id),
        throwsA(GroupTradeException.notEnoughMembers),
      );
    });

    test('leaving or being removed takes the confirmation along', () async {
      final id = await groupOfThree();
      await server.confirmCompletion(_lina, id);

      await expectLater(
        server.removeMember(_sami, id, _lina),
        throwsA(GroupTradeException.notSaved),
        reason: 'members cannot remove each other',
      );
      await expectLater(
        server.removeMember(_maha, id, _maha),
        throwsA(GroupTradeException.notSaved),
        reason: 'the organizer never leaves',
      );
      await server.removeMember(_maha, id, _lina);
      expect(server.storedGroup(id)!['completedBy'], isEmpty);
      expect(await groupAs(_lina, id), isNull);

      // The last member who had not confirmed leaves: the others finish.
      await server.invite(_maha, id, _lina);
      await server.respondToInvitation(_lina, id, accept: true);
      await server.confirmCompletion(_maha, id);
      await server.confirmCompletion(_sami, id);
      await server.removeMember(_lina, id, _lina);
      expect(await server.confirmCompletion(_sami, id), isTrue);
    });

    test('completed and cancelled groups are final', () async {
      final id = await groupOfThree();
      for (final uid in [_maha, _sami, _lina]) {
        await server.confirmCompletion(uid, id);
      }
      for (final change in <Future<void> Function()>[
        () => server.invite(_maha, id, _noura),
        () => server.removeMember(_sami, id, _sami),
        () => server.updateDetails(_maha, id, _draft),
        () => server.cancel(_maha, id),
      ]) {
        await expectLater(change(), throwsA(GroupTradeException.notSaved));
      }

      final other = await groupOfThree();
      await expectLater(
        server.cancel(_sami, other),
        throwsA(GroupTradeException.notSaved),
      );
      await server.cancel(_maha, other);
      await expectLater(
        server.sendMessage(_sami, other, 'Hello'),
        throwsA(GroupTradeException.messageNotSent),
      );
    });

    test('each member of a completed group is rewarded once', () async {
      final id = await groupOfThree();
      await server.invite(_maha, id, _noura);
      await expectLater(
        server.claimReward(_maha, id),
        throwsA(WalletException.rewardNotAdded),
        reason: 'not completed yet',
      );
      for (final uid in [_maha, _sami, _lina]) {
        await server.confirmCompletion(uid, id);
      }

      for (final uid in [_maha, _sami, _lina]) {
        await server.claimReward(uid, id);
        await server.claimReward(uid, id);
        expect(
          WalletDocument.balanceOf(wallets.storedWallet(uid)),
          _welcome + _reward,
        );
        final entry = wallets.storedEntries(
          uid,
        )[WalletDocument.groupRewardId(id)]!;
        expect(entry['amount'], _reward);
        expect(entry['groupId'], id);
      }
      await expectLater(
        server.claimReward(_noura, id),
        throwsA(WalletException.rewardNotAdded),
        reason: 'only invited',
      );
      expect(WalletDocument.balanceOf(wallets.storedWallet(_noura)), _welcome);
    });

    test('only members read and write the group chat', () async {
      final id = await groupOfThree();
      await server.invite(_maha, id, _noura);

      await server.sendMessage(_sami, id, '  Hello group  ');
      await expectLater(
        server.sendMessage(_noura, id, 'Hi'),
        throwsA(GroupTradeException.messageNotSent),
      );
      await expectLater(
        server.sendMessage(_sami, id, '   '),
        throwsA(GroupTradeException.messageNotSent),
      );
      final [message] = await server.watchMessages(_lina, id).first;
      expect(message.text, 'Hello group');
      expect(message.senderId, _sami);
      expect(await server.watchMessages(_noura, id).first, isEmpty);
      final [mine] = await server.watchMessages(_sami, id).first;
      expect(mine.senderId, User.currentUserId);
    });
  });

  group('group trades in the app', () {
    final repository = Repository.instance;
    final originalAuth = AuthService.repository;
    late _Auth auth;
    late DemoTradeRepository trades;
    late _Groups groups;

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
      ChatService.repository = DemoChatRepository();
      trades = DemoTradeRepository();
      groups = _Groups(
        uidOfUsername: (key) => _usernames[key],
        wallets: trades.wallets,
      );
      OnlineTrades.repository = trades;
      OnlineGroups.repository = groups;
      AuthService().signIn();
      await _settle();
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

    /// Maha publishes a group from the post form; returns its id.
    Future<String> publish() async {
      final id = await PostingService().publish(
        const SkillPost(
          kind: ListingKind.group,
          category: 'Design',
          skills: ['Figma', 'UI'],
          city: 'Riyadh',
          availability: 'Weekends',
        ),
      );
      await _settle();
      return id;
    }

    /// Maha's group with Sami as a member.
    Future<GroupTrade> groupWithSami() async {
      final id = await publish();
      await GroupTradeService().inviteByUsername(
        GroupTradeService().byId(id)!,
        'sami_a',
      );
      await groups.respondToInvitation(_sami, id, accept: true);
      await _settle();
      return GroupTradeService().byId(id)!;
    }

    test('a published group is online, shown at once, by uid', () async {
      final localGroups = repository.groupTrades.length;
      final id = await PostingService().publish(
        const SkillPost(
          kind: ListingKind.group,
          category: 'Design',
          skills: ['Figma'],
          city: 'Riyadh',
          availability: 'Weekends',
        ),
      );

      // Shown straight away, before the server's copy arrives.
      expect(GroupTradeService().byId(id), isNotNull);
      await _settle();
      final group = GroupTradeService().byId(id)!;
      expect(repository.groupTrades, hasLength(localGroups));
      expect(GroupTradeService().isOnline(group), isTrue);
      expect(GroupTradeService().isOwner(group), isTrue);
      expect(group.title, 'Design skill circle');
      expect(groups.storedGroup(id)!['ownerId'], _maha);
      expect(_mentionsMe(groups.storedGroup(id)), isFalse);
      expect(GroupTradeService().all().first.id, id);
    });

    test('an invited member joins, and the change arrives live', () async {
      final id = await publish();
      final group = GroupTradeService().byId(id)!;
      await expectLater(
        GroupTradeService().inviteByUsername(group, 'nobody'),
        throwsA(GroupTradeException.unknownUsername),
      );
      await expectLater(
        GroupTradeService().inviteByUsername(group, 'maha_z'),
        throwsA(GroupTradeException.cannotInvite),
      );
      await GroupTradeService().inviteByUsername(group, '@sami_a');
      await _settle();
      expect(GroupTradeService().byId(id)!.invitedIds, [_sami]);

      await groups.respondToInvitation(_sami, id, accept: true);
      await _settle();
      final joined = GroupTradeService().byId(id)!;
      expect(joined.memberIds, [User.currentUserId, _sami]);
      expect(MemberService().nameOf(_sami), 'Sami Test');
    });

    test('a blocked member cannot be invited', () async {
      final id = await publish();
      repository.blockedMemberIds.add(_sami);
      await expectLater(
        GroupTradeService().inviteByUsername(
          GroupTradeService().byId(id)!,
          'sami_a',
        ),
        throwsA(isA<GroupTradeException>()),
      );
      expect(groups.storedGroup(id)!['invitedIds'], isEmpty);
    });

    test('an invitation to the current member can be accepted', () async {
      final id = await groups.create(_sami, _draft);
      await groups.invite(_sami, id, _maha);
      await _settle();
      final invited = GroupTradeService().byId(id)!;
      expect(GroupTradeService().isInvited(invited), isTrue);
      expect(GroupTradeService().all().map((g) => g.id), contains(id));

      await GroupTradeService().acceptInvitation(id);
      await _settle();
      expect(
        GroupTradeService().isMember(GroupTradeService().byId(id)!),
        isTrue,
      );
    });

    test('completion waits for every member, then each is rewarded', () async {
      final group = await groupWithSami();
      expect(GroupTradeService().canComplete(group), isTrue);
      expect(WalletService().balance, _welcome);

      expect(await GroupTradeService().complete(group.id), isFalse);
      await _settle();
      var shown = GroupTradeService().byId(group.id)!;
      expect(GroupTradeService().hasConfirmed(shown), isTrue);
      expect(GroupTradeService().canComplete(shown), isFalse);
      expect(GroupTradeService().waitingFor(shown), 1);
      expect(WalletService().balance, _welcome);

      expect(await groups.confirmCompletion(_sami, group.id), isTrue);
      await _settle();
      shown = GroupTradeService().byId(group.id)!;
      expect(shown.isCompleted, isTrue);
      // This member's app adds their own reward, once.
      expect(WalletService().balance, _welcome + _reward);
      final reward = WalletService().transactions().firstWhere(
        (item) => item.title == 'Group trade completed',
      );
      expect(reward.amount, _reward);
      expect(reward.subtitle, 'Design skill circle');
      expect(
        WalletDocument.balanceOf(trades.wallets.storedWallet(_sami)),
        isNull,
        reason: "Sami's own app claims Sami's reward",
      );
      await groups.claimReward(_sami, group.id);
      expect(
        WalletDocument.balanceOf(trades.wallets.storedWallet(_sami)),
        _welcome + _reward,
      );

      // More changes do not add it again.
      await publish();
      expect(WalletService().balance, _welcome + _reward);
      expect(
        repository.transactions.where(
          (t) => t.title == 'Group trade completed',
        ),
        isEmpty,
        reason: 'not also recorded on this device',
      );
    });

    test('the organizer removes a member; members leave', () async {
      final group = await groupWithSami();
      expect(GroupTradeService().canRemove(group, _sami), isTrue);
      expect(GroupTradeService().canRemove(group, User.currentUserId), isFalse);
      await GroupTradeService().removeMember(group.id, _sami);
      await _settle();
      expect(GroupTradeService().byId(group.id)!.memberIds, [
        User.currentUserId,
      ]);

      final other = await groups.create(_sami, _draft);
      await groups.invite(_sami, other, _maha);
      await groups.respondToInvitation(_maha, other, accept: true);
      await _settle();
      await GroupTradeService().leave(other);
      await _settle();
      expect(GroupTradeService().byId(other), isNull);
    });

    test(
      'deleting cancels the group for everyone, before it completes',
      () async {
        final group = await groupWithSami();
        expect(GroupTradeService().canDelete(group), isTrue);
        await GroupTradeService().deleteGroup(group.id);
        await _settle();
        expect(groups.storedGroup(group.id)!['status'], 'cancelled');
        expect(
          GroupTradeService().all().map((g) => g.id),
          isNot(contains(group.id)),
        );

        final done = await groupWithSami();
        await GroupTradeService().complete(done.id);
        await groups.confirmCompletion(_sami, done.id);
        await _settle();
        expect(
          GroupTradeService().canDelete(GroupTradeService().byId(done.id)!),
          isFalse,
        );
      },
    );

    test('the group chat is shared online with the members', () async {
      final group = await groupWithSami();
      final chatId = ChatService.groupConversationId(group.id);

      await ChatService().sendToGroup(group.id, 'Hello Sami');
      await groups.sendMessage(_sami, group.id, 'Hello Maha');
      await _settle();

      expect(groups.storedMessages(group.id).map((m) => m['senderId']), [
        _maha,
        _sami,
      ]);
      final messages = ChatService().messagesIn(chatId);
      expect(messages.map((m) => m.text), ['Hello Sami', 'Hello Maha']);
      expect(messages.first.isFromCurrentUser, isTrue);
      expect(messages.last.senderName, 'Sami Test');
      final conversation = ChatService().conversations().firstWhere(
        (item) => item.id == chatId,
      );
      expect(conversation.lastMessage, 'Hello Maha');
      expect(conversation.groupId, group.id);
    });

    test('a message that cannot be sent explains why', () async {
      final group = await groupWithSami();
      await groups.removeMember(_maha, group.id, _sami);
      await _settle();
      final other = await groups.create(_sami, _draft);
      await groups.invite(_sami, other, _maha);
      await _settle();
      await expectLater(
        ChatService().sendToGroup(other, 'Not a member yet'),
        throwsA(isA<ChatException>()),
      );
    });

    test(
      'device groups only invite demo members, online groups real ones',
      () async {
        await MemberService().loadMembers([_sami]);
        final local = GroupTradeService().byId('g-language')!;
        expect(GroupTradeService().isOnline(local), isFalse);
        expect(GroupTradeService().inviteCandidates(local, 'sami'), [
          isA<User>().having((m) => m.id, 'id', 'm-sami'),
        ]);
        final online = GroupTradeService().byId(await publish())!;
        expect(GroupTradeService().inviteCandidates(online, 'sami'), [
          isA<User>().having((m) => m.id, 'id', _sami),
        ]);
      },
    );

    test('device groups still complete as before', () async {
      final local = GroupTradeService().byId('g-language')!;
      final before = repository.transactions.length;
      expect(GroupTradeService().canComplete(local), isTrue);

      expect(await GroupTradeService().complete(local.id), isTrue);

      expect(GroupTradeService().byId(local.id)!.isCompleted, isTrue);
      expect(repository.transactions, hasLength(before + 1));
      expect(repository.transactions.last.amount, _reward);
    });

    test('another account sees only its own groups', () async {
      await groupWithSami();
      auth.currentUid = _lina;
      OnlineGroups.syncSession();
      await _settle();
      expect(
        GroupTradeService().all().where(GroupTradeService().isOnline),
        isEmpty,
      );
      auth.currentUid = _sami;
      OnlineGroups.syncSession();
      await _settle();
      expect(
        GroupTradeService().all().where(GroupTradeService().isOnline),
        hasLength(1),
      );
    });

    test('a loading error is reported and what loaded stays shown', () async {
      final id = await publish();
      groups.failStreams(GroupTradeException.offline);
      await _settle();
      expect(OnlineGroups.loadError, GroupTradeException.offline.message);
      expect(GroupTradeService().byId(id), isNotNull);

      OnlineGroups.retry();
      await _settle();
      expect(OnlineGroups.loadError, isNull);
      expect(OnlineGroups.isLoaded, isTrue);
    });

    test('offline, groups stay on this device as before', () async {
      OnlineGroups.repository = null;
      final before = repository.groupTrades.length;
      final id = await publish();
      expect(repository.groupTrades, hasLength(before + 1));
      expect(
        GroupTradeService().isOnline(GroupTradeService().byId(id)!),
        isFalse,
      );
    });

    testWidgets('the details screen shows who confirmed and why it waits', (
      tester,
    ) async {
      final group = await tester.runAsync(groupWithSami);
      await tester.pumpWidget(
        MaterialApp(home: GroupTradeDetailsScreen(groupId: group!.id)),
      );
      expect(find.text('Mark as complete'), findsOneWidget);
      expect(find.textContaining('0 of 2 so far'), findsOneWidget);
      expect(find.byTooltip('Remove from group'), findsOneWidget);

      // A failure is explained, and nothing changes.
      groups.failConfirmations = GroupTradeException.offline;
      await tester.tap(find.text('Mark as complete'));
      await tester.pumpAndSettle();
      expect(find.text('Check your internet connection.'), findsOneWidget);
      expect(find.text('Mark as complete'), findsOneWidget);
      expect(groups.storedGroup(group.id)!['completedBy'], isEmpty);

      groups.failConfirmations = null;
      await tester.tap(find.text('Mark as complete'));
      await tester.pumpAndSettle();
      // The server's change arrives on the stream subscribed in setUp.
      await tester.runAsync(_settle);
      await tester.pumpAndSettle();
      expect(find.text('Waiting for 1 member to confirm'), findsWidgets);
      expect(find.text('Mark as complete'), findsNothing);
      // The member list is further down the page.
      await tester.scrollUntilVisible(find.text('Organizer • Confirmed'), 200);
      expect(find.text('Organizer • Confirmed'), findsOneWidget);
    });
  });
}
