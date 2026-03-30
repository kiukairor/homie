from fastapi import FastAPI
from backend.db.session import get_session  # noqa: F401 – used in DI override


def create_app() -> FastAPI:
    app = FastAPI(title="Homie API")
    return app


app = create_app()
