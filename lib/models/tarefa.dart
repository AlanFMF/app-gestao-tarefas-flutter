/// Uma tarefa do usuário.
///
/// Esta classe é Dart puro de propósito: não importa `cloud_firestore` nem
/// `flutter`. Quem converte `Timestamp` em `DateTime` é o repositório, e é o
/// que permite testar o modelo com `flutter test` sem subir Firebase nenhum.
class Tarefa {
  const Tarefa({
    required this.id,
    required this.texto,
    this.concluida = false,
    this.vencimento,
    this.criadoEm,
  });

  final String id;
  final String texto;
  final bool concluida;

  /// Dia em que a tarefa vence. Nulo quando ela não tem data marcada — é o
  /// que separa "lista de afazeres" de "agenda".
  final DateTime? vencimento;

  final DateTime? criadoEm;

  Tarefa copyWith({
    String? id,
    String? texto,
    bool? concluida,
    DateTime? vencimento,
    bool limparVencimento = false,
  }) {
    return Tarefa(
      id: id ?? this.id,
      texto: texto ?? this.texto,
      concluida: concluida ?? this.concluida,
      vencimento: limparVencimento ? null : (vencimento ?? this.vencimento),
      criadoEm: criadoEm,
    );
  }

  /// O mapa que vai para o Firestore. As datas saem como `DateTime`; o driver
  /// do Firestore converte para `Timestamp` sozinho.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'texto': texto,
      'concluida': concluida,
      'vencimento': vencimento,
      'criadoEm': criadoEm,
    };
  }

  /// Reconstrói a tarefa a partir de um documento já normalizado.
  ///
  /// Tolera documento incompleto de propósito: um app que já rodou antes pode
  /// ter gravado tarefa sem `criadoEm`, e uma tela não deve quebrar por isso.
  factory Tarefa.fromMap(String id, Map<String, dynamic> dados) {
    return Tarefa(
      id: id,
      texto: (dados['texto'] as String?)?.trim() ?? '',
      concluida: dados['concluida'] as bool? ?? false,
      vencimento: _paraData(dados['vencimento']),
      criadoEm: _paraData(dados['criadoEm']),
    );
  }

  static DateTime? _paraData(Object? valor) {
    if (valor == null) return null;
    if (valor is DateTime) return valor;
    if (valor is int) return DateTime.fromMillisecondsSinceEpoch(valor);
    if (valor is String) return DateTime.tryParse(valor);
    return null;
  }

  @override
  String toString() => 'Tarefa($id, "$texto", concluida: $concluida)';

  @override
  bool operator ==(Object other) =>
      other is Tarefa &&
      other.id == id &&
      other.texto == texto &&
      other.concluida == concluida &&
      other.vencimento == vencimento;

  @override
  int get hashCode => Object.hash(id, texto, concluida, vencimento);
}

/// Normaliza uma data para o começo do dia.
///
/// Sem isso, duas tarefas do mesmo dia com horas diferentes viram chaves
/// diferentes e o calendário deixa de marcar o dia.
DateTime diaDe(DateTime data) => DateTime(data.year, data.month, data.day);

/// Agrupa tarefas por dia de vencimento. Tarefas sem data ficam de fora — elas
/// pertencem à lista, não à agenda.
///
/// Função pura, testável sem Firebase e sem widget.
Map<DateTime, List<Tarefa>> agruparPorDia(Iterable<Tarefa> tarefas) {
  final Map<DateTime, List<Tarefa>> porDia = <DateTime, List<Tarefa>>{};
  for (final Tarefa tarefa in tarefas) {
    final DateTime? vencimento = tarefa.vencimento;
    if (vencimento == null) continue;
    porDia.putIfAbsent(diaDe(vencimento), () => <Tarefa>[]).add(tarefa);
  }
  return porDia;
}

/// Formata uma data como dd/MM/aaaa.
///
/// Escrito à mão para o app não depender de `intl` e da inicialização de
/// locale só para mostrar uma data curta.
String formatarData(DateTime data) {
  final String dia = data.day.toString().padLeft(2, '0');
  final String mes = data.month.toString().padLeft(2, '0');
  return '$dia/$mes/${data.year}';
}

/// Ordena: pendentes antes de concluídas, depois por vencimento (sem data por
/// último) e, no empate, pelo texto.
///
/// Vive aqui, e não no repositório, porque ordem de exibição é regra de
/// domínio e não acesso a dados — e porque assim o teste roda sem arrastar o
/// plugin do Firestore junto.
void ordenar(List<Tarefa> tarefas) {
  tarefas.sort((Tarefa a, Tarefa b) {
    if (a.concluida != b.concluida) return a.concluida ? 1 : -1;
    final DateTime? va = a.vencimento;
    final DateTime? vb = b.vencimento;
    if (va != null && vb != null && va != vb) return va.compareTo(vb);
    if (va == null && vb != null) return 1;
    if (va != null && vb == null) return -1;
    return a.texto.toLowerCase().compareTo(b.texto.toLowerCase());
  });
}
