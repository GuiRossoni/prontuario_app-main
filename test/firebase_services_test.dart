import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import 'package:prontuario_app/services/firestore_service.dart';
import 'package:prontuario_app/services/auth_service.dart';
import 'package:prontuario_app/models/prontuario.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService (mocked)', () {
    test('sign up -> sign out -> sign in', () async {
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final authService = AuthService(auth: mockAuth);

      final email = 'user_${DateTime.now().microsecondsSinceEpoch}@example.com';
      const password = 'Test@123456';

      final cred = await authService.signUp(email, password);
      expect(cred.user, isNotNull);
      expect(mockAuth.currentUser?.email, email);

      await authService.signOut();
      expect(mockAuth.currentUser, isNull);

      await authService.signIn(email, password);
      expect(mockAuth.currentUser?.email, email);
    });
  });

  group('FirestoreService (fake)', () {
    test('CRUD Prontuario using FakeFirebaseFirestore', () async {
      final fake = FakeFirebaseFirestore();
      final service = FirestoreService(firestore: fake);

      // Create
      final novo = Prontuario(
        paciente: 'Paciente Teste',
        descricao: 'Descricao de teste',
        data: DateTime.now(),
      );
      await service.adicionarProntuario(novo);

      // Read
      var lista = await service.getProntuarios().first;
      expect(lista, isNotEmpty);
      final first = lista.first;

      // Update
      final atualizado = Prontuario(
        id: first.id,
        paciente: 'Paciente Atualizado',
        descricao: first.descricao,
        data: first.data,
      );
      await service.atualizarProntuario(atualizado);

      lista = await service.getProntuarios().first;
      expect(
        lista.any(
          (p) => p.id == first.id && p.paciente == 'Paciente Atualizado',
        ),
        isTrue,
      );

      // Delete
      await service.deletarProntuario(first.id!);
      lista = await service.getProntuarios().first;
      expect(lista.any((p) => p.id == first.id), isFalse);
    });

    test('prefix search and date filter behave', () async {
      final fake = FakeFirebaseFirestore();
      final service = FirestoreService(firestore: fake);

      final now = DateTime.now();
      await service.adicionarProntuario(
        Prontuario(
          paciente: 'Alice',
          descricao: 'A',
          data: now.subtract(const Duration(days: 2)),
        ),
      );
      await service.adicionarProntuario(
        Prontuario(paciente: 'Alberto', descricao: 'B', data: now),
      );
      await service.adicionarProntuario(
        Prontuario(paciente: 'Bruno', descricao: 'C', data: now),
      );

      final prefix = await service.getProntuariosPorPacientePrefixo('al').first;
      expect(
        prefix.every((p) => p.paciente.toLowerCase().startsWith('al')),
        isTrue,
      );

      final range = await service
          .getProntuariosPorData(
            now.subtract(const Duration(days: 1)),
            now.add(const Duration(days: 1)),
          )
          .first;
      expect(range.any((p) => p.paciente == 'Alice'), isFalse);
      expect(range.any((p) => p.paciente == 'Alberto'), isTrue);
    });
  });
}
