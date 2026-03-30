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
