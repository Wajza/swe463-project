import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/data/auth_repository.dart';
import 'package:souq_skills/data/chat_repository.dart';
import 'package:souq_skills/data/device_account_store.dart';
import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/models/conversation.dart';
import 'package:souq_skills/models/message.dart';
import 'package:souq_skills/models/notification.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/screens/chats/direct_chat_screen.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/chat_service.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/services/member_simulator.dart';
import 'package:souq_skills/services/proposal_service.dart';
import 'package:souq_skills/services/repository.dart';

import 'support/memory_data_source.dart';

const _maha = 'uid-maha';
const _sami = 'uid-sami';
const _lina = 'uid-lina';

/// A built-in demo member, who stays on this device.
const _demoSami = 'm-sami';
const _offline = ChatException('Check your internet connection.');

/// The offline sign-in with a Firebase-like uid that can change.
class _Auth extends DemoAuthRepository {
  _Auth() : super(isKnownPhone: AuthService().isKnownPhone);

  String? currentUid = _maha;

  @override
  String? get uid => currentUid;
}

/// Chats online; sending can be held or fail.
class _Chats extends DemoChatRepository {
  _Chats({super.hasBlocked});

  bool failSends = false;
  Completer<void>? holdSends;
  int sends = 0;

  @override
  Future<Message> sendMessage(String uid, ChatMessageDraft draft) async {
    sends++;
    final waitFor = holdSends;
    await waitFor?.future;
    if (failSends) throw _offline;
    return super.sendMessage(uid, draft);
  }
}

User _user(String first, String last, String username, String phone) => User(
  id: User.currentUserId,
  firstName: first,
  lastName: last,
  username: username,
  phone: phone,
  city: 'Jeddah',
  isVerified: true,
);

/// Lets listeners and background loads (such as member names) finish.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

ChatMessageDraft _to(String memberId, String text) =>
    ChatMessageDraft(memberId: memberId, text: text);

