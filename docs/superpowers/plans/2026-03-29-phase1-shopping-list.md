# Phase 1 Shopping List Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a FastAPI shopping list CRUD API and React PWA frontend, containerised as ARM64 Docker images pushed to ghcr.io/kiukairor via GitHub Actions.

**Architecture:** FastAPI backend with SQLAlchemy 2 async + asyncpg talking to PostgreSQL; React 18 / Vite frontend served by Nginx. Alembic runs migrations on startup. GitHub Actions builds both images as linux/arm64 on every push to main.

**Tech Stack:** Python 3.11, FastAPI, SQLAlchemy 2 async, asyncpg, Alembic, Pydantic v2, uvicorn, pytest, httpx, aiosqlite; React 18, Vite, vite-plugin-pwa, Nginx; Docker buildx, GitHub Actions.

---

## File Map

```
backend/
  Dockerfile
  requirements.txt
  main.py                          # app factory, CORS, lifespan (runs migrations)
  db/
    __init__.py
    session.py                     # async engine + SessionLocal
  models/
    __init__.py
    item.py                        # SQLAlchemy Item ORM model
  routers/
    __init__.py
    items.py                       # all /api/items routes + Pydantic schemas
  alembic.ini
  alembic/
    env.py
    versions/
      0001_create_items_table.py
  tests/
    __init__.py
    conftest.py                    # test app + async client fixture
    test_health.py
    test_items.py

frontend/
  Dockerfile
  nginx.conf
  package.json
  vite.config.js
  index.html
  public/
    manifest.json
  src/
    main.jsx
    App.jsx
    api.js                         # fetch wrappers for all endpoints
    components/
      AddItemForm.jsx
      ItemList.jsx
      ItemRow.jsx

.github/
  workflows/
    build.yml                      # build + push ARM64 images to ghcr.io
```

---

## Task 1: Backend dependencies and project skeleton

**Files:**
- Create: `backend/requirements.txt`
- Create: `backend/db/__init__.py`
- Create: `backend/models/__init__.py`
- Create: `backend/routers/__init__.py`

- [ ] **Step 1: Create requirements.txt**

```
fastapi==0.111.0
uvicorn[standard]==0.29.0
sqlalchemy[asyncio]==2.0.30
asyncpg==0.29.0
alembic==1.13.1
pydantic==2.7.1
python-dotenv==1.0.1

# test
pytest==8.2.0
pytest-anyio==0.0.0
anyio[trio]==4.3.0
httpx==0.27.0
aiosqlite==0.20.0
```

- [ ] **Step 2: Create empty __init__.py files**

```bash
mkdir -p /home/ubuntu/src/backend/db \
         /home/ubuntu/src/backend/models \
         /home/ubuntu/src/backend/routers \
         /home/ubuntu/src/backend/tests \
         /home/ubuntu/src/backend/alembic/versions
touch /home/ubuntu/src/backend/db/__init__.py \
      /home/ubuntu/src/backend/models/__init__.py \
      /home/ubuntu/src/backend/routers/__init__.py \
      /home/ubuntu/src/backend/tests/__init__.py
```

- [ ] **Step 3: Install dependencies into a venv**

```bash
cd /home/ubuntu/src/backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Expected: no errors, packages installed.

- [ ] **Step 4: Commit skeleton**

```bash
cd /home/ubuntu/src
git add backend/requirements.txt backend/db/__init__.py backend/models/__init__.py backend/routers/__init__.py backend/tests/__init__.py
git commit -m "chore: backend skeleton and requirements"
```

---

## Task 2: Item model and DB session

**Files:**
- Create: `backend/db/session.py`
- Create: `backend/models/item.py`

- [ ] **Step 1: Write the failing test**

Create `backend/tests/conftest.py`:

```python
import pytest
import pytest_anyio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.pool import StaticPool

TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"


@pytest.fixture(scope="session")
def anyio_backend():
    return "asyncio"


