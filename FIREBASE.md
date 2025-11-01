Configuração Firestore (regras e índices)

Resumo
- Regras: leitura e criação em `jogos` apenas para utilizadores autenticados, com validação básica de campos.
- Índice composto: `ativo` (asc) + `data` (asc) com scope de Coleção.

Ficheiros
- `firestore.rules`: regras de segurança.
- `firestore.indexes.json`: configuração de índices compostos.

Pré‑requisitos
- Firebase CLI instalado e autenticado: `npm i -g firebase-tools && firebase login`.
- Seleciona o projeto certo: `firebase use <project-id>` (ex.: `futeboladas-62f15`).

Deploy
1) Regras do Firestore:
   - `firebase deploy --only firestore:rules`
2) Índices do Firestore:
   - `firebase firestore:indexes:apply firestore.indexes.json`
   - (ou) `firebase deploy --only firestore:indexes`

Notas
- O `lib/firebase_options.dart` já aponta para o projeto configurado via FlutterFire.
- Se precisares de ambientes (dev/prod), cria projetos distintos e gere um `firebase_options.dart` por flavor.
- Se alterares a query para `orderBy('data', descending: true)`, cria também um índice com `data` descendente.

