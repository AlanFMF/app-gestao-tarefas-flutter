import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/mensagens_auth.dart';

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();

  bool _carregando = false;
  bool _enviado = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _email.text.trim(),
      );
      if (!mounted) return;
      setState(() => _enviado = true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // 'user-not-found' aqui vira sucesso de propósito: responder de forma
      // diferente para e-mail existente e inexistente entrega quem tem conta.
      if (e.code == 'user-not-found') {
        setState(() => _enviado = true);
      } else {
        setState(() => _erro = mensagemDeErroAuth(e));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível enviar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _enviado
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Icon(Icons.mark_email_read_outlined, size: 56),
                        const SizedBox(height: 16),
                        const Text(
                          'Se existir uma conta com esse e-mail, o link de '
                          'redefinição já está a caminho. Confira também a '
                          'caixa de spam.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Voltar ao login'),
                        ),
                      ],
                    )
                  : Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const Text(
                            'Informe o e-mail da conta. Enviaremos um link '
                            'para você criar uma nova senha.',
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                            onFieldSubmitted: (_) => _enviar(),
                            validator: validarEmail,
                          ),
                          if (_erro != null) ...<Widget>[
                            const SizedBox(height: 16),
                            Text(
                              _erro!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _carregando ? null : _enviar,
                            child: _carregando
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Enviar link'),
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
