// True isometric voxel car renderer — CrossyRoad style
// All geometry uses proper 30° isometric projection (no skew, no ellipses).

export type CarType = "sedan" | "sports" | "suv" | "truck";

interface IsoCarProps {
  type?: CarType;
  color: string;
  scale?: number;
}

function hexToRgb(hex: string) {
  const h = hex.replace("#", "");
  return {
    r: parseInt(h.slice(0, 2), 16),
    g: parseInt(h.slice(2, 4), 16),
    b: parseInt(h.slice(4, 6), 16),
  };
}
function shade(hex: string, f: number) {
  if (!hex.startsWith("#") || hex.length < 7) return hex;
  const { r, g, b } = hexToRgb(hex);
  return `rgb(${Math.round(r * f)},${Math.round(g * f)},${Math.round(b * f)})`;
}
function lighten(hex: string, a: number) {
  if (!hex.startsWith("#") || hex.length < 7) return hex;
  const { r, g, b } = hexToRgb(hex);
  return `rgb(${Math.min(255, r + a)},${Math.min(255, g + a)},${Math.min(255, b + a)})`;
}

// Isometric basis vectors (true 2:1 dimetric "video-game iso")
const SX = 10;
const SY = 5;
const SZ = 13;

function p(x: number, y: number, z: number, ox: number, oy: number) {
  return `${(ox + (x - y) * SX).toFixed(2)},${(oy + (x + y) * SY - z * SZ).toFixed(2)}`;
}
function face(corners: [number, number, number][], ox: number, oy: number) {
  return corners.map(([x, y, z]) => p(x, y, z, ox, oy)).join(" ");
}

// Voxel cube — full 3 visible faces, sharp edges
function Cube({
  x, y, z, dx, dy, dz, color, ox, oy, edge = true,
}: {
  x: number; y: number; z: number;
  dx: number; dy: number; dz: number;
  color: string;
  ox: number; oy: number;
  edge?: boolean;
}) {
  const top = lighten(color, 18);
  const left = shade(color, 0.78);   // y=const front-facing-left side
  const right = shade(color, 0.58);  // x=const front-facing-right side
  const stroke = edge ? "rgba(0,0,0,0.35)" : "none";
  const sw = edge ? 0.6 : 0;
  return (
    <g>
      {/* Left/side face: y = y (closer to camera bottom-left) */}
      <polygon
        points={face([[x, y, z], [x + dx, y, z], [x + dx, y, z + dz], [x, y, z + dz]], ox, oy)}
        fill={left} stroke={stroke} strokeWidth={sw} strokeLinejoin="miter"
      />
      {/* Right/front face: x = x+dx */}
      <polygon
        points={face([[x + dx, y, z], [x + dx, y + dy, z], [x + dx, y + dy, z + dz], [x + dx, y, z + dz]], ox, oy)}
        fill={right} stroke={stroke} strokeWidth={sw} strokeLinejoin="miter"
      />
      {/* Top face */}
      <polygon
        points={face([[x, y, z + dz], [x + dx, y, z + dz], [x + dx, y + dy, z + dz], [x, y + dy, z + dz]], ox, oy)}
        fill={top} stroke={stroke} strokeWidth={sw} strokeLinejoin="miter"
      />
    </g>
  );
}

// Isometric ground shadow built from a diamond (no ellipses — keeps everything blocky)
function ShadowDiamond({ x, y, dx, dy, ox, oy }: {
  x: number; y: number; dx: number; dy: number; ox: number; oy: number;
}) {
  return (
    <polygon
      points={face([[x, y, 0], [x + dx, y, 0], [x + dx, y + dy, 0], [x, y + dy, 0]], ox, oy)}
      fill="rgba(0,0,0,0.22)"
    />
  );
}

// Cube wheel — proper voxel, not an ellipse
function Wheel({ x, y, ox, oy, w = 0.6, l = 0.7, h = 0.5 }: {
  x: number; y: number; ox: number; oy: number; w?: number; l?: number; h?: number;
}) {
  return <Cube x={x} y={y} z={0} dx={l} dy={w} dz={h} color="#1a1208" ox={ox} oy={oy} />;
}

