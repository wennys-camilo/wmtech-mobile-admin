# wmtech Admin (Flutter)

App mobile admin para cadastro de produtos, integrado ao backend wmtech (NestJS).

## Arquitetura (Clean Architecture)

- **core/** – Infraestrutura compartilhada: `ApiClient`, `AuthStorage`, `AppConfig`
- **domain/** – Entidades e contratos (repositórios abstratos); sem dependências externas
- **data/** – Implementação dos repositórios e datasources (chamadas HTTP)
- **presentation/** – Telas e widgets; **nunca** chamam API diretamente, apenas repositórios

A UI depende apenas dos contratos em `domain`; a implementação em `data` pode ser trocada (ex.: mock em testes).

## Configuração

### URL da API

Por padrão a API é `http://localhost:3005`. Para alterar:

- **Emulador Android:** use `http://10.0.2.2:3005` (10.0.2.2 = host da máquina).
- **Build com variável:**  
  `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3005`

O valor é lido em `lib/core/config.dart` via `String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3005')`.

### Backend

1. Subir o backend (ex.: `npm run start:dev` no **wmtech-backend**).
2. Ter um usuário cadastrado (POST `/users/register` ou via front web) para fazer login no app.

## Como rodar

```bash
cd wmtech_admin
flutter pub get
flutter run
```

Para emulador Android com API no host:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3005
```

## Fluxo

1. **Login** – E-mail e senha; chama `AuthRepository.login` → POST `/auth/login`; token salvo em `SharedPreferences`.
2. **Lista de produtos** – `ProductRepository.getProducts` → GET `/products` ou `/products?all=true` (inclui inativos).
3. **Novo produto** – FAB → formulário → `ProductRepository.createProduct` → POST `/products` (com Bearer).
4. **Editar produto** – Toque no item → mesmo formulário → `ProductRepository.updateProduct` → PATCH `/products/:id`.
5. **Sair** – Menu → Sair → `AuthRepository.logout` (limpa token) e volta para a tela de login.

## Endpoints utilizados

| Método | Rota              | Auth | Uso        |
|--------|-------------------|------|------------|
| POST   | /auth/login       | Não  | Login      |
| GET    | /products         | Não  | Listar     |
| GET    | /products?all=true| Não  | Listar todos|
| POST   | /products         | JWT  | Criar      |
| PATCH  | /products/:id     | JWT  | Atualizar  |