void main() {
  group('conversation ids and validation', () {
    test('both members get the same id, from their sorted uids', () {
      expect(
        ChatDocument.conversationIdFor(_maha, _sami),
        ChatDocument.conversationIdFor(_sami, _maha),
      );
      expect(
        ChatDocument.conversationIdFor(_sami, _maha),
        'dm_${_maha}_$_sami',
      );
      expect(ChatDocument.participantsOf(_sami, _maha), [_maha, _sami]);
    });

    test('nobody chats with themselves, the local id or unsafe ids', () {
      for (final (uid, other) in [
        (_maha, _maha),
        (_maha, User.currentUserId),
        (User.currentUserId, _maha),
        (_maha, 'bad id'),
        (_maha, 'a/b'),
        (_maha, ''),
      ]) {
        expect(
          () => ChatDocument.conversationIdFor(uid, other),
          throwsA(isA<ChatException>()),
          reason: '$uid and $other',
        );
      }
    });

    test('messages must have 1 to 1000 characters', () {
      expect(
        () => ChatDocument.validate(_maha, _to(_sami, '')),
        throwsA(ChatException.empty),
      );
      expect(
        () => ChatDocument.validate(_maha, _to(_sami, '  \n ')),
        throwsA(ChatException.empty),
      );
      expect(
        () => ChatDocument.validate(_maha, _to(_sami, 'x' * 1001)),
        throwsA(ChatException.tooLong),
      );
      ChatDocument.validate(_maha, _to(_sami, 'x' * 1000));
      // Surrounding spaces do not count, and are not stored.
      ChatDocument.validate(_maha, _to(_sami, '  ${'x' * 1000}  '));
      expect(
        ChatDocument.messageData(_maha, _to(_sami, '  Hi  '))['text'],
        'Hi',
      );
    });

    test('proposal and trade references must fit the kind of message', () {
      void refused(ChatMessageDraft draft) => expect(
        () => ChatDocument.validate(_maha, draft),
        throwsA(isA<ChatException>()),
      );
      refused(
        const ChatMessageDraft(
          memberId: _sami,
          text: 'Trade proposal',
          kind: ChatMessageKind.proposal,
        ),
      );
      refused(
        const ChatMessageDraft(memberId: _sami, text: 'Hi', proposalId: 'p1'),
      );
      refused(
        const ChatMessageDraft(memberId: _sami, text: 'Hi', tradeId: 't1'),
      );
      refused(
        const ChatMessageDraft(
          memberId: _sami,
          text: 'Trade proposal',
          kind: ChatMessageKind.proposal,
          proposalId: 'bad id',
        ),
      );
      ChatDocument.validate(
        _maha,
        const ChatMessageDraft(
          memberId: _sami,
          text: 'Trade proposal',
          kind: ChatMessageKind.proposal,
          proposalId: 'p1',
          tradeId: 't1',
        ),
      );
    });

    test('only uids are stored: no names or phone numbers', () {
      final draft = _to(_sami, 'Hello');
      expect(ChatDocument.messageData(_maha, draft).keys.toSet(), {
        'senderId',
        'text',
        'kind',
      });
      expect(ChatDocument.conversationData(_maha, draft, 'm1').keys.toSet(), {
        'kind',
        'participantIds',
        'lastMessage',
        'lastMessageId',
        'lastSenderId',
      });
    });
  });

  group('two members, one server', () {
    late DemoChatRepository chats;
    final blocks = <String, Set<String>>{};

    setUp(() {
      blocks.clear();
      chats = DemoChatRepository(
        isRealMember: (uid) => uid != 'uid-gone',
        hasBlocked: (uid, other) => blocks[uid]?.contains(other) ?? false,
      );
    });

    Future<List<ChatConversation>> conversationsOf(String uid) =>
        chats.watchConversations(uid).first;

    Future<List<Message>> messagesOf(String uid, String memberId) =>
        chats.watchMessages(uid, memberId).first;

    test('each member sees the same chat from their own side', () async {
      final sent = await chats.sendMessage(_maha, _to(_sami, 'Hello'));
      expect(sent.isFromCurrentUser, isTrue);
      expect(sent.conversationId, _sami);

      final [mine] = await conversationsOf(_maha);
      expect(mine.id, 'dm_${_maha}_$_sami');
      expect(mine.memberId, _sami);
      expect(mine.lastSenderId, User.currentUserId);
      expect(mine.isUnread, isFalse);

      final [theirs] = await conversationsOf(_sami);
      expect(theirs.id, mine.id);
      expect(theirs.memberId, _maha);
      expect(theirs.lastSenderId, _maha);
      expect(theirs.isUnread, isTrue);

      final [asSent] = await messagesOf(_maha, _sami);
      final [asReceived] = await messagesOf(_sami, _maha);
      expect(asSent.id, asReceived.id);
      expect(asSent.isFromCurrentUser, isTrue);
      expect(asReceived.isFromCurrentUser, isFalse);
      expect(asSent.conversationId, _sami);
      expect(asReceived.conversationId, _maha);
      expect(asReceived.senderName, isEmpty);
      // The local id is never stored.
      expect(
        chats.storedMessages(mine.id).single['senderId'],
        isNot(User.currentUserId),
      );
    });

    test('messages are oldest first, chats newest first', () async {
      await chats.sendMessage(_maha, _to(_sami, 'One'));
      await chats.sendMessage(_maha, _to(_lina, 'Two'));
      await chats.sendMessage(_sami, _to(_maha, 'Three'));

      expect(
        [for (final item in await messagesOf(_maha, _sami)) item.text],
        ['One', 'Three'],
      );
      expect(
        [for (final item in await conversationsOf(_maha)) item.memberId],
        [_sami, _lina],
      );
      expect((await conversationsOf(_maha)).first.lastMessage, 'Three');
    });

    test('reading changes only the reader\'s own read time', () async {
      await chats.sendMessage(_maha, _to(_sami, 'Hello'));
      final before = chats.storedConversation('dm_${_maha}_$_sami')!;

      await chats.markConversationRead(_sami, _maha);

      expect((await conversationsOf(_sami)).single.isUnread, isFalse);
      final after = chats.storedConversation('dm_${_maha}_$_sami')!;
      expect(after['lastMessage'], before['lastMessage']);
      expect(
        (after['lastReadAt'] as Map)[_maha],
        (before['lastReadAt'] as Map)[_maha],
      );
      // Nothing to read before the first message.
      await chats.markConversationRead(_lina, _maha);
      expect(chats.storedConversation('dm_${_lina}_$_maha'), isNull);
    });

    test('blocks, either way, and missing accounts stop messages', () async {
      blocks[_sami] = {_maha};
      await expectLater(
        chats.sendMessage(_maha, _to(_sami, 'Hi')),
        throwsA(ChatException.notSent),
      );
      await expectLater(
        chats.sendMessage(_sami, _to(_maha, 'Hi')),
        throwsA(ChatException.notSent),
      );
      await expectLater(
        chats.sendMessage(_maha, _to('uid-gone', 'Hi')),
        throwsA(ChatException.notSent),
      );
      expect(await conversationsOf(_maha), isEmpty);
    });

    test('a chat that does not exist yet cannot be listened to', () async {
      await expectLater(
        messagesOf(_maha, _sami),
        throwsA(isA<ChatException>()),
      );
    });
  });

  group('chats in the app', () {
    final repository = Repository.instance;
    final originalAuth = AuthService.repository;
    final blocks = <String, Set<String>>{};
    late _Auth auth;
    late _Chats chats;
    final chatId = 'dm_${_maha}_$_sami';

    setUp(() async {
      repository
        ..dataSource = MemoryDataSource()
        ..reset();
      // The sample notifications, so only new ones are counted.
      repository.notifications.clear();
      auth = _Auth();
      AuthService.repository = auth;
      AuthService.deviceAccount = MemoryDeviceAccountStore(_maha);
      final profiles = DemoProfileRepository();
      await profiles.saveProfile(
        _maha,
        _user('Maha', 'Alzahrani', 'maha_z', '501234567'),
      );
      await profiles.saveProfile(
        _sami,
        _user('Sami', 'Alharbi', 'sami_a', '512345678'),
      );
      await profiles.saveProfile(
        _lina,
        _user('Lina', 'Saleh', 'lina_s', '523456789'),
      );
      AuthService.profiles = profiles;
      blocks.clear();
      chats = _Chats(
        hasBlocked: (uid, other) => blocks[uid]?.contains(other) ?? false,
      );
      ChatService.repository = chats;
    });

    tearDown(() {
      ChatService.repository = null;
      AuthService.profiles = null;
      AuthService.deviceAccount = null;
      AuthService.repository = originalAuth;
    });

    /// Widget tests pass [tester]: their clock only moves when pumped.
    Future<void> signIn([WidgetTester? tester]) async {
      AuthService().signIn();
      await (tester == null ? _settle() : tester.pump());
    }

    List<AppNotification> messageNotifications() => [
      for (final item in repository.notifications)
        if (item.type == NotificationType.message) item,
    ];

    Conversation? chatWith(String memberId) {
      for (final item in ChatService().conversations()) {
        if (item.memberId == memberId) return item;
      }
      return null;
    }

    test(
      'sending to a real member saves it online, as theirs to read',
      () async {
        await signIn();
        final onDevice = repository.messages.length;

        await ChatService().sendToMember(_sami, 'Hello');

        final [stored] = chats.storedMessages(chatId);
        expect(stored['senderId'], _maha);
        expect(stored['text'], 'Hello');
        expect(repository.messages, hasLength(onDevice));
        final chat = chatWith(_sami)!;
        expect(chat.lastMessage, 'Hello');
        expect(chat.unreadCount, 0);

        ChatService().open(_sami);

        await _settle();
        final [shown] = ChatService().messagesIn(_sami);
        expect(shown.isFromCurrentUser, isTrue);
        expect(shown.isRead, isTrue);
        ChatService().close(_sami);
      },
    );

    test('a reply arrives live: unread, named, and notified once', () async {
      await signIn();
      // The sample demo chats have unread messages of their own.
      final unreadBefore = ChatService().unreadConversationCount();
      await ChatService().sendToMember(_sami, 'Hello');

      // Sami answers from their own device.
      await chats.sendMessage(_sami, _to(_maha, 'Hi Maha'));
      await _settle();

      final chat = chatWith(_sami)!;
      expect(chat.title, 'Sami Alharbi');
      expect(chat.lastMessage, 'Hi Maha');
      expect(chat.unreadCount, 1);
      expect(ChatService().unreadConversationCount(), unreadBefore + 1);
      final [notification] = messageNotifications();
      expect(notification.title, 'New message from Sami Alharbi');
      expect(notification.routeArgument, _sami);

      ChatService().open(_sami);

      await _settle();
      final messages = ChatService().messagesIn(_sami);
      expect([for (final item in messages) item.text], ['Hello', 'Hi Maha']);
      expect(messages.last.isFromCurrentUser, isFalse);
      expect(messages.last.isRead, isFalse);
      expect(messages.last.senderName, 'Sami Alharbi');

      ChatService().markRead(_sami);
      await _settle();
      expect(
        ChatService().messagesIn(_sami).every((item) => item.isRead),
        isTrue,
      );
      expect(chatWith(_sami)!.unreadCount, 0);
      expect(ChatService().unreadConversationCount(), unreadBefore);
      // Seen from Sami's side, Maha's read time moved on, nothing else.
      final [asSami] = await chats.watchConversations(_sami).first;
      expect(asSami.lastSenderId, User.currentUserId);
      expect(messageNotifications(), hasLength(1));
      ChatService().close(_sami);
    });

    test('messages from before signing in are unread, not notified', () async {
      await chats.sendMessage(_sami, _to(_maha, 'Sent while you were away'));

      await signIn();

      expect(chatWith(_sami)!.unreadCount, 1);
      expect(messageNotifications(), isEmpty);
    });

    test('no notification for a chat that is open', () async {
      await signIn();
      await ChatService().sendToMember(_sami, 'Hello');
      ChatService().open(_sami);
      await _settle();

      await chats.sendMessage(_sami, _to(_maha, 'Hi'));
      await _settle();

      expect(messageNotifications(), isEmpty);
      expect(ChatService().messagesIn(_sami).last.text, 'Hi');
      ChatService().close(_sami);
    });

    test(
      'a chat with nothing in it yet is empty, not loading forever',
      () async {
        await signIn();
        ChatService().open(_sami);
        await _settle();

        expect(ChatService().messagesIn(_sami), isEmpty);
        expect(chatWith(_sami), isNull);
        expect(ChatService().loadStateOf(_sami).status, ChatLoadStatus.loaded);
        expect(
          ChatService().loadStateOf(ChatService.conversationList).status,
          ChatLoadStatus.loaded,
        );
        // The first message starts the chat, and listening to it.
        await ChatService().sendToMember(_sami, 'Hello');
        await _settle();
        expect(ChatService().loadStateOf(_sami).status, ChatLoadStatus.loaded);
        expect(ChatService().messagesIn(_sami), hasLength(1));
        ChatService().close(_sami);
      },
    );

    test(
      'trade notes kept on this device show in order in the same chat',
      () async {
        await signIn();
        ChatService().open(_sami);
        await _settle();
        // Apart in time: notes use this device's clock, messages the
        // server's, and a tie would be ordered by id.
        const apart = Duration(milliseconds: 20);
        await ChatService().sendToMember(_sami, 'First');
        await Future<void>.delayed(apart);
        ChatService().postSystem(_sami, 'Session scheduled.');
        await Future<void>.delayed(apart);
        await chats.sendMessage(_sami, _to(_maha, 'Third'));
        await _settle();

        expect(
          [for (final item in ChatService().messagesIn(_sami)) item.text],
          ['First', 'Session scheduled.', 'Third'],
        );
        ChatService().close(_sami);
      },
    );

    testWidgets('real members never get simulated replies or acceptances', (
      tester,
    ) async {
      await signIn(tester);
      await ChatService().sendToMember(_sami, 'Hello');
      ProposalService().send(
        const TradeProposal(
          senderId: User.currentUserId,
          receiverId: _sami,
          offeredSkill: 'Baking',
          requestedSkill: 'Flutter',
        ),
      );
      final proposal = repository.proposals.last;

      await tester.pump(
        MemberSimulator.proposalReplyDelay + const Duration(seconds: 5),
      );

      expect(chats.storedMessages(chatId), hasLength(1));
      expect(
        ChatService().messagesIn(_sami).where((m) => !m.isFromCurrentUser),
        isEmpty,
      );
      expect(ProposalService().byId(proposal.id)!.isPending, isTrue);
      expect(messageNotifications(), isEmpty);
    });

    testWidgets('demo members still reply on this device', (tester) async {
      await signIn(tester);
      await ChatService().sendToMember(_demoSami, 'Hello');
      expect(chats.sends, 0);

      await tester.pump(
        MemberSimulator.replyDelay + const Duration(seconds: 1),
      );

      final messages = ChatService().messagesIn(_demoSami);
      expect(messages, hasLength(greaterThan(1)));
      expect(messages.last.isFromCurrentUser, isFalse);
      expect(messageNotifications(), hasLength(1));
    });

    test('signing out stops listening and hides online chats', () async {
      await signIn();
      await ChatService().sendToMember(_sami, 'Hello');
      ChatService().open(_sami);
      await _settle();
      expect(chats.activeWatchers, 2);

      await AuthService().signOut();

      expect(chats.activeWatchers, 0);
      expect(chatWith(_sami), isNull);
      expect(ChatService().messagesIn(_sami), isEmpty);
      await chats.sendMessage(_sami, _to(_maha, 'Are you there?'));
      await _settle();
      expect(chatWith(_sami), isNull);
      expect(messageNotifications(), isEmpty);
      ChatService().close(_sami);
    });

    test('another account never sees the previous account\'s chats', () async {
      await signIn();
      await ChatService().sendToMember(_sami, 'Hello from Maha');
      await AuthService().signOut();

      auth.currentUid = _lina;
      await signIn();

      expect(chatWith(_sami), isNull);
      expect(chats.activeWatchers, 1);
      await chats.sendMessage(_sami, _to(_lina, 'Hello Lina'));
      await _settle();
      expect(chatWith(_sami)!.lastMessage, 'Hello Lina');
      ChatService().open(_sami);
      await _settle();
      expect(
        [for (final item in ChatService().messagesIn(_sami)) item.text],
        ['Hello Lina'],
      );
      ChatService().close(_sami);
    });

    test(
      'the account changing without signing out restarts listening',
      () async {
        await signIn();
        await ChatService().sendToMember(_sami, 'Hello from Maha');

        auth.currentUid = _lina;
        ChatService.syncSession();
        await _settle();

        expect(chatWith(_sami), isNull);
        expect(chats.activeWatchers, 1);
      },
    );

    test('a send that fails throws and shows nothing', () async {
      await signIn();
      chats.failSends = true;

      await expectLater(
        ChatService().sendToMember(_sami, 'Hello'),
        throwsA(_offline),
      );

      expect(chats.storedConversation(chatId), isNull);
      expect(chatWith(_sami), isNull);
    });

    test('invalid messages are refused before anything is stored', () async {
      await signIn();

      await expectLater(
        ChatService().sendToMember(_sami, '   '),
        throwsA(ChatException.empty),
      );
      await expectLater(
        ChatService().sendToMember(_sami, 'x' * 1001),
        throwsA(ChatException.tooLong),
      );
      expect(chats.storedConversation(chatId), isNull);
    });

    test('the same message tapped twice while sending is sent once', () async {
      await signIn();
      chats.holdSends = Completer<void>();

      final first = ChatService().sendToMember(_sami, 'Hello');
      final second = ChatService().sendToMember(_sami, 'Hello');
      final other = ChatService().sendToMember(_sami, 'Something else');
      chats.holdSends!.complete();
      await Future.wait([first, second, other]);

      expect(chats.sends, 2);
      expect(
        [for (final item in chats.storedMessages(chatId)) item['text']],
        ['Hello', 'Something else'],
      );
      // Once sent, the same text can be sent again.
      await ChatService().sendToMember(_sami, 'Hello');
      expect(chats.storedMessages(chatId), hasLength(3));
    });

    test('blocked members cannot be messaged, either way', () async {
      await signIn();
      repository.blockedMemberIds.add(_sami);
      await expectLater(
        ChatService().sendToMember(_sami, 'Hello'),
        throwsA(isA<ChatException>()),
      );
      expect(chats.sends, 0);

      repository.blockedMemberIds.remove(_sami);
      blocks[_sami] = {_maha};
      await expectLater(
        ChatService().sendToMember(_sami, 'Hello'),
        throwsA(ChatException.notSent),
      );
      expect(chats.storedConversation(chatId), isNull);
    });

    test('a chat of a member you blocked is hidden', () async {
      await chats.sendMessage(_sami, _to(_maha, 'Hello'));
      await signIn();
      expect(chatWith(_sami)!.unreadCount, 1);
      final unread = ChatService().unreadConversationCount();

      repository.blockedMemberIds.add(_sami);

      expect(chatWith(_sami), isNull);
      expect(ChatService().unreadConversationCount(), unread - 1);
    });

    test('a listener that fails is reported and can be retried', () async {
      await signIn();

      chats.failStreams(_offline);
      await _settle();
      final failed = ChatService().loadStateOf(ChatService.conversationList);
      expect(failed.isFailed, isTrue);
      expect(failed.error, _offline.message);

      ChatService().retry(ChatService.conversationList);
      await _settle();
      expect(
        ChatService().loadStateOf(ChatService.conversationList).status,
        ChatLoadStatus.loaded,
      );
    });

    test('offline, every chat stays on this device as before', () async {
      ChatService.repository = null;
      await signIn();

      await ChatService().sendToMember(_sami, 'Hello');

      expect(chats.sends, 0);
      expect(repository.messages.last.text, 'Hello');
      expect(ChatService.isOnlineChat(_sami), isFalse);
    });

    group('on the chat screen', () {
      Future<void> openChat(WidgetTester tester) async {
        await signIn(tester);
        await MemberService().loadMembers([_sami]);
        await tester.pumpWidget(
          const MaterialApp(home: DirectChatScreen(memberId: _sami)),
        );
        await tester.pumpAndSettle();
      }

      Future<void> send(WidgetTester tester, String text) async {
        await tester.enterText(find.byType(TextField), text);
        await tester.tap(find.byTooltip('Send'));
        await tester.pumpAndSettle();
      }

      String fieldText(WidgetTester tester) =>
          tester.widget<TextField>(find.byType(TextField)).controller!.text;

      testWidgets('a sent message shows as mine and the field clears', (
        tester,
      ) async {
        await openChat(tester);

        await send(tester, 'Hello Sami');

        expect(find.text('Hello Sami'), findsOneWidget);
        expect(fieldText(tester), isEmpty);
        expect(chats.storedMessages(chatId), hasLength(1));

        await tester.runAsync(
          () => chats.sendMessage(_sami, _to(_maha, 'Hi Maha')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Hi Maha'), findsOneWidget);
        // Read while on screen.
        final [asSami] = await chats.watchConversations(_sami).first;
        expect(asSami.memberId, _maha);
        expect(chatWith(_sami)!.unreadCount, 0);

        await tester.pumpWidget(const SizedBox());
        expect(chats.activeWatchers, 1);
      });

      testWidgets('a message that fails is kept, with the reason', (
        tester,
      ) async {
        await openChat(tester);
        chats.failSends = true;

        await send(tester, 'Hello Sami');

        expect(find.text(_offline.message), findsOneWidget);
        expect(fieldText(tester), 'Hello Sami');
        expect(chats.storedConversation(chatId), isNull);
      });
    });
  });
}
