import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../data/tarefa_repository.dart';
import '../models/tarefa.dart';
import '../widgets/tarefa_tile.dart';

/// Calendário ligado às tarefas.
///
/// Antes, esta tela desenhava um `TableCalendar` que não conhecia tarefa
/// nenhuma: selecionar um dia só movia o foco, e a única ligação com a lista
/// era um item de menu que navegava para ela. O README chamava isso de
/// "organização por calendário".
///
/// Agora o calendário lê o mesmo fluxo do Firestore que a lista: os dias com
/// tarefa ganham marcador, e tocar num dia mostra as tarefas dele.
class CalendarioPage extends StatefulWidget {
  const CalendarioPage({super.key, required this.uid, required this.repository});

  final String uid;
  final TarefaRepository repository;

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  CalendarFormat _formato = CalendarFormat.month;
  DateTime _focado = DateTime.now();
  DateTime? _selecionado = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Tarefa>>(
      stream: widget.repository.observar(widget.uid),
      builder: (BuildContext context, AsyncSnapshot<List<Tarefa>> snap) {
        if (snap.hasError) {
          return const Center(child: Text('Não foi possível carregar a agenda.'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final Map<DateTime, List<Tarefa>> porDia = agruparPorDia(snap.data!);
        final DateTime dia = diaDe(_selecionado ?? _focado);
        final List<Tarefa> doDia = porDia[dia] ?? const <Tarefa>[];

        return Column(
          children: <Widget>[
            TableCalendar<Tarefa>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: _focado,
              calendarFormat: _formato,
              startingDayOfWeek: StartingDayOfWeek.monday,
              availableCalendarFormats: const <CalendarFormat, String>{
                CalendarFormat.month: 'Mês',
                CalendarFormat.twoWeeks: '2 semanas',
                CalendarFormat.week: 'Semana',
              },
              selectedDayPredicate: (DateTime d) => isSameDay(_selecionado, d),
              // É daqui que vem o marcador embaixo do número do dia.
              eventLoader: (DateTime d) => porDia[diaDe(d)] ?? const <Tarefa>[],
              onDaySelected: (DateTime selecionado, DateTime focado) {
                setState(() {
                  _selecionado = selecionado;
                  _focado = focado;
                });
              },
              onFormatChanged: (CalendarFormat f) => setState(() => _formato = f),
              onPageChanged: (DateTime focado) => _focado = focado,
              calendarStyle: CalendarStyle(
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${formatarData(dia)} · ${doDia.length} tarefa(s)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
            Expanded(
              child: doDia.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhuma tarefa com vencimento neste dia.',
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                    )
                  : ListView.builder(
                      itemCount: doDia.length,
                      itemBuilder: (BuildContext context, int i) {
                        final Tarefa tarefa = doDia[i];
                        return TarefaTile(
                          tarefa: tarefa,
                          mostrarVencimento: false,
                          onAlternar: () => widget.repository
                              .alternarConclusao(widget.uid, tarefa),
                          onRemover: () =>
                              widget.repository.remover(widget.uid, tarefa),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
