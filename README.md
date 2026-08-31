# ACQA — Gestão de Tarefas

Aplicativo Flutter de tarefas com autenticação por e-mail e senha, tarefas salvas por usuário no Firestore e um calendário ligado às datas de vencimento.

## O que o app faz

- Criar conta, entrar e recuperar senha (Firebase Auth)
- Criar, editar, concluir e excluir tarefas
- Definir data de vencimento e ver a tarefa marcada no calendário
- Tocar num dia do calendário para ver as tarefas daquele dia
- Destacar tarefas atrasadas
- Ocultar ou mostrar as concluídas
- Sincronizar entre dispositivos: as tarefas ficam no Firestore, sob a conta do usuário

## O que ele não faz

Vale dizer, para o README descrever o aplicativo e não a intenção:

- não tem notificação nem lembrete;
- não funciona offline — sem internet, a lista não carrega;
- não tem categorias, etiquetas nem tarefas recorrentes;
- não tem foto de perfil nem edição de conta além da senha.

## Como está organizado

```
lib/
  main.dart                     inicializa o Firebase e sobe o app
  app.dart                      o único MaterialApp + porta de autenticação
  models/tarefa.dart            modelo e regras de domínio, em Dart puro
  data/tarefa_repository.dart   acesso ao Firestore
  pages/                        uma tela por arquivo
  widgets/tarefa_tile.dart      a linha de tarefa, usada pela lista e pelo calendário
  utils/mensagens_auth.dart     tradução dos erros do Firebase e validações
test/tarefa_test.dart           testes do modelo, do agrupamento e da ordenação
firestore.rules                 regras de segurança do banco
```

Três decisões que valem explicação:

**O modelo não conhece o Firestore.** `models/tarefa.dart` não importa `cloud_firestore`. Quem converte `Timestamp` em `DateTime` é o repositório. É isso que permite testar o domínio com `flutter test`, sem emulador, sem rede e sem projeto no Firebase.

**As tarefas ficam em `usuarios/{uid}/tarefas`, não numa coleção única com um campo `uid`.** Com o dono no caminho, a regra de segurança é uma comparação entre o `uid` do documento e o de quem pede, e não existe consulta capaz de trazer tarefa de outra pessoa. Na coleção única, esquecer um `where` no cliente vazaria tudo.

**Quem decide entre login e app é o `authStateChanges`.** Não há `Navigator.pushReplacement` depois do `signIn`. Isso resolve dois problemas de uma vez: a sessão salva é reconhecida ao reabrir o app, e o logout volta para o login de qualquer tela, sem cada tela precisar saber disso.

## Rodar o projeto

```bash
flutter pub get
flutter run
```

As pastas de plataforma (`android/`, `ios/`, `web/`) são versionadas, então o projeto roda logo depois do clone. Se por algum motivo elas faltarem, recrie com `flutter create --project-name acqa .` — o nome precisa ser passado explicitamente porque a pasta do repositório tem hífen, e hífen não é válido em nome de pacote Dart.

Para conectar ao seu próprio Firebase, em vez do projeto usado no desenvolvimento:

```bash
dart pub global activate flutterfire_cli
flutterfire configure      # regrava lib/firebase_options.dart
```

No console do Firebase, habilite **Authentication → E-mail/senha** e crie um banco **Firestore**. Depois publique as regras deste repositório:

```bash
firebase deploy --only firestore:rules
```

Sem essa última etapa o Firestore fica no modo de teste, que expira e libera acesso amplo enquanto vale.

## Testes

```bash
flutter test
flutter analyze
```

Os testes cobrem a leitura de documento incompleto ou com data em formato inesperado, o agrupamento por dia (incluindo tarefas sem data, que ficam fora da agenda) e a ordem de exibição. São testes de domínio: não sobem Firebase.

## Histórico

**v1.1** — as tarefas passaram a ser salvas no Firestore por usuário; antes viviam numa lista em memória e sumiam ao fechar o app. O calendário, que só desenhava os dias, passou a ler as mesmas tarefas e marcar as datas de vencimento. Também foram removidos o `MaterialApp` aninhado dentro da HomePage, os `TextEditingController` sem `dispose` e o tratamento de erro que respondia a mesma frase para qualquer falha de login.

**v1.0** — versão acadêmica, com autenticação no Firebase e tarefas em memória.

## Sobre

Projeto desenvolvido para a disciplina de Desenvolvimento para Dispositivos Móveis e mantido depois como estudo. Autor: [Alan Fabrício de Morais Filho](https://github.com/AlanFMF).
