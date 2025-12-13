import 'package:flutter/material.dart';

class ListaTarefasPage extends StatefulWidget {
  const ListaTarefasPage({Key? key}) : super(key: key);

  @override
  _ListaTarefasPageState createState() => _ListaTarefasPageState();
}

class _ListaTarefasPageState extends State<ListaTarefasPage> {
  List<Tarefa> _tarefas = [];
  List<Tarefa> _tarefasConcluidas = [];

  TextEditingController _controller = TextEditingController();

  void _adicionarTarefa() {
    setState(() {
      String novaTarefaTexto = _controller.text.trim();
      if (novaTarefaTexto.isNotEmpty) {
        Tarefa novaTarefa = Tarefa(texto: novaTarefaTexto, concluida: false);
        _tarefas.add(novaTarefa);
        _controller.clear();
      }
    });
  }

  void _removerTarefa(int index) {
    setState(() {
      _tarefas.removeAt(index);
    });
  }

  void _concluirTarefa(int index) {
    setState(() {
      Tarefa tarefa = _tarefas[index];
      tarefa.concluida = true;
      _tarefas.removeAt(index);
      _tarefasConcluidas.add(tarefa);
    });
  }

  void _desmarcarConcluida(int index) {
    setState(() {
      Tarefa tarefa = _tarefasConcluidas[index];
      tarefa.concluida = false;
      _tarefasConcluidas.removeAt(index);
      _tarefas.add(tarefa);
    });
  }

  void _removerTarefaConcluida(int index) {
    setState(() {
      _tarefasConcluidas.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Tarefas'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Nova Tarefa',
                    ),
                    onSubmitted: (_) => _adicionarTarefa(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _adicionarTarefa,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildListaTarefas('Tarefas em Progresso', _tarefas,
                    _concluirTarefa, _removerTarefa),
                const SizedBox(height: 16),
                _buildListaTarefasConcluidas(
                    'Tarefas Concluídas',
                    _tarefasConcluidas,
                    _desmarcarConcluida,
                    _removerTarefaConcluida),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaTarefas(String title, List<Tarefa> tarefas,
      Function(int) onConcluir, Function(int) onRemover) {
    return Expanded(
      child: ListView.builder(
        itemCount: tarefas.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(
                tarefas[index].texto,
                style: TextStyle(
                  decoration: tarefas[index].concluida
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              leading: Checkbox(
                value: tarefas[index].concluida,
                onChanged: (value) {
                  onConcluir(index);
                },
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  onRemover(index);
                },
                color: Theme.of(context).primaryColor,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListaTarefasConcluidas(
      String title,
      List<Tarefa> tarefasConcluidas,
      Function(int) onDesmarcar,
      Function(int) onRemover) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tarefasConcluidas.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(
                      tarefasConcluidas[index].texto,
                      style: TextStyle(
                        decoration: tarefasConcluidas[index].concluida
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.undo),
                          onPressed: () {
                            onDesmarcar(index);
                          },
                          color: Theme.of(context).primaryColor,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            onRemover(index);
                          },
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Tarefa {
  String texto;
  bool concluida;

  Tarefa({required this.texto, required this.concluida});
}
