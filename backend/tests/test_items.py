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
