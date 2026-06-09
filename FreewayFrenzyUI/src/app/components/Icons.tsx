// Blocky pixel-style SVG icons — no emojis anywhere

type P = { size?: number; color?: string };
const def = (size = 14, color = "currentColor") => ({ size, color });

function Box({ children, size, color }: { children: React.ReactNode; size: number; color: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 16 16" fill={color} shapeRendering="crispEdges" style={{ display: "inline-block", verticalAlign: "middle" }}>
      {children}
    </svg>
  );
}

export const IconCar = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="2" y="7" width="12" height="5" />
      <rect x="4" y="4" width="8" height="3" />
      <rect x="5" y="5" width="2" height="2" fill="rgba(255,255,255,0.5)" />
      <rect x="9" y="5" width="2" height="2" fill="rgba(255,255,255,0.5)" />
      <rect x="1" y="9" width="1" height="2" />
      <rect x="14" y="9" width="1" height="2" />
      <rect x="3" y="12" width="3" height="2" fill="#000" />
      <rect x="10" y="12" width="3" height="2" fill="#000" />
    </Box>
  );
};

export const IconMap = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="1" y="3" width="4" height="10" />
      <rect x="6" y="2" width="4" height="10" opacity="0.7" />
      <rect x="11" y="3" width="4" height="10" />
      <rect x="3" y="6" width="1" height="1" fill="rgba(0,0,0,0.4)" />
      <rect x="8" y="5" width="1" height="1" fill="rgba(0,0,0,0.4)" />
      <rect x="13" y="8" width="1" height="1" fill="rgba(0,0,0,0.4)" />
    </Box>
  );
};

export const IconGear = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="6" y="1" width="4" height="2" />
      <rect x="6" y="13" width="4" height="2" />
      <rect x="1" y="6" width="2" height="4" />
      <rect x="13" y="6" width="2" height="4" />
      <rect x="4" y="4" width="8" height="8" />
      <rect x="6" y="6" width="4" height="4" fill="#1a1108" />
    </Box>
  );
};

export const IconPaint = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="2" y="3" width="10" height="6" />
      <rect x="3" y="9" width="8" height="2" />
      <rect x="6" y="11" width="2" height="3" />
      <rect x="5" y="14" width="4" height="1" />
      <rect x="11" y="4" width="2" height="2" fill="rgba(255,255,255,0.4)" />
    </Box>
  );
};

export const IconBolt = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="8" y="1" width="4" height="2" />
      <rect x="6" y="3" width="4" height="2" />
      <rect x="4" y="5" width="4" height="2" />
      <rect x="6" y="7" width="6" height="2" />
      <rect x="4" y="9" width="4" height="2" />
      <rect x="2" y="11" width="4" height="2" />
      <rect x="4" y="13" width="2" height="2" />
    </Box>
  );
};

export const IconTrophy = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="3" y="2" width="10" height="2" />
      <rect x="4" y="4" width="8" height="5" />
      <rect x="1" y="3" width="2" height="4" />
      <rect x="13" y="3" width="2" height="4" />
      <rect x="6" y="9" width="4" height="2" />
      <rect x="4" y="11" width="8" height="2" />
      <rect x="3" y="13" width="10" height="2" />
    </Box>
  );
};

export const IconFlag = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="3" y="1" width="2" height="14" />
      <rect x="5" y="2" width="2" height="2" />
      <rect x="9" y="2" width="2" height="2" />
      <rect x="7" y="4" width="2" height="2" />
      <rect x="11" y="4" width="2" height="2" />
      <rect x="5" y="6" width="2" height="2" />
      <rect x="9" y="6" width="2" height="2" />
      <rect x="5" y="2" width="8" height="6" fill="none" stroke={c} strokeWidth="1" />
    </Box>
  );
};

export const IconCheck = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="12" y="3" width="2" height="2" />
      <rect x="10" y="5" width="2" height="2" />
      <rect x="8" y="7" width="2" height="2" />
      <rect x="6" y="9" width="2" height="2" />
      <rect x="4" y="11" width="2" height="2" />
      <rect x="2" y="9" width="2" height="2" />
    </Box>
  );
};

export const IconSun = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="6" y="6" width="4" height="4" />
      <rect x="7" y="1" width="2" height="2" />
      <rect x="7" y="13" width="2" height="2" />
      <rect x="1" y="7" width="2" height="2" />
      <rect x="13" y="7" width="2" height="2" />
      <rect x="3" y="3" width="2" height="2" />
      <rect x="11" y="3" width="2" height="2" />
      <rect x="3" y="11" width="2" height="2" />
      <rect x="11" y="11" width="2" height="2" />
    </Box>
  );
};

export const IconDusk = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="5" y="7" width="6" height="3" />
      <rect x="6" y="6" width="4" height="1" />
      <rect x="1" y="10" width="14" height="1" />
      <rect x="7" y="2" width="2" height="2" opacity="0.6" />
      <rect x="3" y="4" width="2" height="2" opacity="0.5" />
      <rect x="11" y="4" width="2" height="2" opacity="0.5" />
    </Box>
  );
};

