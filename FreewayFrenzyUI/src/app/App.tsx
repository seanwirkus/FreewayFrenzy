import { useState } from "react";
import { IsoCar, CarType } from "./components/IsoCar";
import { IsoCrossroadScene } from "./components/IsoCrossroadScene";
import {
  IconCar, IconMap, IconGear, IconPaint, IconBolt, IconTrophy, IconFlag,
  IconCheck, IconSun, IconDusk, IconMoon, IconRain, IconPlay, IconLap,
  IconRuler, IconShield, IconAngry, IconPolice, IconStar, IconFire,
  IconHeart, IconTarget, IconJoypad, IconTrafficLight,
} from "./components/Icons";

// ─── Data ──────────────────────────────────────────────────────────────────

const VEHICLES: {
  id: string; name: string; subtitle: string; type: CarType;
  color: string; speed: number; handling: number; durability: number; nitro: number;
}[] = [
  { id: "v1", name: "APEX RUNNER", subtitle: "Sports", type: "sports", color: "#E63946", speed: 95, handling: 88, durability: 50, nitro: 80 },
  { id: "v2", name: "DELTA CRUISER", subtitle: "Sedan",  type: "sedan",  color: "#457B9D", speed: 65, handling: 75, durability: 80, nitro: 55 },
  { id: "v3", name: "TITAN BLOCK",   subtitle: "SUV",    type: "suv",    color: "#2DC653", speed: 52, handling: 58, durability: 97, nitro: 40 },
  { id: "v4", name: "HAULER X9",     subtitle: "Truck",  type: "truck",  color: "#F4A261", speed: 42, handling: 44, durability: 100, nitro: 30 },
];

const PAINT_COLORS = [
  "#E63946", "#FF6B35", "#FF9F0A", "#F4D35E",
  "#2DC653", "#00C2A0", "#457B9D", "#6A4C93",
  "#E8E8E8", "#2C2C2C",
];

const ROUTES = [
  { id: "r1", name: "Downtown Grid",   laps: 3, km: "4.2", tag: "MEDIUM", tagColor: "#FF9F0A" },
  { id: "r2", name: "Harbor Loop",     laps: 2, km: "7.8", tag: "HARD",   tagColor: "#E63946" },
  { id: "r3", name: "Industrial Cut",  laps: 5, km: "2.1", tag: "EASY",   tagColor: "#2DC653" },
  { id: "r4", name: "Midnight Express",laps: 1, km: "12.4",tag: "EXTREME",tagColor: "#9B2226" },
];

const TIME_OF_DAY: { id: string; label: string; Icon: React.FC<{ size?: number; color?: string }> }[] = [
  { id: "day",   label: "Day",   Icon: IconSun  },
  { id: "dusk",  label: "Dusk",  Icon: IconDusk },
  { id: "night", label: "Night", Icon: IconMoon },
  { id: "rain",  label: "Rain",  Icon: IconRain },
];

const DIFFICULTIES = [
  { id: "rookie",  label: "Rookie",  bg: "rgba(45,198,83,0.15)",  border: "rgba(45,198,83,0.5)",  text: "#2DC653" },
  { id: "street",  label: "Street",  bg: "rgba(255,159,10,0.15)", border: "rgba(255,159,10,0.5)", text: "#FF9F0A" },
  { id: "pro",     label: "Pro",     bg: "rgba(255,107,53,0.15)", border: "rgba(255,107,53,0.5)", text: "#FF6B35" },
  { id: "legend",  label: "Legend",  bg: "rgba(230,57,70,0.15)",  border: "rgba(230,57,70,0.5)",  text: "#E63946" },
];

// ─── Blocky primitives ─────────────────────────────────────────────────────

const RADIUS = 2; // blocky corners — small but not zero

function StatBar({ label, value, color }: { label: string; value: number; color: string }) {
  return (
    <div className="flex items-center gap-2">
      <span style={{ fontFamily: "JetBrains Mono, monospace", fontSize: "10px", color: "#a07848", width: 28, flexShrink: 0 }}>
        {label}
      </span>
      <div className="flex-1 overflow-hidden" style={{ height: 8, background: "rgba(0,0,0,0.4)", border: "1px solid rgba(255,180,80,0.18)" }}>
        {/* Segmented blocky fill */}
        <div className="flex h-full" style={{ width: `${value}%` }}>
          {Array.from({ length: Math.max(1, Math.floor(value / 8)) }).map((_, i) => (
            <div key={i} style={{ flex: 1, background: color, marginRight: 1, boxShadow: `inset 0 -2px 0 rgba(0,0,0,0.25)` }} />
          ))}
        </div>
      </div>
      <span style={{ fontFamily: "JetBrains Mono, monospace", fontSize: "10px", color: "#a07848", width: 24, textAlign: "right" }}>
        {value}
      </span>
    </div>
  );
}