// Window pane (recessed face highlight only; no skew)
function WindowFace({ corners, ox, oy }: {
  corners: [number, number, number][]; ox: number; oy: number;
}) {
  return (
    <>
      <polygon points={face(corners, ox, oy)} fill="rgba(110,200,255,0.55)" />
      <polygon points={face(corners, ox, oy)} fill="none"
        stroke="rgba(0,0,0,0.4)" strokeWidth="0.5" />
    </>
  );
}

// ───────── SEDAN ─────────
function Sedan({ color, ox, oy }: { color: string; ox: number; oy: number }) {
  return (
    <g>
      <ShadowDiamond x={-0.3} y={-0.3} dx={5.6} dy={3.6} ox={ox} oy={oy} />
      {/* Wheels */}
      <Wheel x={0.2}  y={-0.05} ox={ox} oy={oy} />
      <Wheel x={0.2}  y={2.45}  ox={ox} oy={oy} />
      <Wheel x={4.0}  y={-0.05} ox={ox} oy={oy} />
      <Wheel x={4.0}  y={2.45}  ox={ox} oy={oy} />
      {/* Lower chassis */}
      <Cube x={0} y={0} z={0.4} dx={5} dy={3} dz={0.7} color={color} ox={ox} oy={oy} />
      {/* Cabin */}
      <Cube x={1.1} y={0.3} z={1.1} dx={2.8} dy={2.4} dz={0.9} color={color} ox={ox} oy={oy} />
      {/* Side window (left face of cabin: y = 0.3) */}
      <WindowFace
        corners={[[1.35, 0.3, 1.3], [3.65, 0.3, 1.3], [3.65, 0.3, 1.92], [1.35, 0.3, 1.92]]}
        ox={ox} oy={oy}
      />
      {/* Windshield (front face of cabin: x = 3.9) */}
      <WindowFace
        corners={[[3.9, 0.5, 1.3], [3.9, 2.5, 1.3], [3.9, 2.5, 1.92], [3.9, 0.5, 1.92]]}
        ox={ox} oy={oy}
      />
      {/* Headlights on chassis front face x=5 */}
      <polygon
        points={face([[5.01, 0.25, 0.55], [5.01, 0.85, 0.55], [5.01, 0.85, 0.95], [5.01, 0.25, 0.95]], ox, oy)}
        fill="#fff4b3"
      />
      <polygon
        points={face([[5.01, 2.15, 0.55], [5.01, 2.75, 0.55], [5.01, 2.75, 0.95], [5.01, 2.15, 0.95]], ox, oy)}
        fill="#fff4b3"
      />
      {/* Door seam line on side face y=0 */}
      <polyline
        points={`${p(2.5, 0, 0.42, ox, oy)} ${p(2.5, 0, 1.08, ox, oy)}`}
        stroke={shade(color, 0.55)} strokeWidth="0.5" fill="none"
      />
    </g>
  );
}

// ───────── SPORTS (low, sleek, still pure voxels) ─────────
function Sports({ color, ox, oy }: { color: string; ox: number; oy: number }) {
  return (
    <g>
      <ShadowDiamond x={-0.3} y={-0.3} dx={5.6} dy={3.6} ox={ox} oy={oy} />
      <Wheel x={0.3} y={-0.05} ox={ox} oy={oy} h={0.55} />
      <Wheel x={0.3} y={2.45}  ox={ox} oy={oy} h={0.55} />
      <Wheel x={4.1} y={-0.05} ox={ox} oy={oy} h={0.55} />
      <Wheel x={4.1} y={2.45}  ox={ox} oy={oy} h={0.55} />
      {/* Long low chassis */}
      <Cube x={0} y={0} z={0.45} dx={5} dy={3} dz={0.5} color={color} ox={ox} oy={oy} />
      {/* Hood (lower) */}
      <Cube x={3.9} y={0} z={0.95} dx={1.1} dy={3} dz={0.2} color={color} ox={ox} oy={oy} />
      {/* Cabin (small, low) */}
      <Cube x={1.4} y={0.35} z={0.95} dx={2.5} dy={2.3} dz={0.55} color={color} ox={ox} oy={oy} />
      <WindowFace
        corners={[[1.55, 0.35, 1.05], [3.85, 0.35, 1.05], [3.85, 0.35, 1.45], [1.55, 0.35, 1.45]]}
        ox={ox} oy={oy}
      />
      <WindowFace
        corners={[[3.9, 0.55, 1.05], [3.9, 2.45, 1.05], [3.9, 2.45, 1.45], [3.9, 0.55, 1.45]]}
        ox={ox} oy={oy}
      />
      {/* Rear spoiler */}
      <Cube x={-0.1} y={0.2} z={0.95} dx={0.25} dy={2.6} dz={0.4} color={shade(color, 0.4)} ox={ox} oy={oy} />
      {/* Headlights */}
      <polygon
        points={face([[5.01, 0.2, 0.55], [5.01, 0.9, 0.55], [5.01, 0.9, 0.9], [5.01, 0.2, 0.9]], ox, oy)}
        fill="#fff4b3"
      />
      <polygon
        points={face([[5.01, 2.1, 0.55], [5.01, 2.8, 0.55], [5.01, 2.8, 0.9], [5.01, 2.1, 0.9]], ox, oy)}
        fill="#fff4b3"
      />
      {/* Racing stripe on top */}
      <polygon
        points={face([[0, 1.3, 1.501], [5, 1.3, 1.501], [5, 1.7, 1.501], [0, 1.7, 1.501]], ox, oy)}
        fill={lighten(color, 60)}
      />
    </g>
  );
}

