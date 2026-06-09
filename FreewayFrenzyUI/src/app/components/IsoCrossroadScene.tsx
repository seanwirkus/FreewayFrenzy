import { useEffect, useState } from "react";

// CrossyRoad-style isometric intersection scene

const TW = 22; // tile half-width
const TH = 11; // tile half-height
const SCENE_OX = 195;
const SCENE_OY = 80;

function tileCenter(gx: number, gy: number) {
  return {
    x: SCENE_OX + (gx - gy) * TW,
    y: SCENE_OY + (gx + gy) * TH,
  };
}

function Diamond({ gx, gy, fill, stroke = "rgba(0,0,0,0.08)", strokeWidth = 0.5 }: {
  gx: number; gy: number; fill: string; stroke?: string; strokeWidth?: number;
}) {
  const { x, y } = tileCenter(gx, gy);
  const pts = `${x},${y - TH} ${x + TW},${y} ${x},${y + TH} ${x - TW},${y}`;
  return <polygon points={pts} fill={fill} stroke={stroke} strokeWidth={strokeWidth} />;
}

function RoadTile({ gx, gy, dir }: { gx: number; gy: number; dir?: "h" | "v" | "cross" }) {
  const { x, y } = tileCenter(gx, gy);
  const base = "#2c2c2c";
  const line = "#f5d020";
  const pts = `${x},${y - TH} ${x + TW},${y} ${x},${y + TH} ${x - TW},${y}`;

  if (dir === "h") {
    // horizontal dashes
    const dash1x = x - TW * 0.3;
    const dash2x = x + TW * 0.3;
    return (
      <g>
        <polygon points={pts} fill={base} />
        <line x1={dash1x - 4} y1={y} x2={dash1x + 4} y2={y} stroke={line} strokeWidth="1.5" opacity="0.7" />
        <line x1={dash2x - 4} y1={y} x2={dash2x + 4} y2={y} stroke={line} strokeWidth="1.5" opacity="0.7" />
      </g>
    );
  }
  if (dir === "v") {
    const dash1y = y - TH * 0.4;
    const dash2y = y + TH * 0.4;
    return (
      <g>
        <polygon points={pts} fill={base} />
        <line x1={x} y1={dash1y - 3} x2={x} y2={dash1y + 3} stroke={line} strokeWidth="1.5" opacity="0.7" />
        <line x1={x} y1={dash2y - 3} x2={x} y2={dash2y + 3} stroke={line} strokeWidth="1.5" opacity="0.7" />
      </g>
    );
  }
  if (dir === "cross") {
    return (
      <g>
        <polygon points={pts} fill="#333" />
        {/* Crosswalk stripes */}
        {[-3, 0, 3].map(off => (
          <line
            key={off}
            x1={x + off * 2 - 1} y1={y - TH * 0.6}
            x2={x + off * 2 - 1} y2={y + TH * 0.6}
            stroke="#fff" strokeWidth="1" opacity="0.25"
          />
        ))}
      </g>
    );
  }
  return <polygon points={pts} fill={base} />;
}

function GrassTile({ gx, gy }: { gx: number; gy: number }) {
  const { x, y } = tileCenter(gx, gy);
  const pts = `${x},${y - TH} ${x + TW},${y} ${x},${y + TH} ${x - TW},${y}`;
  const bright = "#5cd65c";
  const dark = "#47b847";
  return (
    <g>
      <polygon points={pts} fill={bright} />
      {/* subtle faceting */}
      <polygon
        points={`${x},${y - TH} ${x + TW},${y} ${x},${y}`}
        fill={dark}
        opacity="0.25"
      />
    </g>
  );
}

function Tree({ gx, gy, small }: { gx: number; gy: number; small?: boolean }) {
  const { x, y } = tileCenter(gx, gy);
  const s = small ? 0.75 : 1;
  const trunkH = 8 * s;
  const canopyR = 11 * s;
  return (
    <g>
      <rect x={x - 2 * s} y={y - trunkH} width={4 * s} height={trunkH} fill="#7a5230" rx="1" />
      <polygon
        points={`${x},${y - trunkH - canopyR * 1.5} ${x + canopyR},${y - trunkH + canopyR * 0.3} ${x - canopyR},${y - trunkH + canopyR * 0.3}`}
        fill="#2d9e2d"
      />
      <polygon
        points={`${x},${y - trunkH - canopyR * 1.5} ${x + canopyR * 0.7},${y - trunkH - canopyR * 0.2}`}
        fill="#1d7a1d"
        opacity="0.5"
      />
    </g>
  );
}

