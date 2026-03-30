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