function BlockySlider({ label, value, onChange, color = "#FF9F0A", Icon }: {
  label: string; value: number; onChange: (v: number) => void; color?: string;
  Icon?: React.FC<{ size?: number; color?: string }>;
}) {
  const segments = 20;
  const filled = Math.round((value / 100) * segments);
  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <span className="flex items-center gap-1.5" style={{ fontFamily: "Nunito, sans-serif", fontSize: "13px", fontWeight: 800, color: "#fff4e0" }}>
          {Icon && <Icon size={12} color="#a07848" />}
          {label}
        </span>
        <span style={{ fontFamily: "JetBrains Mono, monospace", fontSize: "12px", color, fontWeight: 700 }}>
          {value.toString().padStart(2, "0")}%
        </span>
      </div>
      <div className="relative h-6 flex items-center">
        <div className="flex w-full gap-[2px]" style={{ height: 10 }}>
          {Array.from({ length: segments }).map((_, i) => (
            <div
              key={i}
              style={{
                flex: 1,
                background: i < filled ? color : "rgba(255,255,255,0.07)",
                border: i < filled ? `1px solid ${color}` : "1px solid rgba(255,180,80,0.12)",
                boxShadow: i < filled ? `inset 0 -2px 0 rgba(0,0,0,0.3)` : "none",
              }}
            />
          ))}
        </div>
        <input
          type="range" min={0} max={100} value={value}
          onChange={e => onChange(+e.target.value)}
          className="absolute w-full opacity-0 cursor-pointer"
          style={{ zIndex: 2, height: "100%" }}
        />
      </div>
    </div>
  );
}

function Panel({ children, className = "", style = {} }: { children: React.ReactNode; className?: string; style?: React.CSSProperties }) {
  return (
    <div
      className={className}
      style={{
        background: "rgba(35,22,7,0.92)",
        border: "2px solid rgba(255,180,80,0.22)",
        borderRadius: RADIUS,
        boxShadow: "inset 0 1px 0 rgba(255,180,80,0.08), 0 4px 0 rgba(0,0,0,0.4)",
        ...style,
      }}
    >
      {children}
    </div>
  );
}

function SectionHeading({ Icon, title }: { Icon: React.FC<{ size?: number; color?: string }>; title: string }) {
  return (
    <div className="flex items-center gap-2 mb-3">
      <Icon size={14} color="#FF9F0A" />
      <span style={{ fontFamily: "Nunito, sans-serif", fontWeight: 900, fontSize: "11px", color: "#a07848", letterSpacing: "0.18em", textTransform: "uppercase" }}>
        {title}
      </span>
      <div className="flex-1" style={{ height: 2, background: "rgba(255,180,80,0.15)" }} />
    </div>
  );
}

type Tab = "vehicle" | "route" | "settings";

// ─── Main App ──────────────────────────────────────────────────────────────

