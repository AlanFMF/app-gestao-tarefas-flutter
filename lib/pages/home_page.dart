import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/tarefa_repository.dart';
import 'calendario_page.dart';
import 'lista_page.dart';

/// Casca do app depois do login.
///
/// A tela inicial antiga mostrava "DPDM" e o RA em fonte 50, e o botão de
/// adicionar abria um diálogo com os dados do autor. Era entrega de trabalho,
/// não produto — e num repositório público expunha um dado pessoal sem
/// necessidade. Aqui a home é o que o usuário veio fazer: as tarefas.
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.usuario, this.repository});

  final User usuario;

  /// Injetável para teste de widget; em produção usa o Firestore real.
  final TarefaRepository? repository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TarefaRepository _repo = widget.repository ?? TarefaRepository();
  int _aba = 0;

  Future<void> _sair() async {
    final bool confirmou = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Sair da conta?'),
            content: const Text('Suas tarefas continuam salvas.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sair'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmou) return;
    await FirebaseAuth.instance.signOut();
    // Sem navegação manual: o AuthGate volta para o login sozinho.
  }

  @override
  Widget build(BuildContext context) {
    final String uid = widget.usuario.uid;
    return Scaffold(
      appBar: AppBar(
        title: Text(_aba == 0 ? 'Minhas tarefas' : 'Calendário'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String valor) {
              if (valor == 'sair') _sair();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                enabled: false,
                child: Text(widget.usuario.email ?? 'Conectado'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'sair',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sair'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _aba,
        children: <Widget>[
          ListaPage(uid: uid, repository: _repo),
          CalendarioPage(uid: uid, repository: _repo),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: (int i) => setState(() => _aba = i),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Lista',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Calendário',
          ),
        ],
      ),
    );
  }
}
