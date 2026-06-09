interface VehicleCardProps {
  id: string;
  name: string;
  type: string;
  speed: number;
  handling: number;
  durability: number;
  selected: boolean;
  color: string;
  onClick: () => void;
}

const SHAPES: Record<string, string> = {
  sedan: "M4,26 L10,14 L20,10 L40,10 L46,14 L46,26 Z",
  suv: "M2,27 L8,12 L20,8 L42,8 L48,12 L48,27 Z",
  sports: "M2,25 L10,13 L22,9 L44,9 L48,17 L48,25 Z",
  truck: "M2,28 L2,10 L22,10 L22,14 L46,14 L48,14 L48,28 Z",
};

function StatBar({ value, color }: { value: number; color: string }) {
  return (
    <div className="flex items-center gap-1.5">
      {[1, 2, 3, 4, 5].map(i => (
        <div
          key={i}
          className="h-1.5 flex-1 transition-all"
          style={{
            background: i <= Math.round(value / 20) ? color : "rgba(255,255,255,0.1)",
            clipPath: "polygon(2px 0%, 100% 0%, calc(100% - 2px) 100%, 0% 100%)",
          }}
        />
      ))}
    </div>
  );
}

export function VehicleCard({ id, name, type, speed, handling, durability, selected, color, onClick }: VehicleCardProps) {
  return (
    <button
      onClick={onClick}
      className="relative w-full text-left transition-all duration-200 group"
      style={{
        background: selected ? "rgba(200,255,0,0.06)" : "rgba(255,255,255,0.02)",
        border: `1px solid ${selected ? "rgba(200,255,0,0.4)" : "rgba(255,255,255,0.06)"}`,
        clipPath: "polygon(12px 0%, 100% 0%, calc(100% - 12px) 100%, 0% 100%)",
        padding: "12px 16px",
      }}
    >
      {selected && (
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            background: "linear-gradient(135deg, rgba(200,255,0,0.05) 0%, transparent 60%)",
            clipPath: "polygon(12px 0%, 100% 0%, calc(100% - 12px) 100%, 0% 100%)",
          }}
        />
      )}

      <div className="flex items-center gap-3">
        {/* Vehicle SVG */}
        <div className="flex-shrink-0">
          <svg width="56" height="36" viewBox="0 0 56 36">
            <defs>
              <filter id={`glow-${id}`}>
                <feGaussianBlur stdDeviation="2" result="blur" />
                <feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge>
              </filter>
            </defs>
            <ellipse cx="25" cy="30" rx="18" ry="4" fill={selected ? `${color}30` : "rgba(0,0,0,0.2)"} />
            <path
              d={SHAPES[type] || SHAPES.sedan}
              fill={selected ? color : `${color}88`}
              filter={selected ? `url(#glow-${id})` : undefined}
            />
            <path
              d={type === "truck" ? "M2,10 L22,10 L22,14" : "M10,14 L20,10 L40,10 L46,14"}
              fill="rgba(255,255,255,0.15)"
            />
            <rect
              x={type === "truck" ? "25" : "22"}
              y="14"
              width={type === "truck" ? "10" : "14"}
              height="7"
              rx="1"
              fill="rgba(0,229,255,0.5)"
            />
            <circle cx="13" cy="27" r="4" fill="#0a0c10" />
            <circle cx="13" cy="27" r="2.5" fill="#1a1f2a" />
            <circle cx="37" cy="27" r="4" fill="#0a0c10" />
            <circle cx="37" cy="27" r="2.5" fill="#1a1f2a" />
          </svg>
        </div>

        <div className="flex-1 min-w-0">
          <div
            className="truncate mb-2"
            style={{
              fontFamily: "Rajdhani, sans-serif",
              fontWeight: 700,
              fontSize: "13px",
              color: selected ? "#c8ff00" : "#e8edf5",
              letterSpacing: "0.05em",
            }}
          >
            {name}
          </div>
          <div className="space-y-1">
            <div className="flex items-center gap-2">
              <span style={{ fontFamily: "JetBrains Mono, monospace", fontSize: "9px", color: "#6b7a99", width: "36px" }}>SPD</span>
              <StatBar value={speed} color={selected ? "#c8ff00" : "#4a5568"} />
            </div>
            <div className="flex items-center gap-2">
              <span style={{ fontFamily: "JetBrains Mono, monospace", fontSize: "9px", color: "#6b7a99", width: "36px" }}>HND</span>
              <StatBar value={handling} color={selected ? "#00e5ff" : "#4a5568"} />
            </div>
            <div className="flex items-center gap-2">
              <span style={{ fontFamily: "JetBrains Mono, monospace", fontSize: "9px", color: "#6b7a99", width: "36px" }}>DUR</span>
              <StatBar value={durability} color={selected ? "#ff6b35" : "#4a5568"} />
            </div>
          </div>
        </div>
      </div>

      {/* Selected indicator */}
      {selected && (
        <div
          className="absolute top-2 right-3"
          style={{
            width: "8px",
            height: "8px",
            background: "#c8ff00",
            clipPath: "polygon(50% 0%, 100% 50%, 50% 100%, 0% 50%)",
            boxShadow: "0 0 8px rgba(200,255,0,0.8)",
          }}
        />
      )}
    </button>
  );
}