// Small isometric traffic car using true iso projection (no skew, no ellipses)
function TrafficCar({ x, y, color, dir, scale = 1 }: {
  x: number; y: number; color: string; dir: "h" | "v"; scale?: number;
}) {
  const SX_ = 6 * scale, SY_ = 3 * scale, SZ_ = 7 * scale;
  const r = parseInt(color.slice(1, 3), 16);
  const g = parseInt(color.slice(3, 5), 16);
  const b = parseInt(color.slice(5, 7), 16);
  const top = color;
  const left = `rgb(${Math.round(r * 0.78)},${Math.round(g * 0.78)},${Math.round(b * 0.78)})`;
  const right = `rgb(${Math.round(r * 0.58)},${Math.round(g * 0.58)},${Math.round(b * 0.58)})`;

  // Two orientations: dir "h" lays the long axis along +x, dir "v" along +y
  const L = dir === "h" ? 4 : 2;
  const W = dir === "h" ? 2 : 4;

  const toPt = (px: number, py: number, pz: number) =>
    `${(x + (px - py) * SX_).toFixed(2)},${(y + (px + py) * SY_ - pz * SZ_).toFixed(2)}`;
  const fc = (corners: [number, number, number][]) => corners.map(([a, b, c]) => toPt(a, b, c)).join(" ");

  // Diamond shadow
  const shadow = fc([[-0.2, -0.2, 0], [L, -0.2, 0], [L, W, 0], [-0.2, W, 0]]);

  // Wheels as small voxel cubes at the four corners
  const wheelCube = (wx: number, wy: number) => {
    const cw = 0.45, cl = 0.55, ch = 0.4;
    return (
      <g key={`${wx}-${wy}`}>
        <polygon points={fc([[wx, wy, 0], [wx + cl, wy, 0], [wx + cl, wy, ch], [wx, wy, ch]])} fill="#0c0805" />
        <polygon points={fc([[wx + cl, wy, 0], [wx + cl, wy + cw, 0], [wx + cl, wy + cw, ch], [wx + cl, wy, ch]])} fill="#070403" />
        <polygon points={fc([[wx, wy, ch], [wx + cl, wy, ch], [wx + cl, wy + cw, ch], [wx, wy + cw, ch]])} fill="#1a1208" />
      </g>
    );
  };

  return (
    <g>
      <polygon points={shadow} fill="rgba(0,0,0,0.22)" />
      {wheelCube(0.1, -0.05)}
      {wheelCube(0.1, W - 0.4)}
      {wheelCube(L - 0.65, -0.05)}
      {wheelCube(L - 0.65, W - 0.4)}
      {/* Chassis */}
      <polygon points={fc([[0, 0, 0.4], [L, 0, 0.4], [L, 0, 1], [0, 0, 1]])} fill={left} />
      <polygon points={fc([[L, 0, 0.4], [L, W, 0.4], [L, W, 1], [L, 0, 1]])} fill={right} />
      <polygon points={fc([[0, 0, 1], [L, 0, 1], [L, W, 1], [0, W, 1]])} fill={top} />
      {/* Cabin */}
      <polygon points={fc([[L * 0.2, 0.2, 1], [L * 0.85, 0.2, 1], [L * 0.85, 0.2, 1.6], [L * 0.2, 0.2, 1.6]])} fill={left} />
      <polygon points={fc([[L * 0.2, 0.2, 1.15], [L * 0.85, 0.2, 1.15], [L * 0.85, 0.2, 1.5], [L * 0.2, 0.2, 1.5]])} fill="rgba(110,200,255,0.6)" />
      <polygon points={fc([[L * 0.85, 0.2, 1], [L * 0.85, W - 0.2, 1], [L * 0.85, W - 0.2, 1.6], [L * 0.85, 0.2, 1.6]])} fill={right} />
      <polygon points={fc([[L * 0.2, 0.2, 1.6], [L * 0.85, 0.2, 1.6], [L * 0.85, W - 0.2, 1.6], [L * 0.2, W - 0.2, 1.6]])} fill={`rgb(${Math.round(r * 0.55)},${Math.round(g * 0.55)},${Math.round(b * 0.55)})`} />
    </g>
  );
}

