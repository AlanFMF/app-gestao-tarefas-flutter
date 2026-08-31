import 'package:firebase_auth/firebase_auth.dart';

/// Traduz o código do FirebaseAuthException para uma frase que ajuda.
///
/// A versão anterior mostrava sempre "Verifique seu email e senha e tente
/// novamente", inclusive quando o problema era falta de internet ou e-mail já
/// cadastrado. Um erro que sempre diz a mesma coisa não é tratamento de erro:
/// é um `catch` vazio com aparência de cuidado.
String mensagemDeErroAuth(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'E-mail inválido.';
    case 'user-disabled':
      return 'Esta conta está desativada.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      // Propositalmente igual para os três: dizer "esse e-mail não existe"
      // permite descobrir quem tem conta no sistema.
      return 'E-mail ou senha incorretos.';
    case 'email-already-in-use':
      return 'Já existe uma conta com este e-mail.';
    case 'weak-password':
      return 'A senha precisa de pelo menos 6 caracteres.';
    case 'too-many-requests':
      return 'Muitas tentativas. Aguarde alguns minutos e tente de novo.';
    case 'network-request-failed':
      return 'Sem conexão. Verifique sua internet.';
    case 'operation-not-allowed':
      return 'Este método de login não está habilitado no projeto.';
    default:
      return 'Não foi possível concluir. (${e.code})';
  }
}

/// Validação de e-mail suficiente para formulário: presença de um `@` com
/// texto dos dois lados e um ponto no domínio. Validação de verdade é o
/// e-mail de verificação chegar.
String? validarEmail(String? valor) {
  final String email = (valor ?? '').trim();
  if (email.isEmpty) return 'Informe o e-mail.';
  final RegExp formato = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!formato.hasMatch(email)) return 'E-mail inválido.';
  return null;
}

/// O Firebase recusa senha com menos de 6 caracteres. Checar antes evita uma
/// ida à rede para receber um erro que dava para prever.
String? validarSenha(String? valor) {
  final String senha = valor ?? '';
  if (senha.isEmpty) return 'Informe a senha.';
  if (senha.length < 6) return 'A senha precisa de pelo menos 6 caracteres.';
  return null;
}
