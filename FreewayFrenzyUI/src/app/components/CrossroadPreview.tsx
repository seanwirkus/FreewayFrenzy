import { useState, useEffect } from "react";

interface CrossroadPreviewProps {
  vehicleColor: string;
  vehicleType: string;
  trafficDensity: number;
  timeOfDay: string;
}

const VEHICLE_SHAPES: Record<string, string> = {
  sedan: "M-18,4 L-14,-4 L-4,-8 L12,-8 L18,-4 L18,4 L-18,4 Z",
  suv: "M-20,5 L-16,-6 L-3,-10 L14,-10 L20,-6 L20,5 L-20,5 Z",
  sports: "M-20,3 L-14,-5 L-2,-7 L16,-7 L20,-3 L20,3 L-20,3 Z",
  truck: "M-22,6 L-22,-8 L-6,-8 L-6,-4 L18,-4 L22,-4 L22,6 L-22,6 Z",
};

const ROAD_COLORS: Record<string, { asphalt: string; line: string; glow: string }> = {
  day: { asphalt: "#1c2030", line: "#c8ff00", glow: "rgba(200,255,0,0.3)" },
  dusk: { asphalt: "#1a1525", line: "#ff9500", glow: "rgba(255,149,0,0.3)" },
  night: { asphalt: "#0d0f1a", line: "#00e5ff", glow: "rgba(0,229,255,0.3)" },
  rain: { asphalt: "#141820", line: "#80cfff", glow: "rgba(128,207,255,0.25)" },
};

function TrafficCar({ x, y, color, angle, small }: { x: number; y: number; color: string; angle: number; small?: boolean }) {
  const s = small ? 0.55 : 0.8;
  return (
    <g transform={`translate(${x},${y}) rotate(${angle}) scale(${s})`}>
      <polygon points="-14,4 -10,-4 -2,-7 10,-7 14,-4 14,4" fill={color} opacity="0.85" />
      <polygon points="-10,-4 -2,-7 10,-7 -10,-4" fill="rgba(255,255,255,0.15)" />
      <circle cx="-9" cy="4" r="3" fill="#111" />
      <circle cx="9" cy="4" r="3" fill="#111" />
    </g>
  );
}

