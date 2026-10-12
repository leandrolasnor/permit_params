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

## Migrando do `BaseController`

Antes (implementação manual):

```ruby
class BaseController < ApplicationController
  class_attribute :param_schemas, default: {}

  class << self
    def permit_params(action, schema)
      param_schemas[action.to_sym] = schema
    end
  end

  private

  def params
    schema = self.class.param_schemas[action_name.to_sym]
    return super unless schema
    # ...
  end
end
```

Depois (com a gem instalada, o `BaseController` pode ficar vazio ou ser removido):

```ruby
class BaseController < ApplicationController
end
```

> Bônus: a implementação manual mutava o mesmo Hash compartilhado entre todos
> os controllers (schemas vazavam de um controller para o outro). A gem usa
> `merge`, então cada controller tem seu próprio conjunto de schemas.

## Requisitos

- Ruby >= 3.1
- `actionpack`/`activesupport` >= 7.0
- `expect:` exige Rails >= 8.0

## Desenvolvimento

```bash
bundle install
bundle exec rspec
```

## Licença

MIT.
