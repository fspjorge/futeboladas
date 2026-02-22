# Futeboladas

Aplicação móvel Flutter para gestão e marcação de jogos de futebol entre amigos. Desenvolvida com Firebase e Flutter.

---

## Funcionalidades

- Autenticação (Google e email)
- Lista de jogos ativos (Firestore)
- Criação/edição de jogo (local, data/hora, número de jogadores)
- Confirmação de presenças por utilizador
- Previsão do tempo (OpenWeather: atual e previsão aproximada)
- Autocomplete de locais: Integrado com **Photon API (OpenStreetMap)** - solução gratuita e sem necessidade de chaves de API.

---

## Tecnologias

- Flutter 3.x, Dart 3.x
- Firebase (Auth, Firestore)
- **Photon API** (via `OsmService`) para pesquisa de locais
- OpenWeather API
- Layout Responsive & Glassmorphism design

---

## Configuração do Projeto

1. Clonar o repositório
   ```bash
   git clone https://github.com/fspjorge/futeboladas.git
   cd futeboladas
   ```
2. Configurar Firebase (Auth + Firestore) e colocar os ficheiros de configuração nas plataformas.
3. Executar a app: `flutter run`

---

## Configuração de Chaves/API

### Pesquisa de Locais (Custo Zero)
A app utiliza a API do Photon (baseada em OpenStreetMap). Não é necessária qualquer configuração de chaves de API ou cartões de crédito para esta funcionalidade.

### OpenWeather
O `WeatherService` usa uma chave definida no código. Para alterar, edite `lib/services/weather_service.dart`.

---

## Android / iOS

- Permissão de rede (`INTERNET`) no `android/app/src/main/AndroidManifest.xml`.
- Coloque as configurações do Firebase (`google-services.json` para Android e `GoogleService-Info.plist` para iOS).
- O cabeçalho de detalhe do jogo (`JogoDetalhe`) foi ajustado para evitar overflows em moradas longas.

---

## Notas de Desenvolvimento

- O autocomplete de locais prioriza resultados em **Portugal** através de bias de localização (latitude/longitude) configurados no `OsmService`.
- O layout utiliza efeitos de blur e transparência (Glassmorphism) para um visual moderno.

## Estrutura relevante

- lib/screens/jogos/jogos_lista.dart — listagem de jogos
- lib/screens/jogos/jogos_form.dart — criação de jogo
- lib/screens/jogos/jogo_editar.dart — edição de jogo
- lib/services/osm_service.dart — Pesquisa de locais (Photon)
- lib/services/weather_service.dart — OpenWeather

## Licença

Uso interno. Não foi atribuída uma licença pública.

