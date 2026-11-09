# Homologacao de cadastro publico e recuperacao de senha

## Fluxo entregue, sem habilitacao publica
- A landing e o login so exibem **Criar conta** com `ENABLE_PUBLIC_SIGNUP=true`.
- O formulario inclui um desafio Cloudflare Turnstile com `TURNSTILE_SITE_KEY`.
- O backend valida `turnstile_token` com a chave secreta no Render e envia um link de uso unico por SMTP TLS.
- Clicar no link abre `/verificar-email?token=...`; a pagina exige POST explicito.
- Confirmar e-mail **nao** concede acesso. O ADMIN aprova contrato DEV na aba Clientes e contratos.
- A API recusa contas pendentes, sem contrato, e contratos SAAS que ainda nao tem rotas isoladas.
- Recuperacao de senha so aparece se `ENABLE_PASSWORD_RECOVERY=true` e a API tiver SMTP + antiabuso habilitados.
- Links de reset abrem `/redefinir-senha?token=...`; ao redefinir, o backend incrementa a versao do JWT e invalida sessoes antigas.

## Configuracao necessaria (nenhuma chave neste repositorio)
Backend Render HML (segredos apenas em Environment):
```text
PUBLIC_SIGNUP_ENABLED=false
PASSWORD_RECOVERY_ENABLED=false
SMTP_HOST=<servidor_smtp>
SMTP_PORT=587
SMTP_USERNAME=<usuario_smtp>
SMTP_PASSWORD=<segredo_smtp>
SMTP_FROM_EMAIL=<remetente_verificado>
PUBLIC_APP_BASE_URL=https://<dominio-da-hml>
TURNSTILE_SECRET_KEY=<segredo_turnstile>
TURNSTILE_EXPECTED_HOSTNAME=<dominio-da-hml-sem-https>
```
Frontend Cloudflare Pages (build, NAO adicionar segredo):
```text
--dart-define=ENABLE_PUBLIC_SIGNUP=false
--dart-define=ENABLE_PASSWORD_RECOVERY=false
--dart-define=TURNSTILE_SITE_KEY=<sitekey-publico>
```

## Checkpoints antes de habilitar
1. Migration de auth e tenant aprovada em Postgres descartavel, backup/restore HML e aplicacao controlada com role SQL correta.
2. SMTP de dominio autenticado (SPF, DKIM, DMARC) e link entregue numa conta de teste.
3. Turnstile autorizado para o hostname final no Cloudflare e Siteverify com validacao real da hostname.
4. Cloudflare WAF/rate limit para `POST /auth/login`, `/auth/cadastro`, `/auth/verificacao/reenviar` e `/auth/senha/solicitar`; Turnstile por si so nao e um rate limiter.
5. Contas A/B testadas: pendente nao ve demandas, verificado sem contrato nao ve demandas, contrato DEV aprovado ve apenas seus dados, empresa SAAS pendente nao acessa dashboard.
6. Confirmar regras de protecao de dados, logs sem senha/token, politicas de sessao e backups.

**Nao promover esses PRs para main nem ativar flags antes dos testes em HML.**
