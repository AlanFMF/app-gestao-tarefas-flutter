import 'package:acqa/models/tarefa.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testes da lógica que não depende de Firebase nem de tela.
///
/// O modelo e as funções de agrupamento e ordenação foram deixados em Dart
/// puro justamente para caberem aqui: `flutter test` roda tudo isto sem
/// emulador, sem rede e sem projeto no Firebase.
void main() {
  group('Tarefa.fromMap', () {
    test('lê um documento completo', () {
      final Tarefa t = Tarefa.fromMap('abc', <String, dynamic>{
        'texto': '  Estudar SQL  ',
        'concluida': true,
        'vencimento': DateTime(2026, 9, 10),
        'criadoEm': DateTime(2026, 9, 1),
      });

      expect(t.id, 'abc');
      expect(t.texto, 'Estudar SQL', reason: 'o texto deve vir sem espaços nas pontas');
      expect(t.concluida, isTrue);
      expect(t.vencimento, DateTime(2026, 9, 10));
    });

    test('aguenta documento incompleto sem quebrar', () {
      // Um app que já rodou antes pode ter gravado documento sem todos os
      // campos. A tela não pode explodir por causa disso.
      final Tarefa t = Tarefa.fromMap('x', <String, dynamic>{});

      expect(t.texto, '');
      expect(t.concluida, isFalse);
      expect(t.vencimento, isNull);
      expect(t.criadoEm, isNull);
    });

    test('aceita data em milissegundos e em texto ISO', () {
      final int millis = DateTime(2026, 5, 4).millisecondsSinceEpoch;
      final Tarefa a = Tarefa.fromMap('a', <String, dynamic>{'vencimento': millis});
      final Tarefa b =
          Tarefa.fromMap('b', <String, dynamic>{'vencimento': '2026-05-04T00:00:00'});

      expect(a.vencimento, DateTime(2026, 5, 4));
      expect(b.vencimento, DateTime(2026, 5, 4));
    });

    test('ignora data em formato desconhecido em vez de lançar', () {
      final Tarefa t = Tarefa.fromMap('a', <String, dynamic>{'vencimento': <int>[1, 2]});
      expect(t.vencimento, isNull);
    });
  });

  group('copyWith', () {
    final Tarefa base = Tarefa(
      id: '1',
      texto: 'Original',
      vencimento: DateTime(2026, 7, 7),
    );

    test('troca só o que foi pedido', () {
      final Tarefa nova = base.copyWith(concluida: true);
      expect(nova.texto, 'Original');
      expect(nova.vencimento, DateTime(2026, 7, 7));
      expect(nova.concluida, isTrue);
    });

    test('limparVencimento remove a data', () {
      // Sem esse sinalizador não haveria como apagar a data: passar null em
      // copyWith é indistinguível de "não mexa neste campo".
      final Tarefa nova = base.copyWith(limparVencimento: true);
      expect(nova.vencimento, isNull);
    });
  });

  group('diaDe', () {
    test('zera a hora para duas tarefas do mesmo dia caírem na mesma chave', () {
      final DateTime manha = DateTime(2026, 3, 2, 8, 30);
      final DateTime noite = DateTime(2026, 3, 2, 23, 59);
      expect(diaDe(manha), diaDe(noite));
    });
  });

  group('agruparPorDia', () {
    test('agrupa por dia e descarta tarefa sem vencimento', () {
      final List<Tarefa> tarefas = <Tarefa>[
        Tarefa(id: '1', texto: 'A', vencimento: DateTime(2026, 3, 2, 9)),
        Tarefa(id: '2', texto: 'B', vencimento: DateTime(2026, 3, 2, 18)),
        Tarefa(id: '3', texto: 'C', vencimento: DateTime(2026, 3, 5)),
        const Tarefa(id: '4', texto: 'Sem data'),
      ];

      final Map<DateTime, List<Tarefa>> porDia = agruparPorDia(tarefas);

      expect(porDia.length, 2);
      expect(porDia[DateTime(2026, 3, 2)]!.length, 2);
      expect(porDia[DateTime(2026, 3, 5)]!.length, 1);
      expect(
        porDia.values.expand((List<Tarefa> l) => l).any((Tarefa t) => t.id == '4'),
        isFalse,
        reason: 'tarefa sem data pertence à lista, não à agenda',
      );
    });

    test('devolve mapa vazio para lista vazia', () {
      expect(agruparPorDia(const <Tarefa>[]), isEmpty);
    });
  });

  group('ordenar', () {
    test('pendentes antes de concluídas, depois por data, depois por texto', () {
      final List<Tarefa> tarefas = <Tarefa>[
        const Tarefa(id: '1', texto: 'Zebra', concluida: true),
        const Tarefa(id: '2', texto: 'Banana'),
        Tarefa(id: '3', texto: 'Abacaxi', vencimento: DateTime(2026, 1, 5)),
        Tarefa(id: '4', texto: 'Caju', vencimento: DateTime(2026, 1, 2)),
      ];

      ordenar(tarefas);

      expect(
        tarefas.map((Tarefa t) => t.texto).toList(),
        <String>['Caju', 'Abacaxi', 'Banana', 'Zebra'],
      );
    });

    test('tarefa sem data vai depois das que têm data', () {
      final List<Tarefa> tarefas = <Tarefa>[
        const Tarefa(id: '1', texto: 'Sem data'),
        Tarefa(id: '2', texto: 'Com data', vencimento: DateTime(2030, 1, 1)),
      ];

      ordenar(tarefas);

      expect(tarefas.first.texto, 'Com data');
    });
  });

  group('formatarData', () {
    test('preenche dia e mês com zero à esquerda', () {
      expect(formatarData(DateTime(2026, 1, 5)), '05/01/2026');
      expect(formatarData(DateTime(2026, 12, 31)), '31/12/2026');
    });
  });
}
