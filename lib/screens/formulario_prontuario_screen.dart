import 'package:flutter/material.dart';
import '../models/prontuario.dart';
import '../services/firestore_service.dart';

class FormularioProntuarioScreen extends StatefulWidget {
  final Prontuario? existente;
  const FormularioProntuarioScreen({super.key, this.existente});

  @override
  _FormularioProntuarioScreenState createState() =>
      _FormularioProntuarioScreenState();
}

class _FormularioProntuarioScreenState
    extends State<FormularioProntuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pacienteController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _service = FirestoreService();
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existente;
    if (p != null) {
      _pacienteController.text = p.paciente;
      _descricaoController.text = p.descricao;
    }
  }

  Future<void> _salvar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _salvando = true);
      try {
        if (widget.existente == null) {
          final prontuario = Prontuario(
            paciente: _pacienteController.text,
            descricao: _descricaoController.text,
            data: DateTime.now(),
          );
          await _service.adicionarProntuario(prontuario);
        } else {
          final atualizado = Prontuario(
            id: widget.existente!.id,
            paciente: _pacienteController.text,
            descricao: _descricaoController.text,
            data: widget.existente!.data,
          );
          await _service.atualizarProntuario(atualizado);
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
        }
      } finally {
        if (mounted) setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Novo Prontuário')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _pacienteController,
                decoration: InputDecoration(labelText: 'Nome do Paciente'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome do paciente';
                  }
                  if (value.trim().length < 3) return 'Nome muito curto';
                  return null;
                },
              ),
              TextFormField(
                controller: _descricaoController,
                decoration: InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a descrição';
                  }
                  if (value.trim().length < 5) return 'Descrição muito curta';
                  return null;
                },
              ),
              SizedBox(height: 20),
              _salvando
                  ? const CircularProgressIndicator()
                  : ElevatedButton(onPressed: _salvar, child: Text('Salvar')),
            ],
          ),
        ),
      ),
    );
  }
}