// Player car in scene (isometric, oriented on the crossroad)
function PlayerCar({ color, gx, gy }: { color: string; gx: number; gy: number }) {
  const { x, y } = tileCenter(gx, gy);
  const SX = 7, SY = 3.5, SZ = 9;
  const ox = x, oy = y - 4;

  function p(px: number, py: number, pz: number) {
    return `${ox + (px - py) * SX},${oy + (px + py) * SY - pz * SZ}`;
  }

  function f(corners: [number, number, number][]) {
    return corners.map(([px, py, pz]) => p(px, py, pz)).join(" ");
  }

  const r = parseInt(color.slice(1, 3), 16);
  const g = parseInt(color.slice(3, 5), 16);
  const b = parseInt(color.slice(5, 7), 16);
  const top = color;
  const side = `rgb(${Math.round(r * 0.8)},${Math.round(g * 0.8)},${Math.round(b * 0.8)})`;
  const front = `rgb(${Math.round(r * 0.6)},${Math.round(g * 0.6)},${Math.round(b * 0.6)})`;
  const roof = `rgb(${Math.round(r * 0.55)},${Math.round(g * 0.55)},${Math.round(b * 0.55)})`;

  return (
    <g>
      {/* Glow */}
      <ellipse cx={ox + (2.5) * SX * 0} cy={oy + 5 * SY + 1} rx={20} ry={7}
        fill={`${color}40`} />
      {/* Shadow */}
      <ellipse cx={ox + 12} cy={oy + 5 * SY + 3} rx={18} ry={5.5}
        fill="rgba(0,0,0,0.3)" />
      {/* Wheels */}
      {([[0.4, 0.3], [0.4, 2.7], [3.6, 0.3], [3.6, 2.7]] as [number, number][]).map(([wx, wy], i) => {
        const cx = ox + (wx - wy) * SX;
        const cy = oy + (wx + wy) * SY + 2;
        return (
          <g key={i}>
            <ellipse cx={cx} cy={cy} rx={5} ry={2.5} fill="#111" />
            <ellipse cx={cx} cy={cy} rx={3} ry={1.5} fill="#333" />
          </g>
        );
      })}
      {/* Body */}
      <polygon points={f([[0,0,0],[4,0,0],[4,0,1],[0,0,1]])} fill={side} />
      <polygon points={f([[4,0,0],[4,3,0],[4,3,1],[4,0,1]])} fill={front} />
      <polygon points={f([[0,0,1],[4,0,1],[4,3,1],[0,3,1]])} fill={top} />
      {/* Cabin */}
      <polygon points={f([[0.8,0.4,1],[3.2,0.4,1],[3.2,0.4,2],[0.8,0.4,2]])} fill={side} />
      <polygon points={f([[0.9,0.5,1.12],[3.1,0.5,1.12],[3.1,0.5,1.88],[0.9,0.5,1.88]])}
        fill="rgba(100,210,255,0.6)" />
      <polygon points={f([[3.2,0.4,1],[3.2,2.6,1],[3.2,2.6,2],[3.2,0.4,2]])} fill={front} />
      <polygon points={f([[3.2,0.6,1.12],[3.2,2.4,1.12],[3.2,2.4,1.88],[3.2,0.6,1.88]])}
        fill="rgba(100,210,255,0.5)" />
      <polygon points={f([[0.8,0.4,2],[3.2,0.4,2],[3.2,2.6,2],[0.8,2.6,2]])} fill={roof} />
    </g>
  );
}

// Ambient vehicle on road with animation
interface AmbientVehicle {
  id: number;
  color: string;
  dir: "h" | "v";
  startTile: number;
  speed: number;
  laneOffset: number;
}