@pytest.fixture(scope="session")
async def engine():
    engine = create_async_engine(
        TEST_DATABASE_URL,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    async with engine.begin() as conn:
        from backend.models.item import Base
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest.fixture
async def db_session(engine):
    Session = async_sessionmaker(engine, expire_on_commit=False)
    async with Session() as session:
        yield session
        await session.rollback()


@pytest.fixture
async def client(engine):
    from backend.main import create_app
    from backend.db.session import get_session

    Session = async_sessionmaker(engine, expire_on_commit=False)

    async def override_get_session():
        async with Session() as session:
            yield session

    app = create_app()
    app.dependency_overrides[get_session] = override_get_session

    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        yield ac
```

Create `backend/tests/test_items.py` with first failing test:

```python
import pytest

pytestmark = pytest.mark.anyio


async def test_list_items_empty(client):
    resp = await client.get("/api/items")
    assert resp.status_code == 200
    assert resp.json() == []
```

- [ ] **Step 2: Create db/session.py**

```python
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from typing import AsyncGenerator
import os

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./homie.db")

engine = create_async_engine(DATABASE_URL, echo=False)
SessionLocal = async_sessionmaker(engine, expire_on_commit=False)


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    async with SessionLocal() as session:
        yield session
```

- [ ] **Step 3: Create models/item.py**

```python
import uuid
from datetime import datetime, timezone
from sqlalchemy import String, Boolean, DateTime
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class Item(Base):
    __tablename__ = "items"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name: Mapped[str] = mapped_column(String, nullable=False)
    quantity: Mapped[str] = mapped_column(String, nullable=False, default="1")
    unit: Mapped[str | None] = mapped_column(String, nullable=True)
    category: Mapped[str | None] = mapped_column(String, nullable=True)
    checked: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
```

- [ ] **Step 4: Create minimal main.py so conftest import works**

```python
from fastapi import FastAPI
from backend.db.session import get_session  # noqa: F401 – used in DI override


def create_app() -> FastAPI:
    app = FastAPI(title="Homie API")
    return app
```

- [ ] **Step 5: Run test to verify it fails for the right reason**

```bash
cd /home/ubuntu/src/backend
source .venv/bin/activate
python -m pytest tests/test_items.py::test_list_items_empty -v
```

Expected: FAIL — `404 Not Found` (route doesn't exist yet) or import error if something is missing.

- [ ] **Step 6: Commit**

```bash
cd /home/ubuntu/src
git add backend/db/session.py backend/models/item.py backend/tests/conftest.py backend/tests/test_items.py
git commit -m "feat: Item model and DB session"
```

---

## Task 3: Items router — all CRUD endpoints

**Files:**
- Create: `backend/routers/items.py`

- [ ] **Step 1: Add remaining tests to test_items.py**

Replace `backend/tests/test_items.py` with:

```python
import pytest

pytestmark = pytest.mark.anyio


async def test_list_items_empty(client):
    resp = await client.get("/api/items")
    assert resp.status_code == 200
    assert resp.json() == []


async def test_create_item(client):
    resp = await client.post("/api/items", json={"name": "Milk", "quantity": "2", "unit": "L"})
    assert resp.status_code == 201
    data = resp.json()
    assert data["name"] == "Milk"
    assert data["quantity"] == "2"
    assert data["unit"] == "L"
    assert data["checked"] is False
    assert "id" in data
    assert "created_at" in data


async def test_list_items_after_create(client):
    await client.post("/api/items", json={"name": "Eggs", "quantity": "12", "category": "dairy"})
    resp = await client.get("/api/items")
    assert resp.status_code == 200
    names = [i["name"] for i in resp.json()]
    assert "Eggs" in names


async def test_list_items_filter_checked(client):
    r1 = await client.post("/api/items", json={"name": "Bread", "quantity": "1"})
    item_id = r1.json()["id"]
    await client.patch(f"/api/items/{item_id}", json={"checked": True})

    resp = await client.get("/api/items?checked=false")
    assert all(not i["checked"] for i in resp.json())


async def test_patch_item(client):
    r = await client.post("/api/items", json={"name": "Butter", "quantity": "1"})
    item_id = r.json()["id"]

    resp = await client.patch(f"/api/items/{item_id}", json={"checked": True, "quantity": "2"})
    assert resp.status_code == 200
    assert resp.json()["checked"] is True
    assert resp.json()["quantity"] == "2"


async def test_patch_item_not_found(client):
    resp = await client.patch("/api/items/nonexistent-id", json={"checked": True})
    assert resp.status_code == 404


async def test_delete_item(client):
    r = await client.post("/api/items", json={"name": "Cheese", "quantity": "1"})
    item_id = r.json()["id"]

    resp = await client.delete(f"/api/items/{item_id}")
    assert resp.status_code == 204

    resp2 = await client.get("/api/items")
    ids = [i["id"] for i in resp2.json()]
    assert item_id not in ids


async def test_delete_item_not_found(client):
    resp = await client.delete("/api/items/nonexistent-id")
    assert resp.status_code == 404


async def test_delete_checked_items(client):
    r1 = await client.post("/api/items", json={"name": "Apple", "quantity": "3"})
    r2 = await client.post("/api/items", json={"name": "Orange", "quantity": "2"})
    id1 = r1.json()["id"]
    await client.patch(f"/api/items/{id1}", json={"checked": True})

    resp = await client.delete("/api/items/checked")
    assert resp.status_code == 204

    remaining = [i["id"] for i in (await client.get("/api/items")).json()]
    assert id1 not in remaining
    assert r2.json()["id"] in remaining
```

- [ ] **Step 2: Run tests to confirm they all fail**

```bash
cd /home/ubuntu/src/backend
source .venv/bin/activate
python -m pytest tests/test_items.py -v
```

Expected: multiple FAILs — routes not yet implemented.

- [ ] **Step 3: Create routers/items.py**

```python
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
from datetime import datetime

from backend.db.session import get_session
from backend.models.item import Item

router = APIRouter(prefix="/api/items", tags=["items"])


class ItemCreate(BaseModel):
    name: str
    quantity: str = "1"
    unit: Optional[str] = None
    category: Optional[str] = None


class ItemUpdate(BaseModel):
    name: Optional[str] = None
    quantity: Optional[str] = None
    unit: Optional[str] = None
    category: Optional[str] = None
    checked: Optional[bool] = None


class ItemResponse(BaseModel):
    id: str
    name: str
    quantity: str
    unit: Optional[str]
    category: Optional[str]
    checked: bool
    created_at: datetime

    model_config = {"from_attributes": True}


@router.get("", response_model=list[ItemResponse])
async def list_items(
    checked: Optional[bool] = None,
    session: AsyncSession = Depends(get_session),
):
    stmt = select(Item).order_by(Item.created_at)
    if checked is not None:
        stmt = stmt.where(Item.checked == checked)
    result = await session.execute(stmt)
    return result.scalars().all()


@router.post("", response_model=ItemResponse, status_code=201)
async def create_item(body: ItemCreate, session: AsyncSession = Depends(get_session)):
    item = Item(**body.model_dump())
    session.add(item)
    await session.commit()
    await session.refresh(item)
    return item


@router.patch("/{item_id}", response_model=ItemResponse)
async def update_item(
    item_id: str,
    body: ItemUpdate,
    session: AsyncSession = Depends(get_session),
):
    item = await session.get(Item, item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(item, field, value)
    await session.commit()
    await session.refresh(item)
    return item


@router.delete("/checked", status_code=204)
async def delete_checked(session: AsyncSession = Depends(get_session)):
    await session.execute(delete(Item).where(Item.checked == True))  # noqa: E712
    await session.commit()
    return Response(status_code=204)


@router.delete("/{item_id}", status_code=204)
async def delete_item(item_id: str, session: AsyncSession = Depends(get_session)):
    item = await session.get(Item, item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    await session.delete(item)
    await session.commit()
    return Response(status_code=204)
```

- [ ] **Step 4: Update main.py to include the router**

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.db.session import get_session  # noqa: F401 – used in DI override
from backend.routers.items import router as items_router


def create_app() -> FastAPI:
    app = FastAPI(title="Homie API")

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(items_router)

    @app.get("/api/health")
    async def health():
        return {"status": "ok"}

    return app


app = create_app()
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
cd /home/ubuntu/src/backend
source .venv/bin/activate
python -m pytest tests/ -v
```

Expected: all PASS.

- [ ] **Step 6: Commit**

```bash
cd /home/ubuntu/src
git add backend/routers/items.py backend/main.py backend/tests/test_items.py
git commit -m "feat: items CRUD router and health endpoint"
```

---

## Task 4: Health endpoint test

**Files:**
- Create: `backend/tests/test_health.py`

- [ ] **Step 1: Write test**

```python
import pytest

pytestmark = pytest.mark.anyio


async def test_health(client):
    resp = await client.get("/api/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}
```

- [ ] **Step 2: Run test**

```bash
cd /home/ubuntu/src/backend
source .venv/bin/activate
python -m pytest tests/test_health.py -v
```

Expected: PASS.

- [ ] **Step 3: Commit**

```bash
cd /home/ubuntu/src
git add backend/tests/test_health.py
git commit -m "test: health endpoint"
```

---

## Task 5: Alembic migrations

**Files:**
- Create: `backend/alembic.ini`
- Create: `backend/alembic/env.py`
- Create: `backend/alembic/script.py.mako`
- Create: `backend/alembic/versions/0001_create_items_table.py`

- [ ] **Step 1: Create alembic.ini**

```ini
[alembic]
script_location = alembic
prepend_sys_path = .
sqlalchemy.url = placeholder

[loggers]
keys = root,sqlalchemy,alembic

[handlers]
keys = console

[formatters]
keys = generic

[logger_root]
level = WARN
handlers = console
qualname =

[logger_sqlalchemy]
level = WARN
handlers =
qualname = sqlalchemy.engine

[logger_alembic]
level = INFO
handlers =
qualname = alembic

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[formatter_generic]
format = %(levelname)-5.5s [%(name)s] %(message)s
datefmt = %H:%M:%S
```

- [ ] **Step 2: Create alembic/env.py**

```python
import asyncio
import os
from logging.config import fileConfig

from sqlalchemy import pool
from sqlalchemy.ext.asyncio import create_async_engine

from alembic import context

config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

from backend.models.item import Base  # noqa: E402
target_metadata = Base.metadata


def get_url():
    return os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./homie.db")


def run_migrations_offline() -> None:
    url = get_url()
    context.configure(url=url, target_metadata=target_metadata, literal_binds=True)
    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection):
    context.configure(connection=connection, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    engine = create_async_engine(get_url(), poolclass=pool.NullPool)
    async with engine.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await engine.dispose()


def run_migrations_online() -> None:
    asyncio.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
```

- [ ] **Step 3: Create alembic/script.py.mako**

```
"""${message}

Revision ID: ${up_revision}
Revises: ${down_revision | comma,n}
Create Date: ${create_date}

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
${imports if imports else ""}

revision: str = ${repr(up_revision)}
down_revision: Union[str, None] = ${repr(down_revision)}
branch_labels: Union[str, Sequence[str], None] = ${repr(branch_labels)}
depends_on: Union[str, Sequence[str], None] = ${repr(depends_on)}


def upgrade() -> None:
    ${upgrades if upgrades else "pass"}


def downgrade() -> None:
    ${downgrades if downgrades else "pass"}
```

- [ ] **Step 4: Create migration 0001**

```python
# backend/alembic/versions/0001_create_items_table.py
"""create items table

Revision ID: 0001
Revises:
Create Date: 2026-03-29
"""
from alembic import op
import sqlalchemy as sa

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "items",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("name", sa.String(), nullable=False),
        sa.Column("quantity", sa.String(), nullable=False, server_default="1"),
        sa.Column("unit", sa.String(), nullable=True),
        sa.Column("category", sa.String(), nullable=True),
        sa.Column("checked", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.PrimaryKeyConstraint("id"),
    )


def downgrade() -> None:
    op.drop_table("items")
```

- [ ] **Step 5: Update main.py lifespan to run migrations on startup**

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import subprocess
import sys

from backend.db.session import get_session  # noqa: F401
from backend.routers.items import router as items_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    subprocess.run(
        [sys.executable, "-m", "alembic", "upgrade", "head"],
        check=True,
        cwd="/app",
    )
    yield


def create_app() -> FastAPI:
    app = FastAPI(title="Homie API", lifespan=lifespan)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(items_router)

    @app.get("/api/health")
    async def health():
        return {"status": "ok"}

    return app


app = create_app()
```

- [ ] **Step 6: Run all tests to confirm nothing broken**

```bash
cd /home/ubuntu/src/backend
source .venv/bin/activate
python -m pytest tests/ -v
```

Expected: all PASS (conftest creates tables directly via SQLAlchemy metadata, bypassing migrations in tests — that's correct).

- [ ] **Step 7: Commit**

```bash
cd /home/ubuntu/src
git add backend/alembic.ini backend/alembic/
git add backend/main.py
git commit -m "feat: Alembic migrations, run on startup"
```

---

## Task 6: Backend Dockerfile

**Files:**
- Create: `backend/Dockerfile`

- [ ] **Step 1: Create Dockerfile**

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV DATABASE_URL=""
ENV REDIS_URL=""
ENV OLLAMA_BASE_URL=""
ENV ANTHROPIC_API_KEY=""

EXPOSE 8000

CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

- [ ] **Step 2: Verify build locally (optional — skip if no Docker)**

```bash
cd /home/ubuntu/src/backend
docker build -t homie-backend-test . && echo "Build OK"
```

Expected: Build OK (or skip if Docker not available; CI will validate).

- [ ] **Step 3: Commit**

```bash
cd /home/ubuntu/src
git add backend/Dockerfile
git commit -m "feat: backend Dockerfile"
```

---

## Task 7: Frontend scaffold

**Files:**
- Create: `frontend/package.json`
- Create: `frontend/vite.config.js`
- Create: `frontend/index.html`
- Create: `frontend/public/manifest.json`
- Create: `frontend/src/main.jsx`

- [ ] **Step 1: Create package.json**

```json
{
  "name": "homie-frontend",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.3.0",
    "vite": "^5.2.11",
    "vite-plugin-pwa": "^0.20.0"
  }
}
```

- [ ] **Step 2: Create vite.config.js**

```js
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { VitePWA } from "vite-plugin-pwa";

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: "autoUpdate",
      manifest: {
        name: "Homie",
        short_name: "Homie",
        description: "Smart household shopping list",
        theme_color: "#1a73e8",
        background_color: "#ffffff",
        display: "standalone",
        start_url: "/",
        icons: [
          { src: "/icon-192.png", sizes: "192x192", type: "image/png" },
          { src: "/icon-512.png", sizes: "512x512", type: "image/png" }
        ]
      }
    }),
  ],
  server: {
    proxy: {
      "/api": "http://localhost:8000",
    },
  },
});
```

- [ ] **Step 3: Create index.html**

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Homie</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
```

