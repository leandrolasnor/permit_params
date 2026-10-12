# permit_params

Schemas de parâmetros **declarativos e por action** para controllers Rails.

Declare o que cada action espera e a gem cuida do `strong parameters` automaticamente.
Suporta `permit`, `required` + `permit` e a API nova `expect` do Rails 8.

```ruby
class HeroesController < ApplicationController
  permit_params :show,   { permit: [:id, { hero: {} }] }
  permit_params :search, { permit: [:query, :page, :per_page, { filter: [] }, { sort: [] }] }
  permit_params :create, { required: :hero, permit: [:name, :rank, :lat, :lng] }
  permit_params :update, { expect: { hero: [:id, :name, :rank, :lat, :lng] } }

  def show
    status, content, serializer = Http::ShowHero::Service.(params)
    render json: content, status: status, serializer: serializer
  end
end
```

## Como funciona

- A gem é incluída automaticamente em `ActionController::Base` e
  `ActionController::API` (via Railtie). **Instalar já basta.**
- `permit_params :action, schema` guarda o schema por action.
- No momento em que a action chama `params`, o schema da action é aplicado.
- Actions sem schema continuam recebendo o `params` padrão do framework
  (a menos que você configure `default_schema`/`raise_on_missing_schema`).

## Instalação

### Publicada no Rubygems

```ruby
# Gemfile
gem "permit_params"
```

### Como gem local (path)

```ruby
# Gemfile
gem "permit_params", path: "../permit_params"
```

Depois:

```bash
bundle install
```

Opcionalmente, gere o initializer de configuração:

```bash
rails generate permit_params:install
```

## Formatos de schema

### `permit`

Equivale a `params.permit(*...)`:

```ruby
permit_params :show, { permit: [:id, { hero: {} }] }
# params.permit(:id, hero: {})
```

> `hero: {}` permite **todas** as chaves de dentro de `hero`.
> Para filtrar o conteúdo, liste as chaves: `{ hero: [:name] }`.

### `required` + `permit`

Equivale a `params.required(:chave).permit(*...)`. Como o `require` do Rails
**desembrulha** a chave, o resultado já são os atributos internos:

```ruby
permit_params :create, { required: :hero, permit: [:name, :rank, :lat, :lng] }
# params.required(:hero).permit(:name, :rank, :lat, :lng)
# => params com name/rank/lat/lng no topo
```

### `expect` (Rails 8+)

Equivale a `params.expect(...)`. Quando o schema tem uma única chave raiz, o
Rails também desembrulha o conteúdo:

```ruby
permit_params :update, { expect: { hero: [:id, :name, :rank, :lat, :lng] } }
# params.expect(hero: [:id, :name, :rank, :lat, :lng])
# => params com id/name/rank/lat/lng no topo
```

Para **arrays** de hashes use os colchetes duplos (regra do próprio Rails):

```ruby
permit_params :bulk, { expect: { heroes: [[:id, :name, :rank]] } }
```

### Atalho com array

Um array puro vira um `permit`:

```ruby
permit_params :index, [:page, :per_page]
# o mesmo que permit: [:page, :per_page]
```

## Configuração global

```ruby
# config/initializers/permit_params.rb
PermitParams.configure do |config|
  # Schema aplicado a actions que não declaram o próprio schema.
  # nil (padrão) mantém o params padrão do framework.
  config.default_schema = { permit: [:page, :per_page] }

  # Levanta PermitParams::MissingSchemaError para actions sem schema.
  config.raise_on_missing_schema = false
end
```

## Erros

| Erro                                   | Quando acontece                                                        |
| -------------------------------------- | ---------------------------------------------------------------------- |
| `PermitParams::InvalidSchemaError`     | Schema não é Array nem Hash com `:permit`, `:required` ou `:expect`.   |
| `PermitParams::MissingSchemaError`     | Action sem schema com `raise_on_missing_schema` ligado.                |
| `PermitParams::Error`                  | `expect:` usado em uma versão de Rails sem `Parameters#expect` (< 8.0).|
| `ActionController::ParameterMissing`   | Chave obrigatória ausente (`required`/`expect`).                       |

## Requisitos

- Ruby >= 3.1
- `actionpack`/`activesupport` >= 7.0
- `expect:` exige Rails >= 8.0

## Desenvolvimento

```bash
bundle install
bundle exec rspec
```

### Bump de versão

O bump usa a gem [`gem-release`](https://github.com/svenfuchs/gem-release):

```bash
gem bump --version patch   # 0.1.0 -> 0.1.1
gem bump --version minor   # 0.1.0 -> 0.2.0
gem bump --version major   # 0.1.0 -> 1.0.0
```

Por padrão o bump reescreve `lib/permit_params/version.rb`, faz **commit** da
mudança e **não** faz push nem tag.

O comando `gem bump --version patch --tag --push` faz tudo em sequência:
bump, commit (só do `version.rb`), push do commit, cria a tag anotada
`v<versão>` (a partir da versão do `version.rb`) e faz push das tags. Como a
tag `v*` é enviada, **isso dispara a release**.

> ⚠️ A árvore do git precisa estar **limpa** antes de rodar o bump (ele aborta
> com "Uncommitted changes found"). Como o bump só faz `git add` do
> `version.rb`, o `CHANGELOG.md` precisa já estar commitado — por isso, escreva
> a seção da nova versão e commite antes.

Para saber a próxima versão sem alterar nada:

```bash
gem bump --pretend --no-commit | awk '{ print $4 }'   # -> 0.1.1
```

Fluxo recomendado (o `CHANGELOG.md` precisa estar commitado antes do bump):

```bash
# 1) escreva a seção da nova versão no CHANGELOG.md e commite tudo
git add .
git commit -m "Prepare 0.1.1"

# 2) bump + tag + push (dispara a release) usando a versão explícita
gem bump --version 0.1.1 --tag --push
```

Alternativa com mais controle (separa o push do código da release):

```bash
gem bump --version patch --no-commit        # só edita o version.rb
git add lib/permit_params/version.rb CHANGELOG.md
git commit -m "Prepare 0.1.1"
git push origin main                        # sem release
gem tag --push                              # cria v0.1.1 e empurra -> dispara a release
```

## Licença

MIT.
