import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futeboladas/services/attendance_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late AttendanceService presencaService;

  final mockUser = MockUser(
    uid: 'tester',
    email: 'tester@futebol.com',
    displayName: 'Tester',
  );

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
    presencaService = AttendanceService(
      firestore: fakeFirestore,
      auth: mockAuth,
    );
  });

  group('AttendanceService Tests', () {
    test('should mark presence successfully', () async {
      const gameId = 'jogo_1';

      await presencaService.markAttendance(gameId, true);

      final doc = await fakeFirestore
          .collection('games')
          .doc(gameId)
          .collection('attendances')
          .doc(mockUser.uid)
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()!['vai'], isTrue);
      expect(doc.data()!['uid'], mockUser.uid);
    });

    test('countConfirmados should return correct amount', () async {
      const gameId = 'jogo_2';

      // Add two confirmed presences manually to fake firestore
      await fakeFirestore
          .collection('games')
          .doc(gameId)
          .collection('attendances')
          .doc('user1')
          .set({'vai': true});

      await fakeFirestore
          .collection('games')
          .doc(gameId)
          .collection('attendances')
          .doc('user2')
          .set({'vai': true});

      await fakeFirestore
          .collection('games')
          .doc(gameId)
          .collection('attendances')
          .doc('user3')
          .set({'vai': false});

      final count = await presencaService.countConfirmados(gameId).first;
      expect(count, 2);
    });
  });
}
