import 'package:flutter/material.dart';

import '../data/tarefa_repository.dart';
import '../models/tarefa.dart';
import '../widgets/tarefa_tile.dart';

/// Lista de tarefas do usuário, vinda do Firestore.
///
/// A versão anterior guardava as tarefas numa `List<Tarefa>` dentro do
/// `setState`: fechar o app apagava tudo, e o README prometia o contrário.
/// Agora a fonte é o `snapshots()` do Firestore, então a tela reflete o
/// estado real e acompanha alteração feita em outro dispositivo.
class ListaPage extends StatefulWidget {
  const ListaPage({super.key, required this.uid, required this.repository});

  final String uid;
  final TarefaRepository repository;

  @override
  State<ListaPage> createState() => _ListaPageState();
}

class _ListaPageState extends State<ListaPage> {
  final TextEditingController _novaTarefa = TextEditingController();
  DateTime? _vencimentoEscolhido;
  bool _mostrarConcluidas = true;

  @override
  void dispose() {
    _novaTarefa.dispose();
    super.dispose();
  }

  Future<void> _adicionar() async {
    final String texto = _novaTarefa.text.trim();
    if (texto.isEmpty) return;
    // Limpo o campo antes do await para a digitação seguinte não ser
    // sobrescrita quando a rede demora.
    _novaTarefa.clear();
    final DateTime? vencimento = _vencimentoEscolhido;
    setState(() => _vencimentoEscolhido = null);
    try {
      await widget.repository.criar(widget.uid, texto, vencimento: vencimento);
    } catch (_) {
      if (!mounted) return;
      _avisar('Não foi possível salvar a tarefa.');
    }
  }

  Future<void> _escolherVencimento() async {
    final DateTime hoje = DateTime.now();
    final DateTime? escolhido = await showDatePicker(
      context: context,
      initialDate: _vencimentoEscolhido ?? hoje,
      firstDate: DateTime(hoje.year - 1),
      lastDate: DateTime(hoje.year + 5),
    );
    if (escolhido == null || !mounted) return;
    setState(() => _vencimentoEscolhido = diaDe(escolhido));
  }

  Future<void> _editar(Tarefa tarefa) async {
    final TextEditingController controle =
        TextEditingController(text: tarefa.texto);
    final String? novo = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Editar tarefa'),
        content: TextField(
          controller: controle,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Descrição'),
          onSubmitted: (String v) => Navigator.of(context).pop(v),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controle.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controle.dispose();
    if (novo == null || novo.trim().isEmpty || novo.trim() == tarefa.texto) return;
    try {
      await widget.repository.renomear(widget.uid, tarefa, novo);
    } catch (_) {
      if (!mounted) return;
      _avisar('Não foi possível editar a tarefa.');
    }
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _novaTarefa,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'Nova tarefa',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _adicionar(),
                ),
              ),
              IconButton(
                tooltip: _vencimentoEscolhido == null
                    ? 'Definir data'
                    : 'Vence em ${formatarData(_vencimentoEscolhido!)}',
                icon: Icon(
                  Icons.event,
                  color: _vencimentoEscolhido != null
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onPressed: _escolherVencimento,
              ),
              IconButton(
                tooltip: 'Adicionar',
                icon: const Icon(Icons.add_circle),
                onPressed: _adicionar,
              ),
            ],
          ),
        ),
        if (_vencimentoEscolhido != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text('Vence em ${formatarData(_vencimentoEscolhido!)}'),
                onDeleted: () => setState(() => _vencimentoEscolhido = null),
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<List<Tarefa>>(
            stream: widget.repository.observar(widget.uid),
            builder: (BuildContext context, AsyncSnapshot<List<Tarefa>> snap) {
              if (snap.hasError) {
                return const _Aviso(
                  icone: Icons.cloud_off,
                  texto: 'Não foi possível carregar suas tarefas.',
                );
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final List<Tarefa> todas = snap.data!;
              if (todas.isEmpty) {
                return const _Aviso(
                  icone: Icons.checklist,
                  texto: 'Nenhuma tarefa ainda.\nEscreva a primeira acima.',
                );
              }
              final List<Tarefa> visiveis = _mostrarConcluidas
                  ? todas
                  : todas.where((Tarefa t) => !t.concluida).toList();
              final int concluidas =
                  todas.where((Tarefa t) => t.concluida).length;

              return Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: <Widget>[
                        Text('${todas.length - concluidas} pendente(s)'),
                        const Spacer(),
                        if (concluidas > 0)
                          TextButton.icon(
                            onPressed: () => setState(
                                () => _mostrarConcluidas = !_mostrarConcluidas),
                            icon: Icon(_mostrarConcluidas
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            label: Text(_mostrarConcluidas
                                ? 'Ocultar concluídas ($concluidas)'
                                : 'Mostrar concluídas ($concluidas)'),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: visiveis.length,
                      itemBuilder: (BuildContext context, int i) {
                        final Tarefa tarefa = visiveis[i];
                        return TarefaTile(
                          tarefa: tarefa,
                          onAlternar: () => widget.repository
                              .alternarConclusao(widget.uid, tarefa),
                          onRemover: () =>
                              widget.repository.remover(widget.uid, tarefa),
                          onEditar: () => _editar(tarefa),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icone, size: 48, color: Theme.of(context).hintColor),
          const SizedBox(height: 12),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }
}
