import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/login_page.dart';

/// O único `MaterialApp` do aplicativo.
///
/// A versão anterior tinha um segundo `MaterialApp` dentro da HomePage. Dois
/// `MaterialApp` aninhados criam dois `Navigator` e dois temas: as rotas
/// nomeadas do de fora deixavam de existir para as telas de dentro, e o tema
/// não descia. Aqui existe um só, e quem decide o que mostrar é o estado de
/// autenticação.
class AcqaApp extends StatelessWidget {
  const AcqaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ACQA — Gestão de Tarefas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

/// Decide entre login e app olhando o estado do Firebase Auth.
///
/// Antes, a navegação pós-login era um `Navigator.pushReplacement` dentro do
/// `catch`/`then` do `signIn`. Isso trazia dois problemas: usava o
/// `BuildContext` depois de um `await` sem checar `mounted`, e ao reabrir o
/// app o usuário caía na tela de login mesmo com sessão válida. Ouvir
/// `authStateChanges` resolve os dois: a sessão persistida é reconhecida na
/// abertura, e o logout volta para o login sozinho, de qualquer tela.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final User? usuario = snapshot.data;
        if (usuario == null) {
          return const LoginPage();
        }
        return HomePage(usuario: usuario);
      },
    );
  }
}
