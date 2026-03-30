import pytest

pytestmark = pytest.mark.anyio


async def test_list_items_empty(client):
    resp = await client.get("/api/items")
    assert resp.status_code == 200
    assert resp.json() == []
