import 'package:cloud_firestore/cloud_firestore.dart';

class Prontuario {
  String? id;
  final String paciente;
  final String descricao;
  final DateTime data;

  Prontuario({
    this.id,
    required this.paciente,
    required this.descricao,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'paciente': paciente,
      'paciente_lower': paciente.toLowerCase(),
      'descricao': descricao,
      // Salva como Timestamp para melhor ordenação/queries no servidor
      'data': Timestamp.fromDate(data),
    };
  }

  factory Prontuario.fromMap(String id, Map<String, dynamic> map) {
    // data pode vir como String (legado) ou como Timestamp (novo formato)
    final rawData = map['data'];
    final DateTime parsedDate;
    if (rawData is Timestamp) {
      parsedDate = rawData.toDate();
    } else if (rawData is String) {
      parsedDate = DateTime.tryParse(rawData) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }
    return Prontuario(
      id: id,
      paciente: map['paciente'],
      descricao: map['descricao'],
      data: parsedDate,
    );
  }
}
