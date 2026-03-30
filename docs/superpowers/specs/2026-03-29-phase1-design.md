# Phase 1 Design — Homie Shopping List

**Date:** 2026-03-29
**Status:** Approved

---

## Scope

Build the core shopping list CRUD API (FastAPI) and React PWA frontend. Produce ARM64 Docker images pushed to `ghcr.io/kiukairor` via GitHub Actions. No auth, no AI agent, no messaging — those are later phases.

---

## Data Model

Single `items` table in PostgreSQL 15.

| Column       | Type        | Notes                              |
|--------------|-------------|------------------------------------|
| id           | UUID (PK)   | server-generated                   |
| name         | TEXT        | required                           |
| quantity     | TEXT        | e.g. "2", "half a bag"             |
| unit         | TEXT        | e.g. "kg", "pcs", "L" — optional  |
| category     | TEXT        | e.g. "produce", "dairy" — optional |
| checked      | BOOLEAN     | default false                      |
| created_at   | TIMESTAMPTZ | default now()                      |

No foreign keys, no user table. Single household.

---

## Backend (FastAPI)

**Image:** `ghcr.io/kiukairor/homie-backend:latest`
**Port:** 8000
**Runtime deps:** Python 3.11, SQLAlchemy 2 async, asyncpg, Alembic, Pydantic v2, uvicorn

### Endpoints

| Method | Path                  | Description                        |
|--------|-----------------------|------------------------------------|
| GET    | /api/health           | Readiness probe — returns `{"status":"ok"}` |
| GET    | /api/items            | List items; optional `?checked=false` filter |
| POST   | /api/items            | Create item                        |
| PATCH  | /api/items/{id}       | Update item (any fields)           |
| DELETE | /api/items/{id}       | Delete single item                 |
| DELETE | /api/items/checked    | Bulk-delete all checked items      |

### Structure

```
backend/
├── Dockerfile
├── requirements.txt
├── main.py               # app factory, CORS, router mount
├── db/
│   ├── session.py        # async engine + session factory
│   └── migrations/       # Alembic env + versions
├── models/
│   └── item.py           # SQLAlchemy ORM model
└── routers/
    └── items.py          # all /api/items routes + schemas
```

CORS allows all origins in Phase 1 (tightened later). DB URL from `DATABASE_URL` env var. On startup, Alembic runs `upgrade head` automatically.

---

## Frontend (React PWA)

**Image:** `ghcr.io/kiukairor/homie-frontend:latest`
**Port:** 80 (Nginx)
**Build deps:** Node 20, Vite, React 18

### Features

- Single-page app — shopping list grouped by category
- Add item form (name, quantity, unit, category)
- Check off items (struck-through)
- Delete individual items
- "Clear checked" button
- PWA manifest + service worker (Vite PWA plugin) for installability
- Calls `/api/*` (same origin via Traefik ingress)

### Structure

```
frontend/
├── Dockerfile
├── index.html
├── vite.config.js
├── package.json
└── src/
    ├── main.jsx
    ├── App.jsx
    ├── api.js            # fetch wrappers for all endpoints
    └── components/
        ├── AddItemForm.jsx
        ├── ItemList.jsx
        └── ItemRow.jsx
```

---

## Docker & CI

### Dockerfiles

- `backend/Dockerfile`: python:3.11-slim, installs requirements, copies app, runs `uvicorn main:app --host 0.0.0.0 --port 8000`
- `frontend/Dockerfile`: multi-stage — node:20-alpine builds, nginx:alpine serves from `/usr/share/nginx/html`

Both produce `linux/arm64` images via GitHub Actions QEMU + buildx.

### GitHub Actions

`.github/workflows/build.yml`:
- Trigger: push to `main`
- Jobs: build-backend, build-frontend (parallel)
- Steps: checkout → QEMU → buildx → login ghcr.io → build+push
- Tags: `ghcr.io/kiukairor/homie-backend:latest`, `ghcr.io/kiukairor/homie-frontend:latest`

---

## Database Password

Generated and committed as a note for cluster setup. The value `homie_dev_pw_2026` is used as the example in setup docs. The actual cluster secret is created manually:

```bash
kubectl create secret generic homie-secrets \
  --from-literal=postgres-password=homie_dev_pw_2026 \
  -n homie-prod
```

---

## Out of Scope (Phase 1)

- Authentication / multi-user
- AI agent (Ollama / Claude)
- Telegram / WhatsApp bot
- Habit learning / pantry inference
- Recipe suggestions