export const IconMoon = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="5" y="2" width="6" height="2" />
      <rect x="3" y="4" width="6" height="2" />
      <rect x="2" y="6" width="5" height="4" />
      <rect x="3" y="10" width="6" height="2" />
      <rect x="5" y="12" width="6" height="2" />
    </Box>
  );
};

export const IconRain = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="3" y="3" width="10" height="4" />
      <rect x="2" y="5" width="12" height="3" />
      <rect x="3" y="9" width="1" height="2" />
      <rect x="6" y="10" width="1" height="3" />
      <rect x="9" y="9" width="1" height="2" />
      <rect x="12" y="10" width="1" height="3" />
    </Box>
  );
};

export const IconPlay = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="3" y="2" width="2" height="12" />
      <rect x="5" y="4" width="2" height="8" />
      <rect x="7" y="6" width="2" height="4" />
      <rect x="9" y="7" width="2" height="2" />
    </Box>
  );
};

export const IconLap = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="4" y="2" width="8" height="2" />
      <rect x="2" y="4" width="2" height="8" />
      <rect x="12" y="4" width="2" height="8" />
      <rect x="4" y="12" width="8" height="2" />
      <rect x="6" y="6" width="4" height="4" />
    </Box>
  );
};

export const IconRuler = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="1" y="5" width="14" height="6" />
      <rect x="3" y="5" width="1" height="2" fill="#000" />
      <rect x="6" y="5" width="1" height="3" fill="#000" />
      <rect x="9" y="5" width="1" height="2" fill="#000" />
      <rect x="12" y="5" width="1" height="3" fill="#000" />
    </Box>
  );
};

export const IconShield = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="3" y="2" width="10" height="2" />
      <rect x="2" y="4" width="12" height="7" />
      <rect x="3" y="11" width="10" height="2" />
      <rect x="5" y="13" width="6" height="1" />
      <rect x="6" y="14" width="4" height="1" />
    </Box>
  );
};

export const IconAngry = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="3" y="3" width="3" height="2" />
      <rect x="10" y="3" width="3" height="2" />
      <rect x="3" y="7" width="3" height="2" />
      <rect x="10" y="7" width="3" height="2" />
      <rect x="4" y="11" width="8" height="2" />
    </Box>
  );
};

export const IconPolice = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="5" y="2" width="2" height="3" fill="#ff3b30" />
      <rect x="9" y="2" width="2" height="3" fill="#3b82f6" />
      <rect x="2" y="5" width="12" height="2" />
      <rect x="1" y="7" width="14" height="5" />
      <rect x="3" y="12" width="3" height="2" fill="#000" />
      <rect x="10" y="12" width="3" height="2" fill="#000" />
    </Box>
  );
};

export const IconStar = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="7" y="1" width="2" height="3" />
      <rect x="6" y="4" width="4" height="2" />
      <rect x="1" y="6" width="14" height="3" />
      <rect x="3" y="9" width="3" height="3" />
      <rect x="10" y="9" width="3" height="3" />
      <rect x="2" y="12" width="3" height="3" />
      <rect x="11" y="12" width="3" height="3" />
    </Box>
  );
};

export const IconFire = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="7" y="1" width="2" height="2" />
      <rect x="6" y="3" width="4" height="3" />
      <rect x="5" y="6" width="6" height="3" />
      <rect x="4" y="9" width="8" height="4" />
      <rect x="5" y="13" width="6" height="2" />
      <rect x="7" y="6" width="2" height="3" fill="rgba(255,255,255,0.5)" />
    </Box>
  );
};

export const IconHeart = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="3" y="3" width="3" height="2" />
      <rect x="10" y="3" width="3" height="2" />
      <rect x="2" y="5" width="12" height="3" />
      <rect x="3" y="8" width="10" height="2" />
      <rect x="5" y="10" width="6" height="2" />
      <rect x="7" y="12" width="2" height="2" />
    </Box>
  );
};

export const IconTarget = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="5" y="1" width="6" height="2" />
      <rect x="3" y="3" width="10" height="2" />
      <rect x="1" y="5" width="14" height="6" />
      <rect x="3" y="11" width="10" height="2" />
      <rect x="5" y="13" width="6" height="2" />
      <rect x="6" y="6" width="4" height="4" fill="#1a1108" />
      <rect x="7" y="7" width="2" height="2" fill={c} />
    </Box>
  );
};

export const IconJoypad = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="1" y="5" width="14" height="7" />
      <rect x="3" y="7" width="2" height="3" fill="#1a1108" />
      <rect x="2" y="8" width="4" height="1" fill="#1a1108" />
      <rect x="10" y="7" width="2" height="2" fill="#1a1108" />
      <rect x="12" y="9" width="2" height="2" fill="#1a1108" />
    </Box>
  );
};

export const IconTrafficLight = ({ size, color }: P = {}) => {
  const { size: s, color: c } = def(size, color);
  return (
    <Box size={s} color={c}>
      <rect x="5" y="1" width="6" height="13" />
      <rect x="4" y="2" width="8" height="3" fill="#ff3b30" />
      <rect x="4" y="6" width="8" height="3" fill="#FF9F0A" />
      <rect x="4" y="10" width="8" height="3" fill="#30d158" />
      <rect x="7" y="14" width="2" height="1" />
    </Box>
  );
};
