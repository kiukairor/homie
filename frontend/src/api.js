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

export const listItems = api.listItems;
export const createItem = api.createItem;
export const updateItem = api.updateItem;
export const deleteItem = api.deleteItem;
export const deleteChecked = api.deleteChecked;
