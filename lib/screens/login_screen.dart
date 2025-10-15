import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      final msg = _friendlyAuthError(e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      final msg = _friendlyAuthError(e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyAuthError(Object e) {
    final text = e.toString();
    if (text.contains('invalid-credential') ||
        text.contains('INVALID_LOGIN_CREDENTIALS')) {
      return 'Credenciais inválidas. Verifique email e senha.';
    }
    if (text.contains('email-already-in-use')) {
      return 'Este email já está em uso.';
    }
    if (text.contains('weak-password')) {
      return 'A senha é muito fraca.';
    }
    if (text.contains('user-not-found')) {
      return 'Usuário não encontrado.';
    }
    if (text.contains('wrong-password')) {
      return 'Senha incorreta.';
    }
    return 'Ocorreu um erro. Tente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe o email';
                  final email = v.trim();
                  final ok = RegExp(r'^.+@.+\..+$').hasMatch(email);
                  return ok ? null : 'Email inválido';
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe a senha';
                  if (v.length < 6) {
                    return 'A senha deve ter pelo menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_loading)
                const CircularProgressIndicator()
              else ...[
                ElevatedButton(onPressed: _signIn, child: const Text('Entrar')),
                TextButton(
                  onPressed: _signUp,
                  child: const Text('Criar conta'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