- [ ] **Step 4: Create src/main.jsx**

```jsx
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App.jsx";

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

- [ ] **Step 5: Create public/manifest.json (fallback for older browsers)**

```json
{
  "name": "Homie",
  "short_name": "Homie",
  "description": "Smart household shopping list",
  "theme_color": "#1a73e8",
  "background_color": "#ffffff",
  "display": "standalone",
  "start_url": "/",
  "icons": [
    { "src": "/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icon-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
```

- [ ] **Step 6: Install dependencies**

```bash
cd /home/ubuntu/src/frontend
npm install
```

Expected: node_modules created, no errors.

- [ ] **Step 7: Commit**

```bash
cd /home/ubuntu/src
git add frontend/package.json frontend/vite.config.js frontend/index.html frontend/public/manifest.json frontend/src/main.jsx frontend/package-lock.json
git commit -m "feat: frontend scaffold (Vite + React + PWA)"
```

---

## Task 8: API client

**Files:**
- Create: `frontend/src/api.js`

- [ ] **Step 1: Create api.js**

```js
const BASE = "/api";

async function request(path, options = {}) {
  const res = await fetch(`${BASE}${path}`, {
    headers: { "Content-Type": "application/json", ...options.headers },
    ...options,
  });
  if (res.status === 204) return null;
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`${res.status}: ${err}`);
  }
  return res.json();
}

export const api = {
  listItems: (checked) =>
    request(`/items${checked !== undefined ? `?checked=${checked}` : ""}`),
  createItem: (item) =>
    request("/items", { method: "POST", body: JSON.stringify(item) }),
  updateItem: (id, patch) =>
    request(`/items/${id}`, { method: "PATCH", body: JSON.stringify(patch) }),
  deleteItem: (id) =>
    request(`/items/${id}`, { method: "DELETE" }),
  deleteChecked: () =>
    request("/items/checked", { method: "DELETE" }),
};
```

- [ ] **Step 2: Commit**

```bash
cd /home/ubuntu/src
git add frontend/src/api.js
git commit -m "feat: frontend API client"
```

---

## Task 9: React components

**Files:**
- Create: `frontend/src/components/AddItemForm.jsx`
- Create: `frontend/src/components/ItemRow.jsx`
- Create: `frontend/src/components/ItemList.jsx`
- Create: `frontend/src/App.jsx`

- [ ] **Step 1: Create AddItemForm.jsx**

```jsx
import { useState } from "react";

const CATEGORIES = ["produce", "dairy", "meat", "bakery", "frozen", "drinks", "other"];

export default function AddItemForm({ onAdd }) {
  const [name, setName] = useState("");
  const [quantity, setQuantity] = useState("1");
  const [unit, setUnit] = useState("");
  const [category, setCategory] = useState("");

  async function handleSubmit(e) {
    e.preventDefault();
    if (!name.trim()) return;
    await onAdd({ name: name.trim(), quantity, unit: unit || undefined, category: category || undefined });
    setName("");
    setQuantity("1");
    setUnit("");
    setCategory("");
  }

  return (
    <form onSubmit={handleSubmit} style={{ display: "flex", gap: 8, flexWrap: "wrap", marginBottom: 16 }}>
      <input
        value={name}
        onChange={(e) => setName(e.target.value)}
        placeholder="Item name"
        required
        style={{ flex: "2 1 140px", padding: "8px 12px", borderRadius: 6, border: "1px solid #ccc" }}
      />
      <input
        value={quantity}
        onChange={(e) => setQuantity(e.target.value)}
        placeholder="Qty"
        style={{ flex: "0 1 60px", padding: "8px 12px", borderRadius: 6, border: "1px solid #ccc" }}
      />
      <input
        value={unit}
        onChange={(e) => setUnit(e.target.value)}
        placeholder="Unit"
        style={{ flex: "0 1 60px", padding: "8px 12px", borderRadius: 6, border: "1px solid #ccc" }}
      />
      <select
        value={category}
        onChange={(e) => setCategory(e.target.value)}
        style={{ flex: "1 1 100px", padding: "8px 12px", borderRadius: 6, border: "1px solid #ccc" }}
      >
        <option value="">Category</option>
        {CATEGORIES.map((c) => <option key={c} value={c}>{c}</option>)}
      </select>
      <button
        type="submit"
        style={{ flex: "0 0 auto", padding: "8px 20px", background: "#1a73e8", color: "#fff", border: "none", borderRadius: 6, cursor: "pointer" }}
      >
        Add
      </button>
    </form>
  );
}
```

- [ ] **Step 2: Create ItemRow.jsx**

```jsx
export default function ItemRow({ item, onToggle, onDelete }) {
  return (
    <li style={{
      display: "flex",
      alignItems: "center",
      gap: 10,
      padding: "10px 0",
      borderBottom: "1px solid #eee",
      opacity: item.checked ? 0.5 : 1,
    }}>
      <input
        type="checkbox"
        checked={item.checked}
        onChange={() => onToggle(item)}
        style={{ width: 18, height: 18, cursor: "pointer" }}
      />
      <span style={{ flex: 1, textDecoration: item.checked ? "line-through" : "none" }}>
        <strong>{item.name}</strong>
        {" "}
        <span style={{ color: "#555", fontSize: 14 }}>
          {item.quantity}{item.unit ? ` ${item.unit}` : ""}
        </span>
      </span>
      {item.category && (
        <span style={{
          fontSize: 11, padding: "2px 8px", borderRadius: 12,
          background: "#e8f0fe", color: "#1a73e8"
        }}>
          {item.category}
        </span>
      )}
      <button
        onClick={() => onDelete(item.id)}
        style={{ background: "none", border: "none", color: "#d93025", cursor: "pointer", fontSize: 18 }}
        aria-label="Delete"
      >
        ×
      </button>
    </li>
  );
}
```

- [ ] **Step 3: Create ItemList.jsx**

```jsx
import ItemRow from "./ItemRow.jsx";

export default function ItemList({ items, onToggle, onDelete }) {
  if (items.length === 0) {
    return <p style={{ color: "#999", textAlign: "center", padding: 32 }}>Your list is empty. Add something above!</p>;
  }

  const grouped = items.reduce((acc, item) => {
    const key = item.category || "other";
    if (!acc[key]) acc[key] = [];
    acc[key].push(item);
    return acc;
  }, {});

  return (
    <div>
      {Object.entries(grouped).map(([category, categoryItems]) => (
        <div key={category}>
          <h3 style={{ fontSize: 13, textTransform: "uppercase", color: "#888", margin: "16px 0 4px", letterSpacing: 1 }}>
            {category}
          </h3>
          <ul style={{ listStyle: "none", margin: 0, padding: 0 }}>
            {categoryItems.map((item) => (
              <ItemRow key={item.id} item={item} onToggle={onToggle} onDelete={onDelete} />
            ))}
          </ul>
        </div>
      ))}
    </div>
  );
}
```

- [ ] **Step 4: Create App.jsx**

```jsx
import { useState, useEffect, useCallback } from "react";
import { api } from "./api.js";
import AddItemForm from "./components/AddItemForm.jsx";
import ItemList from "./components/ItemList.jsx";

export default function App() {
  const [items, setItems] = useState([]);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  const loadItems = useCallback(async () => {
    try {
      const data = await api.listItems();
      setItems(data);
      setError(null);
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { loadItems(); }, [loadItems]);

  async function handleAdd(item) {
    try {
      const created = await api.createItem(item);
      setItems((prev) => [...prev, created]);
    } catch (e) {
      setError(e.message);
    }
  }

  async function handleToggle(item) {
    try {
      const updated = await api.updateItem(item.id, { checked: !item.checked });
      setItems((prev) => prev.map((i) => (i.id === updated.id ? updated : i)));
    } catch (e) {
      setError(e.message);
    }
  }

  async function handleDelete(id) {
    try {
      await api.deleteItem(id);
      setItems((prev) => prev.filter((i) => i.id !== id));
    } catch (e) {
      setError(e.message);
    }
  }

  async function handleClearChecked() {
    try {
      await api.deleteChecked();
      setItems((prev) => prev.filter((i) => !i.checked));
    } catch (e) {
      setError(e.message);
    }
  }

  const checkedCount = items.filter((i) => i.checked).length;

  return (
    <div style={{ maxWidth: 600, margin: "0 auto", padding: "24px 16px", fontFamily: "system-ui, sans-serif" }}>
      <header style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 24 }}>
        <h1 style={{ margin: 0, fontSize: 28, color: "#1a73e8" }}>Homie</h1>
        {checkedCount > 0 && (
          <button
            onClick={handleClearChecked}
            style={{ padding: "6px 14px", background: "#d93025", color: "#fff", border: "none", borderRadius: 6, cursor: "pointer" }}
          >
            Clear {checkedCount} checked
          </button>
        )}
      </header>

      <AddItemForm onAdd={handleAdd} />

      {error && (
        <div style={{ padding: 12, background: "#fce8e6", color: "#d93025", borderRadius: 6, marginBottom: 16 }}>
          {error}
        </div>
      )}

      {loading ? (
        <p style={{ textAlign: "center", color: "#999" }}>Loading...</p>
      ) : (
        <ItemList items={items} onToggle={handleToggle} onDelete={handleDelete} />
      )}
    </div>
  );
}
```

- [ ] **Step 5: Verify frontend builds**

```bash
cd /home/ubuntu/src/frontend
npm run build
```

Expected: `dist/` folder created, no errors.

- [ ] **Step 6: Commit**

```bash
cd /home/ubuntu/src
git add frontend/src/App.jsx frontend/src/components/
git commit -m "feat: React PWA components and App"
```

---

## Task 10: Frontend Dockerfile and Nginx config

**Files:**
- Create: `frontend/nginx.conf`
- Create: `frontend/Dockerfile`

- [ ] **Step 1: Create nginx.conf**

```nginx
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Serve static assets with long cache
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff2?)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # SPA fallback — all routes serve index.html
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

