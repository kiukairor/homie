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