// ───────── SUV (tall) ─────────
function Suv({ color, ox, oy }: { color: string; ox: number; oy: number }) {
  return (
    <g>
      <ShadowDiamond x={-0.3} y={-0.3} dx={5.6} dy={3.6} ox={ox} oy={oy} />
      <Wheel x={0.2} y={-0.1} ox={ox} oy={oy} h={0.6} />
      <Wheel x={0.2} y={2.5}  ox={ox} oy={oy} h={0.6} />
      <Wheel x={4.0} y={-0.1} ox={ox} oy={oy} h={0.6} />
      <Wheel x={4.0} y={2.5}  ox={ox} oy={oy} h={0.6} />
      {/* Chassis */}
      <Cube x={0} y={0} z={0.55} dx={5} dy={3} dz={0.85} color={color} ox={ox} oy={oy} />
      {/* Tall cabin runs full length */}
      <Cube x={0.3} y={0.2} z={1.4} dx={4.5} dy={2.6} dz={1.3} color={color} ox={ox} oy={oy} />
      {/* Front window pane */}
      <WindowFace
        corners={[[0.55, 0.2, 1.65], [2.05, 0.2, 1.65], [2.05, 0.2, 2.5], [0.55, 0.2, 2.5]]}
        ox={ox} oy={oy}
      />
      {/* Rear window pane */}
      <WindowFace
        corners={[[2.4, 0.2, 1.65], [4.45, 0.2, 1.65], [4.45, 0.2, 2.5], [2.4, 0.2, 2.5]]}
        ox={ox} oy={oy}
      />
      {/* B-pillar */}
      <polygon
        points={face([[2.05, 0.2, 1.65], [2.4, 0.2, 1.65], [2.4, 0.2, 2.5], [2.05, 0.2, 2.5]], ox, oy)}
        fill={shade(color, 0.45)}
      />
      {/* Windshield */}
      <WindowFace
        corners={[[4.81, 0.45, 1.65], [4.81, 2.55, 1.65], [4.81, 2.55, 2.5], [4.81, 0.45, 2.5]]}
        ox={ox} oy={oy}
      />
      {/* Roof rack */}
      <Cube x={0.9} y={0.3} z={2.7} dx={3.3} dy={2.4} dz={0.1} color={shade(color, 0.4)} ox={ox} oy={oy} />
      {/* Headlights */}
      <polygon
        points={face([[5.01, 0.15, 0.7], [5.01, 0.9, 0.7], [5.01, 0.9, 1.15], [5.01, 0.15, 1.15]], ox, oy)}
        fill="#fff4b3"
      />
      <polygon
        points={face([[5.01, 2.1, 0.7], [5.01, 2.85, 0.7], [5.01, 2.85, 1.15], [5.01, 2.1, 1.15]], ox, oy)}
        fill="#fff4b3"
      />
    </g>
  );
}

