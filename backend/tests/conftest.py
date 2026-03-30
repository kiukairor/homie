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
