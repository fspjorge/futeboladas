# Futeboladas

Aplicação móvel Flutter para gestão e marcação de jogos de futebol entre amigos. Desenvolvida com Firebase e Flutter.

---

## Funcionalidades

- Autenticação (Google e email)
- Lista de jogos ativos (Firestore)
- Criação/edição de jogo (local, data/hora, número de jogadores)
- Confirmação de presenças por utilizador
- Previsão do tempo (OpenWeather: atual e previsão aproximada)
- Autocomplete de locais (Flutter Google Places SDK) com fallback REST (Google Places API)

---

## Tecnologias

- Flutter 3.x, Dart 3.x
- Firebase (Auth, Firestore)
- flutter_google_places_sdk + REST Places API
- OpenWeather API

---

## Configuração do Projeto

1. Clonar o repositório
   ```bash
   git clone https://github.com/fspjorge/futeboladas.git
   cd futeboladas
   ```
2. Configurar Firebase (Auth + Firestore) e colocar os ficheiros de configuração nas plataformas.

---

## Configuração de Chaves/API

### Google Places API

A app suporta passar a chave via `--dart-define` usando a variável `PLACES_API_KEY`. Esta chave é usada tanto pelo SDK (`flutter_google_places_sdk`) como pelo serviço REST (`PlacesService`).

Exemplos:

```
flutter run --dart-define=PLACES_API_KEY=YOUR_GOOGLE_PLACES_API_KEY

# Build Android
flutter build apk --dart-define=PLACES_API_KEY=YOUR_GOOGLE_PLACES_API_KEY

# Build iOS
flutter build ios --dart-define=PLACES_API_KEY=YOUR_GOOGLE_PLACES_API_KEY
```

Se não definir, existe um valor por omissão no código. Recomenda-se usar a sua própria chave de API.

### OpenWeather

O `WeatherService` usa uma chave definida no código. Para alterar, edite `lib/services/weather_service.dart`.

---

## Android

- Permissão de rede (`INTERNET`) no `android/app/src/main/AndroidManifest.xml`.
- Coloque o `google-services.json` do Firebase em `android/app`.

## iOS

- Coloque o `GoogleService-Info.plist` do Firebase no projeto iOS.
- Verifique os requisitos do `flutter_google_places_sdk` em iOS.

---

## Executar localmente

```
flutter pub get
flutter run --dart-define=PLACES_API_KEY=YOUR_GOOGLE_PLACES_API_KEY
```

---

## Notas de Desenvolvimento

- A listagem de jogos está em ListView (vertical). Experiências de grelha (GridView) devem ser feitas em branch separada.
- O autocomplete usa primeiro o SDK nativo; se falhar, faz fallback ao REST com a mesma chave.
- O serviço REST de Places faz logging de erros (status e corpo).

## Estrutura relevante

- lib/screens/jogos/jogos_lista.dart — listagem de jogos
- lib/screens/jogos/jogos_form.dart — criação de jogo (autocomplete)
- lib/screens/jogos/jogo_editar.dart — edição de jogo (autocomplete)
- lib/services/places_service.dart — REST Google Places
- lib/services/weather_service.dart — OpenWeather

## Licença

Uso interno. Não foi atribuída uma licença pública.