export default function App() {
  const [tab, setTab] = useState<Tab>("vehicle");
  const [vehicleId, setVehicleId] = useState("v1");
  const [paintColor, setPaintColor] = useState("#E63946");
  const [routeId, setRouteId] = useState("r1");
  const [timeOfDay, setTimeOfDay] = useState("day");
  const [difficulty, setDifficulty] = useState("street");
  const [traffic, setTraffic] = useState(40);
  const [aggression, setAggression] = useState(55);
  const [nitroBoosts, setNitroBoosts] = useState(3);
  const [policeChase, setPoliceChase] = useState(false);
  const [wetRoads, setWetRoads] = useState(false);
  const [ghostMode, setGhostMode] = useState(false);

  const vehicle = VEHICLES.find(v => v.id === vehicleId)!;
  const route = ROUTES.find(r => r.id === routeId)!;
  const diff = DIFFICULTIES.find(d => d.id === difficulty)!;

  const tabs: { id: Tab; label: string; Icon: React.FC<{ size?: number; color?: string }> }[] = [
    { id: "vehicle",  label: "Garage",   Icon: IconCar  },
    { id: "route",    label: "Route",    Icon: IconMap  },
    { id: "settings", label: "Settings", Icon: IconGear },
  ];

  return (
    <div
      className="min-h-screen overflow-hidden relative"
      style={{
        fontFamily: "Nunito, sans-serif",
        background: "linear-gradient(145deg, #1f1408 0%, #0e0a04 50%, #16100a 100%)",
      }}
    >
      {/* Warm decorative background — blocky pixel grid */}
      <div className="absolute inset-0 pointer-events-none overflow-hidden">
        <div style={{
          position: "absolute", top: -80, left: -60, width: 400, height: 400,
          background: "radial-gradient(circle, rgba(255,159,10,0.07) 0%, transparent 70%)",
        }} />
        <div style={{
          position: "absolute", bottom: -100, right: -80, width: 500, height: 500,
          background: "radial-gradient(circle, rgba(230,57,70,0.05) 0%, transparent 70%)",
        }} />
        <svg className="absolute inset-0 w-full h-full" opacity="0.04">
          {Array.from({ length: 30 }, (_, i) => (
            <line key={`h${i}`} x1="0" y1={i * 32} x2="100%" y2={i * 32}
              stroke="#FF9F0A" strokeWidth="1" shapeRendering="crispEdges" />
          ))}
          {Array.from({ length: 50 }, (_, i) => (
            <line key={`v${i}`} x1={i * 32} y1="0" x2={i * 32} y2="100%"
              stroke="#FF9F0A" strokeWidth="1" shapeRendering="crispEdges" />
          ))}
        </svg>
      </div>

      <div className="relative z-10 flex flex-col h-screen overflow-hidden p-4 gap-3" style={{ maxHeight: "100vh" }}>

        {/* ── Header ── */}
        <header className="flex-shrink-0 flex items-center justify-between">
          <div className="flex items-center gap-3">
            {/* Blocky logo */}
            <div style={{
              width: 44, height: 44,
              background: "rgba(255,159,10,0.12)",
              border: "2px solid rgba(255,159,10,0.4)",
              borderRadius: RADIUS,
              display: "flex", alignItems: "center", justifyContent: "center",
            }}>
              <svg width="28" height="28" viewBox="0 0 16 16" shapeRendering="crispEdges">
                <rect x="7" y="1" width="2" height="14" fill="#FF9F0A" />
                <rect x="1" y="7" width="14" height="2" fill="#FF9F0A" />
                <rect x="6" y="6" width="4" height="4" fill="#1a1108" />
                <rect x="7" y="7" width="2" height="2" fill="#FF6B35" />
              </svg>
            </div>
            <div>
              <div style={{
                fontFamily: "Nunito, sans-serif", fontWeight: 900, fontSize: "22px",
                lineHeight: 1, letterSpacing: "-0.02em",
                background: "linear-gradient(135deg, #FF9F0A, #FF6B35)",
                WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent",
              }}>
                FreewayFrenzy
              </div>
              <div style={{ fontFamily: "JetBrains Mono, monospace", fontSize: "9px", color: "#a07848", letterSpacing: "0.2em" }}>
                CUSTOMIZE · RACE · WIN
              </div>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <div className="flex items-center gap-2 px-3 py-1.5"
              style={{
                background: "rgba(255,159,10,0.1)",
                border: "2px solid rgba(255,159,10,0.3)",
                borderRadius: RADIUS,
              }}
            >
              <IconTrophy size={16} color="#FF9F0A" />
              <div>
                <div style={{ fontFamily: "JetBrains Mono, monospace", fontSize: "9px", color: "#a07848" }}>SEASON 7</div>
                <div style={{ fontFamily: "Nunito, sans-serif", fontWeight: 800, fontSize: "12px", color: "#FF9F0A" }}>Rank #42</div>
              </div>
            </div>
            <div className="flex items-center gap-2 px-3 py-1.5"
              style={{
                background: "rgba(255,255,255,0.04)",
                border: "2px solid rgba(255,180,80,0.18)",
                borderRadius: RADIUS,
              }}
            >
              <div
                style={{ width: 28, height: 28, background: "rgba(255,159,10,0.2)", border: "1px solid rgba(255,159,10,0.4)", borderRadius: RADIUS,
                  display: "flex", alignItems: "center", justifyContent: "center" }}
              >
                <IconJoypad size={16} color="#FF9F0A" />
              </div>
              <div>
                <div style={{ fontFamily: "JetBrains Mono, monospace", fontSize: "9px", color: "#a07848" }}>PILOT</div>
                <div style={{ fontFamily: "Nunito, sans-serif", fontWeight: 800, fontSize: "13px", color: "#fff4e0" }}>ACE_DRIVER_77</div>
              </div>
            </div>
          </div>
        </header>

        {/* ── Main content ── */}
        <div className="flex gap-3 flex-1 min-h-0">

          {/* ── LEFT PANEL ── */}
          <div className="flex flex-col gap-3" style={{ width: 270, flexShrink: 0 }}>

            {/* Tabs */}
            <div className="flex gap-1 p-1" style={{
              background: "rgba(0,0,0,0.3)", border: "2px solid rgba(255,180,80,0.18)", borderRadius: RADIUS,
            }}>
              {tabs.map(t => (
                <button
                  key={t.id}
                  onClick={() => setTab(t.id)}
                  className="flex-1 flex items-center justify-center gap-1.5 py-2 transition-all duration-150"
                  style={{
                    background: tab === t.id ? "rgba(255,159,10,0.2)" : "transparent",
                    border: tab === t.id ? "2px solid rgba(255,159,10,0.5)" : "2px solid transparent",
                    borderRadius: RADIUS,
                    fontFamily: "Nunito, sans-serif",
                    fontWeight: 900,
                    fontSize: "12px",
                    color: tab === t.id ? "#FF9F0A" : "#a07848",
                    boxShadow: tab === t.id ? "inset 0 -2px 0 rgba(0,0,0,0.3)" : "none",
                  }}
                >
                  <t.Icon size={14} />
                  {t.label}
                </button>
              ))}
            </div>

            <Panel className="flex-1 overflow-y-auto p-4" style={{ scrollbarWidth: "none" }}>

              {/* ── GARAGE TAB ── */}
              {tab === "vehicle" && (
                <div className="space-y-4">
                  <SectionHeading Icon={IconCar} title="Choose Your Ride" />

                  <div className="space-y-2">
                    {VEHICLES.map(v => {
                      const sel = vehicleId === v.id;
                      const displayColor = sel ? paintColor : v.color;
                      return (
                        <button
                          key={v.id}
                          onClick={() => { setVehicleId(v.id); setPaintColor(v.color); }}
                          className="w-full text-left transition-all duration-150"
                          style={{
                            background: sel ? "rgba(255,159,10,0.12)" : "rgba(255,255,255,0.03)",
                            border: `2px solid ${sel ? "rgba(255,159,10,0.5)" : "rgba(255,180,80,0.12)"}`,
                            borderRadius: RADIUS,
                            padding: "10px 12px",
                            boxShadow: sel ? "inset 0 -3px 0 rgba(0,0,0,0.3)" : "none",
                          }}
                        >
                          <div className="flex items-center gap-3">
                            <div className="flex-shrink-0" style={{ width: 78, height: 56, overflow: "hidden", position: "relative" }}>
                              <div style={{ transform: "scale(0.55)", transformOrigin: "top left", position: "absolute", top: -4, left: -8 }}>
                                <IsoCar type={v.type} color={displayColor} />
                              </div>
                            </div>
                            <div className="flex-1 min-w-0">
                              <div className="flex items-center justify-between mb-1">
                                <div>
                                  <div style={{ fontFamily: "Nunito, sans-serif", fontWeight: 900, fontSize: "13px", color: sel ? "#FF9F0A" : "#fff4e0" }}>
                                    {v.name}
                                  </div>
                                  <div style={{ fontFamily: "JetBrains Mono, monospace", fontSize: "9px", color: "#a07848" }}>
                                    {v.subtitle}
                                  </div>
                                </div>
                                {sel && (
                                  <div style={{
                                    width: 18, height: 18, background: "#FF9F0A",
                                    border: "1px solid #1a1108", borderRadius: RADIUS,
                                    display: "flex", alignItems: "center", justifyContent: "center",
                                  }}>
                                    <IconCheck size={12} color="#1a1108" />
                                  </div>
                                )}
                              </div>
                              <div className="space-y-1">
                                <StatBar label="SPD" value={v.speed}     color="#E63946" />
                                <StatBar label="HND" value={v.handling}  color="#FF9F0A" />
                                <StatBar label="DUR" value={v.durability} color="#2DC653" />
                              </div>
                            </div>
                          </div>
                        </button>
                      );
                    })}
                  </div>

                  <SectionHeading Icon={IconPaint} title="Paint Job" />
                  <div className="flex flex-wrap gap-2">
                    {PAINT_COLORS.map(c => (
                      <button
                        key={c}
                        onClick={() => setPaintColor(c)}
                        className="transition-all duration-100"
                        style={{
                          width: 28, height: 28,
                          background: c,
                          borderRadius: RADIUS,
                          border: `2px solid ${paintColor === c ? "#fff4e0" : "rgba(0,0,0,0.4)"}`,
                          boxShadow: paintColor === c
                            ? `0 0 0 2px ${c}, inset 0 -3px 0 rgba(0,0,0,0.3)`
                            : "inset 0 -3px 0 rgba(0,0,0,0.3)",
                        }}
                      />
                    ))}
                  </div>

                  <SectionHeading Icon={IconBolt} title="Nitro Boosts" />
                  <div className="flex gap-1.5">
                    {[1, 2, 3, 4, 5].map(n => {
                      const on = n <= nitroBoosts;
                      return (
                        <button
                          key={n}
                          onClick={() => setNitroBoosts(n)}
                          className="flex-1 py-2.5 transition-all"
                          style={{
                            background: on ? "rgba(255,107,53,0.22)" : "rgba(255,255,255,0.04)",
                            border: `2px solid ${on ? "rgba(255,107,53,0.6)" : "rgba(255,255,255,0.1)"}`,
                            borderRadius: RADIUS,
                            fontFamily: "JetBrains Mono, monospace",
                            fontWeight: 800,
                            fontSize: "12px",
                            color: on ? "#FF6B35" : "#a07848",
                            boxShadow: on ? "inset 0 -3px 0 rgba(0,0,0,0.3)" : "none",
                          }}
                        >
                          {n}
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* ── ROUTE TAB ── */}
              {tab === "route" && (
                <div className="space-y-4">
                  <SectionHeading Icon={IconMap} title="Pick a Route" />
                  <div className="space-y-2">
                    {ROUTES.map(r => {
                      const sel = routeId === r.id;
                      return (
                        <button
                          key={r.id}
                          onClick={() => setRouteId(r.id)}
                          className="w-full text-left p-3 transition-all duration-150"
                          style={{
                            background: sel ? "rgba(255,159,10,0.12)" : "rgba(255,255,255,0.03)",
                            border: `2px solid ${sel ? "rgba(255,159,10,0.5)" : "rgba(255,180,80,0.12)"}`,
                            borderRadius: RADIUS,
                            boxShadow: sel ? "inset 0 -3px 0 rgba(0,0,0,0.3)" : "none",
                          }}
                        >
                          <div className="flex items-center justify-between mb-1.5">
                            <span style={{ fontFamily: "Nunito, sans-serif", fontWeight: 800, fontSize: "13px", color: sel ? "#FF9F0A" : "#fff4e0" }}>
                              {r.name}
                            </span>
                            <span
                              style={{
                                fontFamily: "Nunito, sans-serif", fontWeight: 900, fontSize: "9px",
                                color: r.tagColor, background: `${r.tagColor}22`,
                                padding: "3px 8px", borderRadius: RADIUS, border: `2px solid ${r.tagColor}55`,
                                letterSpacing: "0.1em",
                              }}
                            >
                              {r.tag}
                            </span>
                          </div>
                          <div className="flex gap-4">
                            <span className="flex items-center gap-1" style={{ fontFamily: "JetBrains Mono, monospace", fontSize: "10px", color: "#a07848" }}>
                              <IconLap size={10} /> {r.laps} Laps
                            </span>
                            <span className="flex items-center gap-1" style={{ fontFamily: "JetBrains Mono, monospace", fontSize: "10px", color: "#a07848" }}>
                              <IconRuler size={10} /> {r.km} km
                            </span>
                          </div>
                        </button>
                      );
                    })}
                  </div>

                  <SectionHeading Icon={IconSun} title="Time of Day" />
                  <div className="grid grid-cols-2 gap-2">
                    {TIME_OF_DAY.map(t => {
                      const on = timeOfDay === t.id;
                      return (
                        <button
                          key={t.id}
                          onClick={() => setTimeOfDay(t.id)}
                          className="py-3 flex items-center justify-center gap-2 transition-all"
                          style={{
                            background: on ? "rgba(255,159,10,0.14)" : "rgba(255,255,255,0.03)",
                            border: `2px solid ${on ? "rgba(255,159,10,0.5)" : "rgba(255,180,80,0.12)"}`,
                            borderRadius: RADIUS,
                            fontFamily: "Nunito, sans-serif", fontWeight: 900, fontSize: "13px",
                            color: on ? "#FF9F0A" : "#a07848",
                            boxShadow: on ? "inset 0 -3px 0 rgba(0,0,0,0.3)" : "none",
                          }}
                        >
                          <t.Icon size={16} color={on ? "#FF9F0A" : "#a07848"} />
                          {t.label}
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* ── SETTINGS TAB ── */}
              {tab === "settings" && (
                <div className="space-y-5">
                  <SectionHeading Icon={IconFlag} title="Difficulty" />
                  <div className="grid grid-cols-2 gap-2">
                    {DIFFICULTIES.map(d => {
                      const on = difficulty === d.id;
                      return (
                        <button
                          key={d.id}
                          onClick={() => setDifficulty(d.id)}
                          className="py-3 transition-all flex flex-col items-center gap-1"
                          style={{
                            background: on ? d.bg : "rgba(255,255,255,0.03)",
                            border: `2px solid ${on ? d.border : "rgba(255,180,80,0.12)"}`,
                            borderRadius: RADIUS,
                            fontFamily: "Nunito, sans-serif", fontWeight: 900, fontSize: "12px",
                            color: on ? d.text : "#a07848",
                            boxShadow: on ? "inset 0 -3px 0 rgba(0,0,0,0.3)" : "none",
                          }}
                        >
                          <div style={{ width: 12, height: 12, background: on ? d.text : "rgba(255,255,255,0.15)", borderRadius: RADIUS }} />
                          {d.label}
                        </button>
                      );
                    })}
                  </div>

                  <SectionHeading Icon={IconTrafficLight} title="Traffic" />
                  <div className="space-y-4">
                    <BlockySlider label="Density"    value={traffic}    onChange={setTraffic}    Icon={IconCar} />
                    <BlockySlider label="Aggression" value={aggression} onChange={setAggression} color="#FF6B35" Icon={IconAngry} />
                  </div>

                  <SectionHeading Icon={IconJoypad} title="Game Rules" />
                  <div className="space-y-2">
                    {[
                      { label: "Police Chase", Icon: IconPolice, value: policeChase, toggle: () => setPoliceChase(v => !v) },
                      { label: "Wet Roads",    Icon: IconRain,   value: wetRoads,    toggle: () => setWetRoads(v => !v) },
                      { label: "Ghost Mode",   Icon: IconShield, value: ghostMode,   toggle: () => setGhostMode(v => !v) },
                    ].map(rule => (
                      <div
                        key={rule.label}
                        className="flex items-center justify-between p-3"
                        style={{ background: "rgba(255,255,255,0.03)", border: "2px solid rgba(255,180,80,0.12)", borderRadius: RADIUS }}
                      >
                        <span className="flex items-center gap-2" style={{ fontFamily: "Nunito, sans-serif", fontWeight: 800, fontSize: "13px", color: "#fff4e0" }}>
                          <rule.Icon size={14} color="#a07848" />
                          {rule.label}
                        </span>
                        {/* Blocky toggle */}
                        <button
                          onClick={rule.toggle}
                          className="relative transition-all duration-100"
                          style={{
                            width: 48, height: 24,
                            background: rule.value ? "#FF9F0A" : "rgba(0,0,0,0.4)",
                            border: `2px solid ${rule.value ? "#FF9F0A" : "rgba(255,180,80,0.2)"}`,
                            borderRadius: RADIUS,
                            boxShadow: "inset 0 -2px 0 rgba(0,0,0,0.3)",
                          }}
                        >
                          <div
                            className="absolute top-0 transition-all duration-100"
                            style={{
                              width: 16, height: 16,
                              background: "#fff4e0",
                              borderRadius: RADIUS,
                              top: 2,
                              left: rule.value ? 26 : 2,
                              boxShadow: "inset 0 -2px 0 rgba(0,0,0,0.25)",
                            }}
                          />
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </Panel>
          </div>

          {/* ── CENTER: Preview ── */}
          <div className="flex-1 flex flex-col gap-3 min-w-0">

            {/* BIG car showcase */}
            <Panel className="flex-shrink-0" style={{ padding: "16px 20px 8px", position: "relative", overflow: "hidden" }}>
              <div style={{
                position: "absolute",
                bottom: 0, left: "50%", transform: "translateX(-50%)",
                width: 300, height: 150,
                background: `radial-gradient(ellipse, ${paintColor}30 0%, transparent 70%)`,
                pointerEvents: "none",
              }} />
              <div className="flex items-end justify-between">
                <div className="flex-1 flex items-center justify-center" style={{ height: 170 }}>
                  <IsoCar type={vehicle.type} color={paintColor} scale={1.05} />
                </div>

                <div className="flex-shrink-0" style={{ width: 170 }}>
                  <div style={{ fontFamily: "Nunito, sans-serif", fontWeight: 900, fontSize: "18px", color: "#fff4e0", lineHeight: 1 }}>
                    {vehicle.name}
                  </div>
                  <div style={{ fontFamily: "JetBrains Mono, monospace", fontSize: "10px", color: "#a07848", marginBottom: 10 }}>
                    {vehicle.subtitle} Class
                  </div>
                  <div className="space-y-1.5">
                    <StatBar label="SPD" value={vehicle.speed}     color="#E63946" />
                    <StatBar label="HND" value={vehicle.handling}  color="#FF9F0A" />
                    <StatBar label="DUR" value={vehicle.durability} color="#2DC653" />
                    <StatBar label="NOS" value={vehicle.nitro}     color="#457B9D" />
                  </div>
                  <div className="flex items-center gap-2 mt-3">
                    <div style={{ width: 20, height: 20, borderRadius: RADIUS, background: paintColor, border: "2px solid rgba(255,255,255,0.5)", boxShadow: "inset 0 -3px 0 rgba(0,0,0,0.3)" }} />
                    <span style={{ fontFamily: "JetBrains Mono, monospace", fontSize: "10px", color: "#a07848" }}>
                      {paintColor.toUpperCase()}
                    </span>
                  </div>
                </div>
              </div>
            </Panel>

            {/* Crossroad live scene */}
            <Panel className="flex-1 overflow-hidden" style={{ position: "relative", padding: 0, minHeight: 0 }}>
              <div className="absolute top-3 left-4 z-10 flex items-center gap-2">
                <div style={{ width: 8, height: 8, background: "#2DC653", border: "1px solid #1a1108", animation: "pulse 1.5s steps(2) infinite" }} />
                <span style={{ fontFamily: "JetBrains Mono, monospace", fontSize: "9px", color: "#a07848", letterSpacing: "0.15em" }}>
                  LIVE PREVIEW · {timeOfDay.toUpperCase()}
                </span>
              </div>
              <div className="absolute top-3 right-4 z-10">
                <span className="inline-flex items-center gap-1" style={{
                  fontFamily: "JetBrains Mono, monospace", fontSize: "9px",
                  color: "#FF9F0A", background: "rgba(255,159,10,0.1)",
                  border: "2px solid rgba(255,159,10,0.35)",
                  padding: "3px 8px", borderRadius: RADIUS,
                }}>
                  <IconCar size={10} color="#FF9F0A" /> {traffic}% TRAFFIC
                </span>
              </div>
              <IsoCrossroadScene
                vehicleColor={paintColor}
                trafficDensity={traffic}
                timeOfDay={timeOfDay}
              />
            </Panel>

            {/* Config bar */}
            <Panel className="flex-shrink-0">
              <div className="flex items-center justify-around py-2 px-4">
                {[
                  { Icon: IconMap,    label: "ROUTE", value: route.name },
                  { Icon: IconLap,    label: "LAPS",  value: `${route.laps}x` },
                  { Icon: IconRuler,  label: "DIST",  value: `${route.km} km` },
                  { Icon: IconFlag,   label: "DIFF",  value: diff.label, color: diff.text },
                  { Icon: IconBolt,   label: "NITRO", value: `x${nitroBoosts}` },
                ].map((s, i) => (
                  <div key={i} className="text-center flex flex-col items-center">
                    <s.Icon size={14} color={s.color ?? "#FF9F0A"} />
                    <div style={{ fontFamily: "JetBrains Mono, monospace", fontSize: "8px", color: "#a07848", marginTop: 2 }}>{s.label}</div>
                    <div style={{ fontFamily: "Nunito, sans-serif", fontWeight: 900, fontSize: "13px", color: s.color ?? "#fff4e0" }}>
                      {s.value}
                    </div>
                  </div>
                ))}
              </div>
            </Panel>
          </div>

          {/* ── RIGHT PANEL ── */}
          <div className="flex flex-col gap-3" style={{ width: 200, flexShrink: 0 }}>

            <Panel className="flex-shrink-0 p-4">
              <div style={{ fontFamily: "Nunito, sans-serif", fontWeight: 900, fontSize: "20px", color: "#fff4e0", lineHeight: 1.1, marginBottom: 4 }}>
                Ready to<br />
                <span style={{ color: "#FF9F0A" }}>Race?</span>
              </div>
              <div style={{ fontFamily: "JetBrains Mono, monospace", fontSize: "9px", color: "#a07848", marginBottom: 14, letterSpacing: "0.1em" }}>
                {diff.label.toUpperCase()} · {route.name.toUpperCase()}
              </div>

              <button
                className="w-full py-3 transition-all duration-100 hover:brightness-110 active:translate-y-[2px] flex items-center justify-center gap-2"
                style={{
                  background: "linear-gradient(180deg, #FFB13D 0%, #FF9F0A 50%, #FF6B35 100%)",
                  border: "2px solid #FF6B35",
                  borderRadius: RADIUS,
                  fontFamily: "Nunito, sans-serif", fontWeight: 900, fontSize: "15px",
                  color: "#1a1108",
                  boxShadow: "inset 0 2px 0 rgba(255,255,255,0.3), 0 4px 0 #8a3d12",
                  letterSpacing: "0.05em",
                }}
              >
                <IconPlay size={14} color="#1a1108" /> START RACE
              </button>
              <div className="flex gap-2 mt-2">
                <button
                  className="flex-1 py-2.5 transition-all"
                  style={{
                    background: "rgba(255,159,10,0.08)", border: "2px solid rgba(255,180,80,0.3)",
                    borderRadius: RADIUS,
                    fontFamily: "Nunito, sans-serif", fontWeight: 900, fontSize: "12px", color: "#FF9F0A",
                    boxShadow: "inset 0 -2px 0 rgba(0,0,0,0.25)",
                  }}
                >
                  Quick
                </button>
                <button
                  className="flex-1 py-2.5 transition-all"
                  style={{
                    background: "rgba(255,255,255,0.04)", border: "2px solid rgba(255,180,80,0.15)",
                    borderRadius: RADIUS,
                    fontFamily: "Nunito, sans-serif", fontWeight: 900, fontSize: "12px", color: "#a07848",
                    boxShadow: "inset 0 -2px 0 rgba(0,0,0,0.25)",
                  }}
                >
                  Save
                </button>
              </div>
            </Panel>

            <Panel className="flex-1 overflow-y-auto p-4" style={{ scrollbarWidth: "none" }}>
              <SectionHeading Icon={IconTrophy} title="Best Times" />
              <div className="space-y-1">
                {[
                  { rank: 1, name: "PHANTOM_X",    time: "2:14.3", medal: "#FFD700" },
                  { rank: 2, name: "BLAZE_44",     time: "2:16.8", medal: "#C0C0C0" },
                  { rank: 3, name: "NEON_RUSH",    time: "2:19.1", medal: "#CD7F32" },
                  { rank: 4, name: "ACE_DRIVER_77",time: "2:22.6", isPlayer: true },
                  { rank: 5, name: "DRIFT_KING",   time: "2:25.0" },
                  { rank: 6, name: "ROAD_SHARK",   time: "2:28.4" },
                  { rank: 7, name: "TURBO_ACE",    time: "2:31.2" },
                ].map(e => (
                  <div
                    key={e.rank}
                    className="flex items-center gap-2 py-1.5 px-2"
                    style={{
                      background: e.isPlayer ? "rgba(255,159,10,0.12)" : "transparent",
                      border: e.isPlayer ? "2px solid rgba(255,159,10,0.4)" : "2px solid transparent",
                      borderRadius: RADIUS,
                    }}
                  >
                    {e.medal ? (
                      <div style={{ width: 14, height: 14, background: e.medal, border: "1px solid #1a1108", borderRadius: RADIUS, flexShrink: 0 }} />
                    ) : (
                      <span style={{ fontFamily: "JetBrains Mono, monospace", fontSize: "10px", color: "#a07848", width: 14, textAlign: "center", flexShrink: 0 }}>
                        {e.rank}
                      </span>
                    )}
                    <span
                      className="flex-1 truncate"
                      style={{
                        fontFamily: "Nunito, sans-serif", fontWeight: e.isPlayer ? 900 : 700,
                        fontSize: "11px",
                        color: e.isPlayer ? "#FF9F0A" : e.medal ? "#fff4e0" : "#a07848",
                      }}
                    >
                      {e.name}
                    </span>
                    <span style={{ fontFamily: "JetBrains Mono, monospace", fontSize: "10px", color: "#a07848", flexShrink: 0 }}>
                      {e.time}
                    </span>
                  </div>
                ))}
              </div>

              <div className="mt-4">
                <SectionHeading Icon={IconStar} title="Achievements" />
                <div className="grid grid-cols-4 gap-1.5">
                  {[
                    { Icon: IconFlag,   t: "First Race",   u: true },
                    { Icon: IconBolt,   t: "Speed Demon",  u: true },
                    { Icon: IconTrophy, t: "Champion",     u: true },
                    { Icon: IconHeart,  t: "No Damage",    u: true },
                    { Icon: IconMoon,   t: "Night Owl",    u: true },
                    { Icon: IconFire,   t: "On Fire",      u: false },
                    { Icon: IconPolice, t: "Fugitive",     u: false },
                    { Icon: IconTarget, t: "Perfect",      u: false },
                  ].map((a, i) => (
                    <div
                      key={i}
                      title={a.t}
                      className="flex items-center justify-center cursor-pointer transition-all hover:translate-y-[-1px]"
                      style={{
                        width: 38, height: 38,
                        background: a.u ? "rgba(255,159,10,0.14)" : "rgba(255,255,255,0.03)",
                        border: `2px solid ${a.u ? "rgba(255,159,10,0.4)" : "rgba(255,255,255,0.08)"}`,
                        borderRadius: RADIUS,
                        opacity: a.u ? 1 : 0.35,
                        boxShadow: a.u ? "inset 0 -3px 0 rgba(0,0,0,0.3)" : "none",
                      }}
                    >
                      <a.Icon size={18} color={a.u ? "#FF9F0A" : "#a07848"} />
                    </div>
                  ))}
                </div>
              </div>
            </Panel>
          </div>
        </div>
      </div>

      <style>{`
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.2; }
        }
        ::-webkit-scrollbar { display: none; }
        * { scrollbar-width: none; }
        body { overflow: hidden; }
      `}</style>
    </div>
  );
}
