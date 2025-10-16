import 'package:flutter/material.dart';
import '../models/prontuario.dart';
import '../services/firestore_service.dart';
import 'package:prontuario_app/screens/formulario_prontuario_screen.dart';
import 'package:intl/intl.dart';

class ProntuarioListScreen extends StatefulWidget {
  const ProntuarioListScreen({super.key});

  @override
  State<ProntuarioListScreen> createState() => _ProntuarioListScreenState();
}

class _ProntuarioListScreenState extends State<ProntuarioListScreen> {
  final FirestoreService firestoreService = FirestoreService();
  String _query = '';
  DateTime? _inicio;
  DateTime? _fim;

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: (_inicio != null && _fim != null)
          ? DateTimeRange(start: _inicio!, end: _fim!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _inicio = picked.start;
        _fim = picked.end.add(const Duration(days: 1)); // incluir fim do dia
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prontuários'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickDateRange,
            tooltip: 'Filtrar por data',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Filtrar por paciente...',
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Prontuario>>(
              stream: () {
                final hasName = _query.isNotEmpty;
                final hasDates = _inicio != null && _fim != null;
                if (hasName && !hasDates) {
                  return firestoreService.getProntuariosPorPacientePrefixo(
                    _query,
                  );
                } else if (!hasName && hasDates) {
                  return firestoreService.getProntuariosPorData(
                    _inicio!,
                    _fim!,
                  );
                } else if (hasName && hasDates) {
                  // Combinação: usa filtro por data no servidor e aplica nome no cliente
                  return firestoreService.getProntuariosPorData(
                    _inicio!,
                    _fim!,
                  );
                }
                return firestoreService.getProntuarios();
              }(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var prontuarios = snapshot.data!;
                // Só aplica filtro de nome no cliente quando ambos filtros estão ativos
                if (_query.isNotEmpty && _inicio != null && _fim != null) {
                  prontuarios = prontuarios
                      .where((p) => p.paciente.toLowerCase().contains(_query))
                      .toList();
                }

                if (prontuarios.isEmpty) {
                  return const Center(child: Text('Nenhum prontuário'));
                }

                final df = DateFormat('dd/MM/yyyy HH:mm');
                return ListView.builder(
                  itemCount: prontuarios.length,
                  itemBuilder: (context, index) {
                    final p = prontuarios[index];
                    final formatted = df.format(p.data);
                    return ListTile(
                      title: Text(p.paciente),
                      subtitle: Text('${p.descricao}\n$formatted'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Editar',
                            icon: const Icon(Icons.edit),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FormularioProntuarioScreen(existente: p),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Excluir',
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                firestoreService.deletarProntuario(p.id!),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FormularioProntuarioScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
