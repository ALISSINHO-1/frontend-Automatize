# Pending backend contract: authenticated user identity

## Verified API state

The backend currently exposes `POST /auth/login`. Its response contains only
`access_token` and `token_type`. The JWT contains `sub`, `iat`, and `exp`; it
does not contain the profile. There is no `GET /auth/me` or equivalent current
user route in the inspected backend.

The frontend does not derive the profile from email, password, unvalidated JWT
content, or the demand list. Until the backend returns authenticated identity,
login does not open a dashboard and the received token is discarded. The login
screen reports this dependency.

## Minimum backend contract requested

Add `GET /auth/me`, protected by `Authorization: Bearer <token>`, with a `200`
response in this format:

```json
{
  "id": "<UUID of authenticated user>",
  "perfil": "ADMIN"
}
```

`perfil` must be exactly one persisted value: `ADMIN`, `TECNICO`, or `CLIENTE`.
The endpoint must derive `id`, `perfil`, and active state from the database user
loaded from the validated token's `sub`. It must not accept identity or profile
from the frontend and must not return password hashes or internal fields.

Required responses:

- `401` when the Bearer token is absent, invalid, expired, or belongs to an
  inactive account, consistent with other protected routes.
- `403` when an authenticated account is not allowed to use the application.
- `200` only for an active account with one of the three supported profiles.

After this endpoint is implemented and deployed, the frontend can connect its
`CurrentUserProvider` to exactly `/auth/me` and pair it with secure token storage
to restore a session after application reload. The current default provider
does not request a route that does not exist; tests inject an explicit mock.

## Existing contracts used by the frontend

- `POST /auth/login`: JSON `email` and `senha`; returns token; `401` for invalid
  or inactive accounts and `422` for an invalid body.
- `GET /demandas?offset=0&limit=100`: Bearer required. ADMIN receives all
  demands, TECNICO receives only assigned demands, and CLIENTE receives only
  demands whose `cliente_id` matches the authenticated user. The backend applies
  the scope before pagination.
- `GET /demandas/{id}`: applies the same scope and returns `404` for records
  outside the caller's scope.
- `GET /demandas/{id}/etapas` and `GET /demandas/{id}/historico`: authenticated
  reads limited to the demand's access scope.
- `POST /demandas/{id}/aceite` and `/rejeicao`: the backend authorizes the
  demand's client and validates the state and request body.
- `POST /demandas/{id}/status`, `POST /demandas/{id}/etapas`, and
  `POST /demandas/{id}/etapas/{etapa_id}/conclusao`: available operational
  actions; the backend authorizes ADMIN or the responsible technician and
  validates state transitions.

The demand response exposes client and technician UUIDs, not display names, and
has no due-date field. The admin details screen shows authorized UUIDs. Person
names and deadlines need additional API fields or lookup routes. `/historico`
returns audit actions rather than a dedicated state-transition feed, so the
timeline labels recorded actions.

All demand requests include Bearer authentication. The frontend does not
replicate the backend's ownership filter; the API remains responsible for
effective authorization.
