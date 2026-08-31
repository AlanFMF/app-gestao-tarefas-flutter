import 'package:flutter/material.dart';

import '../models/tarefa.dart';

/// Linha de uma tarefa, usada pela lista e pelo calendário.
///
/// Existe como widget próprio porque as duas telas mostram a mesma coisa: sem
/// isso, qualquer ajuste visual precisaria ser feito em dois lugares e um dos
/// dois ficaria para trás.
class TarefaTile extends StatelessWidget {
  const TarefaTile({
    super.key,
    required this.tarefa,
    required this.onAlternar,
    required this.onRemover,
    this.onEditar,
    this.mostrarVencimento = true,
  });

  final Tarefa tarefa;
  final VoidCallback onAlternar;
  final VoidCallback onRemover;
  final VoidCallback? onEditar;
  final bool mostrarVencimento;

  bool get _atrasada {
    final DateTime? vencimento = tarefa.vencimento;
    if (vencimento == null || tarefa.concluida) return false;
    return diaDe(vencimento).isBefore(diaDe(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    final DateTime? vencimento = tarefa.vencimento;

    return Dismissible(
      key: ValueKey<String>(tarefa.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: tema.colorScheme.errorContainer,
        child: Icon(Icons.delete_outline, color: tema.colorScheme.onErrorContainer),
      ),
      // Devolve false de propósito: quem tira a linha da tela é o stream do
      // Firestore, depois que a exclusão volta. Se o Dismissible removesse o
      // widget sozinho antes disso, o Flutter dispararia a asserção "A
      // dismissed Dismissible widget is still part of the tree" no próximo
      // build, porque a tarefa ainda estaria na lista.
      confirmDismiss: (DismissDirection _) async {
        onRemover();
        return false;
      },
      child: ListTile(
        onTap: onEditar,
        leading: Checkbox(
          value: tarefa.concluida,
          onChanged: (_) => onAlternar(),
        ),
        title: Text(
          tarefa.texto,
          style: TextStyle(
            decoration: tarefa.concluida ? TextDecoration.lineThrough : null,
            color: tarefa.concluida ? tema.disabledColor : null,
          ),
        ),
        subtitle: (mostrarVencimento && vencimento != null)
            ? Row(
                children: <Widget>[
                  Icon(
                    Icons.event_outlined,
                    size: 14,
                    color: _atrasada ? tema.colorScheme.error : tema.hintColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatarData(vencimento),
                    style: TextStyle(
                      color: _atrasada ? tema.colorScheme.error : tema.hintColor,
                      fontWeight: _atrasada ? FontWeight.bold : null,
                    ),
                  ),
                  if (_atrasada) ...<Widget>[
                    const SizedBox(width: 6),
                    Text(
                      'atrasada',
                      style: TextStyle(
                        color: tema.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              )
            : null,
      ),
    );
  }
}