export function CrossroadPreview({ vehicleColor, vehicleType, trafficDensity, timeOfDay }: CrossroadPreviewProps) {
  const [tick, setTick] = useState(0);
  const road = ROAD_COLORS[timeOfDay] || ROAD_COLORS.day;

  useEffect(() => {
    const id = setInterval(() => setTick(t => t + 1), 80);
    return () => clearInterval(id);
  }, []);

  const trafficCars = [];
  const count = Math.floor(trafficDensity / 20);
  const offsets = [0, 60, 120, 180, 240, 300];
  const colors = ["#ff6b35", "#a855f7", "#00e5ff", "#ff3c5a", "#fbbf24", "#34d399"];

  for (let i = 0; i < Math.min(count, 6); i++) {
    const offset = offsets[i];
    const speed = 1.2 + i * 0.3;
    const pos = (tick * speed + offset) % 340;

    if (i % 2 === 0) {
      trafficCars.push(
        <TrafficCar key={`h${i}`} x={pos - 170 + 200} y={178} color={colors[i]} angle={0} small={i > 2} />
      );
    } else {
      trafficCars.push(
        <TrafficCar key={`v${i}`} x={200} y={pos - 170 + 180} color={colors[i]} angle={90} small={i > 2} />
      );
    }
  }

  return (
    <div className="relative w-full h-full min-h-[280px] rounded overflow-hidden" style={{ background: road.asphalt }}>
      <svg viewBox="0 0 400 360" className="w-full h-full" style={{ display: "block" }}>
        {/* Low-poly background facets */}
        <polygon points="0,0 200,0 100,180" fill="rgba(200,255,0,0.03)" />
        <polygon points="200,0 400,0 400,180 300,180" fill="rgba(0,229,255,0.025)" />
        <polygon points="0,180 100,180 0,360" fill="rgba(0,229,255,0.03)" />
        <polygon points="300,180 400,180 400,360" fill="rgba(200,255,0,0.025)" />
        <polygon points="100,180 300,180 200,360" fill="rgba(200,255,0,0.02)" />

        {/* Horizontal road */}
        <rect x="0" y="155" width="400" height="50" fill={road.asphalt} />
        {/* Vertical road */}
        <rect x="175" y="0" width="50" height="360" fill={road.asphalt} />

        {/* Road edges */}
        <line x1="0" y1="155" x2="175" y2="155" stroke={road.line} strokeWidth="1" opacity="0.4" />
        <line x1="225" y1="155" x2="400" y2="155" stroke={road.line} strokeWidth="1" opacity="0.4" />
        <line x1="0" y1="205" x2="175" y2="205" stroke={road.line} strokeWidth="1" opacity="0.4" />
        <line x1="225" y1="205" x2="400" y2="205" stroke={road.line} strokeWidth="1" opacity="0.4" />
        <line x1="175" y1="0" x2="175" y2="155" stroke={road.line} strokeWidth="1" opacity="0.4" />
        <line x1="225" y1="0" x2="225" y2="155" stroke={road.line} strokeWidth="1" opacity="0.4" />
        <line x1="175" y1="205" x2="175" y2="360" stroke={road.line} strokeWidth="1" opacity="0.4" />
        <line x1="225" y1="205" x2="225" y2="360" stroke={road.line} strokeWidth="1" opacity="0.4" />

        {/* Dashed center lines */}
        {[30, 70, 110].map(x => (
          <rect key={`dhl${x}`} x={x} y={177} width={20} height={6} rx="1" fill={road.line} opacity="0.5" />
        ))}
        {[270, 310, 350].map(x => (
          <rect key={`dhr${x}`} x={x} y={177} width={20} height={6} rx="1" fill={road.line} opacity="0.5" />
        ))}
        {[20, 60, 100].map(y => (
          <rect key={`dvt${y}`} x={197} y={y} width={6} height={20} rx="1" fill={road.line} opacity="0.5" />
        ))}
        {[240, 280, 320].map(y => (
          <rect key={`dvb${y}`} x={197} y={y} width={6} height={20} rx="1" fill={road.line} opacity="0.5" />
        ))}

        {/* Crossroad intersection diamond */}
        <polygon
          points="175,155 200,130 225,155 200,180"
          fill="none"
          stroke={road.line}
          strokeWidth="1.5"
          opacity="0.6"
        />
        <polygon
          points="175,205 200,180 225,205 200,230"
          fill="none"
          stroke={road.line}
          strokeWidth="1.5"
          opacity="0.6"
        />

        {/* Traffic signal poles */}
        <rect x="170" y="148" width="3" height="10" fill={road.line} opacity="0.7" />
        <rect x="227" y="202" width="3" height="10" fill={road.line} opacity="0.7" />

        {/* Traffic cars */}
        {trafficCars}

        {/* Player vehicle */}
        <g transform="translate(200,180)">
          <ellipse cx="0" cy="8" rx="22" ry="6" fill={road.glow} />
          <path d={VEHICLE_SHAPES[vehicleType] || VEHICLE_SHAPES.sedan} fill={vehicleColor} />
          <path
            d={
              vehicleType === "truck"
                ? "M-22,-8 L-6,-8 L-6,-4"
                : "M-14,-4 L-4,-8 L12,-8 L18,-4"
            }
            fill="rgba(255,255,255,0.2)"
          />
          <rect x="-6" y="-3" width="8" height="4" rx="1" fill="rgba(0,229,255,0.7)" />
          <circle cx="-9" cy="4" r="3.5" fill="#0a0c10" />
          <circle cx="-9" cy="4" r="2" fill="#2a2e3a" />
          <circle cx="9" cy="4" r="3.5" fill="#0a0c10" />
          <circle cx="9" cy="4" r="2" fill="#2a2e3a" />
          {/* Glow outline */}
          <path
            d={VEHICLE_SHAPES[vehicleType] || VEHICLE_SHAPES.sedan}
            fill="none"
            stroke={vehicleColor}
            strokeWidth="1"
            opacity="0.5"
          />
        </g>

        {/* Corner poly accents */}
        <polygon points="0,0 30,0 0,30" fill={road.line} opacity="0.08" />
        <polygon points="400,0 370,0 400,30" fill={road.line} opacity="0.08" />
        <polygon points="0,360 30,360 0,330" fill={road.line} opacity="0.08" />
        <polygon points="400,360 370,360 400,330" fill={road.line} opacity="0.08" />
      </svg>

      {/* Time-of-day overlay */}
      {timeOfDay === "night" && (
        <div
          className="absolute inset-0 pointer-events-none"
          style={{ background: "radial-gradient(ellipse at 50% 50%, transparent 40%, rgba(0,0,0,0.5) 100%)" }}
        />
      )}
      {timeOfDay === "dusk" && (
        <div
          className="absolute inset-0 pointer-events-none"
          style={{ background: "linear-gradient(to bottom, rgba(255,100,0,0.08) 0%, transparent 60%)" }}
        />
      )}
      {timeOfDay === "rain" && (
        <div
          className="absolute inset-0 pointer-events-none"
          style={{ background: "rgba(0,40,80,0.12)" }}
        />
      )}
    </div>
  );
}
