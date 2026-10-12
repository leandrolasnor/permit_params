# Changelog

## 0.1.0

- Versão inicial.
- Macro `permit_params` para declarar schemas de parâmetros por action.
- Suporte a `permit`, `required` + `permit` e `expect` (Rails 8).
- Atalho de array para `permit`.
- Configuração global (`default_schema`, `raise_on_missing_schema`) via
  `PermitParams.configure`.
- Generator `permit_params:install`.
- Inclusão automática em `ActionController::Base`/`ActionController::API`
  através de um Railtie.
