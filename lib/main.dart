import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/prontuario_list_screen.dart'; // Tela principal com lista de prontuários
import 'firebase_options.dart'; //
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/messaging_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized in background isolates
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Só inicializa se ainda não existir
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Registra o handler para mensagens em segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } else {
    Firebase.app(); // pega a instância já existente
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prontuário Eletrônico',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate({Key? key}) : super(key: key);

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    // Solicitar permissão FCM (Android 13+/iOS) e logar token
    () async {
      try {
        await FirebaseMessaging.instance.requestPermission();
        await FirebaseMessaging.instance.getToken();
      } catch (_) {}
    }();

    // Mensagens recebidas em primeiro plano
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notification.title ?? 'Nova notificação')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen();

        // Inicializa FCM para o usuário autenticado (salvar token e tópicos)
        MessagingService.initForUser(user);

        // Ao abrir a notificação, poderíamos navegar para uma tela específica (ex.: detalhe)
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          // Ex.: navegar para a lista (já é a tela atual) ou no futuro para um detalhe
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Prontuário Eletrônico'),
            actions: [
              IconButton(
                onPressed: () => _auth.signOut(),
                icon: const Icon(Icons.logout),
                tooltip: 'Sair',
              ),
            ],
          ),
          body: ProntuarioListScreen(),
        );
      },
    );
  }
}
