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