export function IsoCrossroadScene({ vehicleColor, trafficDensity, timeOfDay }: {
  vehicleColor: string;
  trafficDensity: number;
  timeOfDay: string;
}) {
  const [tick, setTick] = useState(0);

  useEffect(() => {
    const id = setInterval(() => setTick(t => t + 1), 50);
    return () => clearInterval(id);
  }, []);

  const GRID = 8;
  const ROAD_ROWS = [3, 4];
  const ROAD_COLS = [3, 4];

  const isRoad = (gx: number, gy: number) =>
    ROAD_ROWS.includes(gy) || ROAD_COLS.includes(gx);
  const isCross = (gx: number, gy: number) =>
    ROAD_ROWS.includes(gy) && ROAD_COLS.includes(gx);

  const fogColors: Record<string, string> = {
    day:   "rgba(255,200,100,0.03)",
    dusk:  "rgba(255,100,30,0.08)",
    night: "rgba(10,10,40,0.15)",
    rain:  "rgba(80,100,140,0.1)",
  };

  const ambientVehicles: AmbientVehicle[] = [
    { id: 1, color: "#E63946", dir: "h", startTile: 0, speed: 0.8, laneOffset: -0.3 },
    { id: 2, color: "#457B9D", dir: "h", startTile: 120, speed: 0.6, laneOffset: 0.3 },
    { id: 3, color: "#2DC653", dir: "v", startTile: 40, speed: 0.7, laneOffset: -0.2 },
    { id: 4, color: "#F4A261", dir: "v", startTile: 200, speed: 0.9, laneOffset: 0.2 },
    { id: 5, color: "#9B2226", dir: "h", startTile: 280, speed: 0.55, laneOffset: -0.3 },
  ];

  const maxVehicles = Math.ceil(trafficDensity / 20);
  const activeVehicles = ambientVehicles.slice(0, Math.max(1, maxVehicles));

  // Time of day overlay colors
  const skyGradient = {
    day:   ["#87CEEB", "#FFD700"],
    dusk:  ["#FF6B35", "#FF9F0A"],
    night: ["#0d0820", "#1a1040"],
    rain:  ["#607090", "#405070"],
  }[timeOfDay] ?? ["#87CEEB", "#FFD700"];

  return (
    <div className="relative w-full h-full" style={{ minHeight: 280 }}>
      <svg viewBox="0 0 390 270" className="w-full h-full" style={{ display: "block" }}>
        {/* Sky gradient */}
        <defs>
          <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={skyGradient[0]} stopOpacity="0.3" />
            <stop offset="100%" stopColor={skyGradient[1]} stopOpacity="0" />
          </linearGradient>
          <radialGradient id="vignette">
            <stop offset="50%" stopColor="transparent" />
            <stop offset="100%" stopColor="rgba(20,14,6,0.4)" />
          </radialGradient>
        </defs>
        <rect width="390" height="270" fill="url(#sky)" />

        {/* Render tiles back to front (painter's algorithm: sort by gx+gy) */}
        {Array.from({ length: GRID }, (_, gy) =>
          Array.from({ length: GRID }, (_, gx) => {
            if (isCross(gx, gy)) return <RoadTile key={`${gx}-${gy}`} gx={gx} gy={gy} dir="cross" />;
            if (ROAD_ROWS.includes(gy)) return <RoadTile key={`${gx}-${gy}`} gx={gx} gy={gy} dir="h" />;
            if (ROAD_COLS.includes(gx)) return <RoadTile key={`${gx}-${gy}`} gx={gx} gy={gy} dir="v" />;
            return <GrassTile key={`${gx}-${gy}`} gx={gx} gy={gy} />;
          })
        )}

        {/* Trees on grass tiles */}
        {[[0,0],[1,0],[0,1],[7,0],[7,1],[0,7],[1,7],[7,7],[0,5],[6,0],[5,0],[6,7],[7,5]].map(([gx,gy],i) => (
          <Tree key={i} gx={gx} gy={gy} small={i % 3 === 2} />
        ))}

        {/* Animated traffic vehicles */}
        {activeVehicles.map(v => {
          const totalTiles = GRID * TW * 2 * 1.5;
          const pos = ((tick * v.speed + v.startTile) % totalTiles);

          if (v.dir === "h") {
            // Moving along horizontal road (gy=3 or 4 row)
            const rowGy = 3;
            const center = tileCenter(0, rowGy);
            const tx = center.x - GRID * TW + pos - TW;
            const ty = center.y + v.laneOffset * TH * 2;
            if (tx > -20 && tx < 420) {
              return <TrafficCar key={v.id} x={tx} y={ty} color={v.color} dir="h" scale={0.75} />;
            }
          } else {
            // Moving along vertical road (gx=3 or 4 column)
            const colGx = 4;
            const center = tileCenter(colGx, 0);
            const ty = center.y + pos * 0.7 - 40;
            const tx = center.x + v.laneOffset * TW * 2;
            if (ty > -20 && ty < 290) {
              return <TrafficCar key={v.id} x={tx} y={ty} color={v.color} dir="v" scale={0.75} />;
            }
          }
          return null;
        })}

        {/* Player vehicle at intersection center */}
        <PlayerCar color={vehicleColor} gx={3} gy={3} />

        {/* Night/rain overlay */}
        <rect width="390" height="270" fill={fogColors[timeOfDay] ?? "transparent"} />
        <rect width="390" height="270" fill="url(#vignette)" />

        {/* Traffic signals */}
        {[[175, 88],[215, 96]].map(([sx, sy], i) => (
          <g key={i}>
            <rect x={sx} y={sy} width={4} height={16} fill="#555" rx="1" />
            <rect x={sx - 3} y={sy - 10} width={10} height={12} fill="#222" rx="1" />
            <circle cx={sx + 2} cy={sy - 7} r={2.5}
              fill={tick % 60 < 30 ? "#ff3b30" : "#1a1a1a"} />
            <circle cx={sx + 2} cy={sy - 1} r={2.5}
              fill={tick % 60 >= 30 ? "#30d158" : "#1a1a1a"} />
          </g>
        ))}
      </svg>
    </div>
  );
}