// ───────── TRUCK ─────────
function Truck({ color, ox, oy }: { color: string; ox: number; oy: number }) {
  return (
    <g>
      <ShadowDiamond x={-0.3} y={-0.3} dx={6.6} dy={3.6} ox={ox} oy={oy} />
      <Wheel x={0.2} y={-0.05} ox={ox} oy={oy} h={0.6} />
      <Wheel x={0.2} y={2.45}  ox={ox} oy={oy} h={0.6} />
      <Wheel x={3.0} y={-0.05} ox={ox} oy={oy} h={0.6} />
      <Wheel x={3.0} y={2.45}  ox={ox} oy={oy} h={0.6} />
      <Wheel x={5.2} y={-0.05} ox={ox} oy={oy} h={0.6} />
      <Wheel x={5.2} y={2.45}  ox={ox} oy={oy} h={0.6} />
      {/* Chassis */}
      <Cube x={0} y={0} z={0.55} dx={6} dy={3} dz={0.55} color={color} ox={ox} oy={oy} />
      {/* Flatbed walls */}
      <Cube x={0} y={0} z={1.1} dx={0.2} dy={3} dz={0.6} color={shade(color, 0.55)} ox={ox} oy={oy} />
      <Cube x={0} y={0} z={1.1} dx={4} dy={0.2} dz={0.6} color={shade(color, 0.55)} ox={ox} oy={oy} />
      <Cube x={0} y={2.8} z={1.1} dx={4} dy={0.2} dz={0.6} color={shade(color, 0.55)} ox={ox} oy={oy} />
      <Cube x={3.8} y={0} z={1.1} dx={0.2} dy={3} dz={0.6} color={shade(color, 0.55)} ox={ox} oy={oy} />
      {/* Bed floor */}
      <polygon
        points={face([[0.2, 0.2, 1.11], [3.8, 0.2, 1.11], [3.8, 2.8, 1.11], [0.2, 2.8, 1.11]], ox, oy)}
        fill={shade(color, 0.35)}
      />
      {/* Cab */}
      <Cube x={4} y={0} z={1.1} dx={2} dy={3} dz={1.55} color={color} ox={ox} oy={oy} />
      {/* Cab side window */}
      <WindowFace
        corners={[[4.2, 0, 1.3], [5.8, 0, 1.3], [5.8, 0, 2.45], [4.2, 0, 2.45]]}
        ox={ox} oy={oy}
      />
      {/* Cab windshield */}
      <WindowFace
        corners={[[6.01, 0.3, 1.3], [6.01, 2.7, 1.3], [6.01, 2.7, 2.45], [6.01, 0.3, 2.45]]}
        ox={ox} oy={oy}
      />
      {/* Headlights */}
      <polygon
        points={face([[6.01, 0.2, 1.2], [6.01, 0.95, 1.2], [6.01, 0.95, 1.5], [6.01, 0.2, 1.5]], ox, oy)}
        fill="#fff4b3"
      />
      <polygon
        points={face([[6.01, 2.05, 1.2], [6.01, 2.8, 1.2], [6.01, 2.8, 1.5], [6.01, 2.05, 1.5]], ox, oy)}
        fill="#fff4b3"
      />
      {/* Bumper */}
      <Cube x={5.95} y={-0.05} z={1.05} dx={0.1} dy={3.1} dz={0.15} color="#d4c08a" ox={ox} oy={oy} />
    </g>
  );
}

export function IsoCar({ type = "sedan", color, scale = 1 }: IsoCarProps) {
  const configs: Record<CarType, { vb: string; ox: number; oy: number; w: number; h: number }> = {
    sedan:  { vb: "0 0 150 110", ox: 65, oy: 50,  w: 150, h: 110 },
    sports: { vb: "0 0 150 100", ox: 65, oy: 52,  w: 150, h: 100 },
    suv:    { vb: "0 0 150 125", ox: 65, oy: 60,  w: 150, h: 125 },
    truck:  { vb: "0 0 175 130", ox: 55, oy: 60,  w: 175, h: 130 },
  };
  const cfg = configs[type];
  return (
    <svg
      viewBox={cfg.vb}
      width={cfg.w * scale}
      height={cfg.h * scale}
      shapeRendering="crispEdges"
      style={{ overflow: "visible", display: "block" }}
    >
      {type === "sedan"  && <Sedan  color={color} ox={cfg.ox} oy={cfg.oy} />}
      {type === "sports" && <Sports color={color} ox={cfg.ox} oy={cfg.oy} />}
      {type === "suv"    && <Suv    color={color} ox={cfg.ox} oy={cfg.oy} />}
      {type === "truck"  && <Truck  color={color} ox={cfg.ox} oy={cfg.oy} />}
    </svg>
  );
}
