# Supabase Storage – imagens de produtos

O app admin envia as imagens dos produtos para o **Supabase Storage**. O bucket usado é `product-images`.

## 1. Criar o bucket no Supabase

1. Acesse o [Dashboard do Supabase](https://supabase.com/dashboard) e abra seu projeto.
2. Vá em **Storage** e crie um bucket:
   - Nome: `product-images`
   - **Public bucket**: marque como público para as URLs das imagens funcionarem no front de vendas.
3. (Opcional) Em **Policies**, garanta que o bucket permita upload (por exemplo, política para `authenticated` ou para a `anon` key, conforme sua estratégia de segurança).

## 2. Configurar o app admin

Informe a URL e a chave anon do projeto ao rodar o app:

```bash
flutter run --dart-define=SUPABASE_URL=https://SEU_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Ou defina no seu ambiente/IDE os mesmos valores para `SUPABASE_URL` e `SUPABASE_ANON_KEY`.

Sem isso, o formulário de produto continua funcionando, mas as opções de imagens (Galeria/Câmera) não farão upload.

## 3. Fluxo no app

- **Galeria**: várias imagens.
- **Câmera**: uma foto por vez (pode usar várias vezes).
- As imagens são enviadas para `product-images/{productId}/{uuid}.{ext}` e as URLs públicas são salvas no campo `images` do produto no backend.
