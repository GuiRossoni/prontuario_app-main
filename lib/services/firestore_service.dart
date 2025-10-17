import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prontuario.dart';

class FirestoreService {
  final FirebaseFirestore _db;
  late final CollectionReference prontuariosCollection;

  FirestoreService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance {
    prontuariosCollection = _db.collection('prontuarios');
  }

  Future<void> adicionarProntuario(Prontuario prontuario) async {
    await prontuariosCollection.add(prontuario.toMap());
  }

  Future<void> deletarProntuario(String id) async {
    await prontuariosCollection.doc(id).delete();
  }

  Future<void> atualizarProntuario(Prontuario prontuario) async {
    if (prontuario.id == null) return;
    await prontuariosCollection.doc(prontuario.id).update(prontuario.toMap());
  }

  Stream<List<Prontuario>> getProntuarios() {
    // Ordena por data (Timestamp) descendente
    return prontuariosCollection
        .orderBy('data', descending: true)
        .snapshots()
        .map(_toProntuarios);
  }

  Stream<List<Prontuario>> getProntuariosPorPacientePrefixo(String prefixo) {
    if (prefixo.isEmpty) return getProntuarios();
    final start = prefixo.toLowerCase();
    final end = '$start\uf8ff';
    // orderBy deve vir antes de startAt/endAt na API
    final query = prontuariosCollection
        .orderBy('paciente_lower')
        // .orderBy('data', descending: true)
        .startAt([start])
        .endAt([end]);
    return query.snapshots().map(_toProntuarios);
  }

  Stream<List<Prontuario>> getProntuariosPorData(
    DateTime inicio,
    DateTime fim,
  ) {
    final query = prontuariosCollection
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('data', isLessThan: Timestamp.fromDate(fim))
        .orderBy('data', descending: true);
    return query.snapshots().map(_toProntuarios);
  }

  Stream<List<Prontuario>> getProntuariosPorPacienteEData(
    String prefixo,
    DateTime inicio,
    DateTime fim,
  ) {
    // Para combinar where de prefixo + intervalo de data, precisamos usar índices compostos no Firestore.
    // Esta query exige índice: (paciente_lower asc, data desc) com filtros de data.
    final start = prefixo.toLowerCase();
    final end = '$start\uf8ff';
    final query = prontuariosCollection
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('data', isLessThan: Timestamp.fromDate(fim))
        .orderBy('paciente_lower')
        .startAt([start])
        .endAt([end])
        .orderBy('data', descending: true);
    return query.snapshots().map(_toProntuarios);
  }

  List<Prontuario> _toProntuarios(QuerySnapshot snapshot) => snapshot.docs
      .map(
        (doc) => Prontuario.fromMap(doc.id, doc.data() as Map<String, dynamic>),
      )
      .toList();
}