- [ ] **Step 2: Create Dockerfile**

```dockerfile
# Build stage
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Serve stage
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

- [ ] **Step 3: Commit**

```bash
cd /home/ubuntu/src
git add frontend/Dockerfile frontend/nginx.conf
git commit -m "feat: frontend Dockerfile and Nginx config"
```

---

## Task 11: GitHub Actions CI — build and push ARM64 images

**Files:**
- Create: `.github/workflows/build.yml`

- [ ] **Step 1: Create .github/workflows/build.yml**

```yaml
name: Build and push Docker images

on:
  push:
    branches: [main]

jobs:
  build-backend:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push backend
        uses: docker/build-push-action@v5
        with:
          context: ./backend
          platforms: linux/arm64
          push: true
          tags: ghcr.io/kiukairor/homie-backend:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max

  build-frontend:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push frontend
        uses: docker/build-push-action@v5
        with:
          context: ./frontend
          platforms: linux/arm64
          push: true
          tags: ghcr.io/kiukairor/homie-frontend:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

- [ ] **Step 2: Commit**

```bash
cd /home/ubuntu/src
mkdir -p .github/workflows
git add .github/workflows/build.yml
git commit -m "ci: GitHub Actions build and push ARM64 images"
```

---

## Task 12: Configure git remote with token and push

- [ ] **Step 1: Configure git remote to use token for push**

```bash
cd /home/ubuntu/src
git remote set-url origin https://kiukairor:${GITHUB_TOKEN}@github.com/kiukairor/homie.git
git config user.email "homie-bot@kiukairor.dev"
git config user.name "Homie Bot"
```

- [ ] **Step 2: Push to main**

```bash
cd /home/ubuntu/src
git push origin main
```

Expected: push succeeds, GitHub Actions triggered.

- [ ] **Step 3: Verify CI triggered**

```bash
gh run list --repo kiukairor/homie --limit 5
```

Expected: a `Build and push Docker images` run is listed as `in_progress` or `queued`.

---

## Setup Note for Cluster

When ready to deploy, create the k8s secret:

```bash
kubectl create secret generic homie-secrets \
  --from-literal=postgres-password=homie_dev_pw_2026 \
  -n homie-prod
```

Then apply ArgoCD app:

```bash
kubectl apply -f argocd/application.yaml
```
