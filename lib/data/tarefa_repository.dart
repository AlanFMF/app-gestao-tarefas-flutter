import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/tarefa.dart';

/// Acesso às tarefas no Firestore.
///
/// Tudo fica sob `usuarios/{uid}/tarefas`, e não numa coleção global com um
/// campo `uid`. A diferença importa: com subcoleção, a regra de segurança é
/// uma linha comparando o caminho com o usuário autenticado, e não existe
/// consulta capaz de devolver tarefa de outra pessoa nem por engano.
///
/// A instância do Firestore entra pelo construtor para a classe poder ser
/// testada com um Firestore falso, em vez de depender do singleton.
class TarefaRepository {
  TarefaRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _colecao(String uid) =>
      _db.collection('usuarios').doc(uid).collection('tarefas');

  /// Fluxo das tarefas do usuário, já ordenadas.
  ///
  /// A ordenação é feita aqui e não no Firestore porque `orderBy` num campo
  /// que aceita nulo esconde os documentos sem vencimento — e tarefa sem data
  /// é justamente o caso mais comum.
  Stream<List<Tarefa>> observar(String uid) {
    return _colecao(uid).snapshots().map((QuerySnapshot<Map<String, dynamic>> snap) {
      final List<Tarefa> tarefas = snap.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              Tarefa.fromMap(doc.id, _normalizar(doc.data())))
          .toList();
      ordenar(tarefas);
      return tarefas;
    });
  }

  Future<Tarefa> criar(String uid, String texto, {DateTime? vencimento}) async {
    final String limpo = texto.trim();
    if (limpo.isEmpty) {
      throw ArgumentError('A tarefa precisa de um texto.');
    }
    final DocumentReference<Map<String, dynamic>> doc = await _colecao(uid).add(<String, dynamic>{
      'texto': limpo,
      'concluida': false,
      'vencimento': vencimento,
      'criadoEm': FieldValue.serverTimestamp(),
    });
    return Tarefa(id: doc.id, texto: limpo, vencimento: vencimento);
  }

  Future<void> alternarConclusao(String uid, Tarefa tarefa) {
    return _colecao(uid).doc(tarefa.id).update(<String, dynamic>{
      'concluida': !tarefa.concluida,
    });
  }

  Future<void> renomear(String uid, Tarefa tarefa, String novoTexto) {
    final String limpo = novoTexto.trim();
    if (limpo.isEmpty) {
      throw ArgumentError('A tarefa precisa de um texto.');
    }
    return _colecao(uid).doc(tarefa.id).update(<String, dynamic>{'texto': limpo});
  }

  Future<void> definirVencimento(String uid, Tarefa tarefa, DateTime? vencimento) {
    return _colecao(uid).doc(tarefa.id).update(<String, dynamic>{
      'vencimento': vencimento,
    });
  }

  Future<void> remover(String uid, Tarefa tarefa) {
    return _colecao(uid).doc(tarefa.id).delete();
  }

  /// Converte os `Timestamp` do Firestore em `DateTime` antes de entregar ao
  /// modelo, que é Dart puro e não conhece o pacote do Firestore.
  Map<String, dynamic> _normalizar(Map<String, dynamic> dados) {
    return dados.map((String chave, dynamic valor) {
      if (valor is Timestamp) return MapEntry<String, dynamic>(chave, valor.toDate());
      return MapEntry<String, dynamic>(chave, valor);
    });
  }
}
