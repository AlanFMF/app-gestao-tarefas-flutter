import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/mensagens_auth.dart';
import 'forget_password_page.dart';
import 'register_page.dart';

/// Tela de login.
///
/// Virou `StatefulWidget` por um motivo concreto: os `TextEditingController`
/// precisam ser descartados no `dispose`. Num `StatelessWidget` eles eram
/// recriados a cada rebuild e nunca liberados.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _senha = TextEditingController();

  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _senha.text,
      );
      // Não navego daqui: o AuthGate escuta authStateChanges e troca a tela
      // sozinho. Isso evita usar o BuildContext depois do await.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _erro = mensagemDeErroAuth(e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível entrar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _abrir(Widget pagina) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (BuildContext context) => pagina),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Entrar'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'ACQA',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gestão de tarefas',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const <String>[AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: validarEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _senha,
                      obscureText: true,
                      autofillHints: const <String>[AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      onFieldSubmitted: (_) => _entrar(),
                      validator: (String? v) =>
                          (v == null || v.isEmpty) ? 'Informe a senha.' : null,
                    ),
                    if (_erro != null) ...<Widget>[
                      const SizedBox(height: 16),
                      Text(
                        _erro!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _carregando ? null : _entrar,
                      child: _carregando
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _carregando ? null : () => _abrir(const RegisterPage()),
                      child: const Text('Não tem conta? Cadastre-se'),
                    ),
                    TextButton(
                      onPressed:
                          _carregando ? null : () => _abrir(const ForgetPasswordPage()),
                      child: const Text('Esqueci minha senha'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
