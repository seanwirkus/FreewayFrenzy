interface PolySliderProps {
  label: string;
  value: number;
  min?: number;
  max?: number;
  step?: number;
  unit?: string;
  accentColor?: string;
  onChange: (v: number) => void;
}

export function PolySlider({
  label,
  value,
  min = 0,
  max = 100,
  step = 1,
  unit = "%",
  accentColor = "#c8ff00",
  onChange,
}: PolySliderProps) {
  const pct = ((value - min) / (max - min)) * 100;

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <span
          className="uppercase tracking-widest text-muted-foreground"
          style={{ fontFamily: "JetBrains Mono, monospace", fontSize: "10px" }}
        >
          {label}
        </span>
        <span
          style={{ fontFamily: "JetBrains Mono, monospace", fontSize: "12px", color: accentColor }}
        >
          {value}{unit}
        </span>
      </div>
      <div className="relative h-5 flex items-center group">
        {/* Track background */}
        <div
          className="absolute w-full h-[3px]"
          style={{
            background: "rgba(255,255,255,0.08)",
            clipPath: "polygon(0 0, 100% 0, calc(100% - 4px) 100%, 4px 100%)",
          }}
        />
        {/* Track fill */}
        <div
          className="absolute h-[3px] transition-all duration-75"
          style={{
            width: `${pct}%`,
            background: `linear-gradient(90deg, ${accentColor}88, ${accentColor})`,
            clipPath: "polygon(0 0, 100% 0, calc(100% - 4px) 100%, 4px 100%)",
          }}
        />
        {/* Diamond thumb */}
        <div
          className="absolute w-4 h-4 transition-all duration-75"
          style={{
            left: `calc(${pct}% - 8px)`,
            background: accentColor,
            clipPath: "polygon(50% 0%, 100% 50%, 50% 100%, 0% 50%)",
            boxShadow: `0 0 8px ${accentColor}80`,
          }}
        />
        <input
          type="range"
          min={min}
          max={max}
          step={step}
          value={value}
          onChange={e => onChange(Number(e.target.value))}
          className="absolute w-full h-full opacity-0 cursor-pointer"
          style={{ zIndex: 2 }}
        />
      </div>
    </div>
  );
}
