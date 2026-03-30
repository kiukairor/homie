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
