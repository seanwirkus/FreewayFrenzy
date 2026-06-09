export function PolyBackground() {
  return (
    <div className="fixed inset-0 overflow-hidden pointer-events-none" style={{ zIndex: 0 }}>
      <svg
        className="absolute inset-0 w-full h-full"
        xmlns="http://www.w3.org/2000/svg"
        preserveAspectRatio="xMidYMid slice"
      >
        <defs>
          <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style={{ stopColor: "#0d0f14", stopOpacity: 1 }} />
            <stop offset="100%" style={{ stopColor: "#0a1020", stopOpacity: 1 }} />
          </linearGradient>
        </defs>
        <rect width="100%" height="100%" fill="url(#grad1)" />

        {/* Low-poly triangular facets */}
        <polygon points="0,0 320,0 180,200" fill="rgba(200,255,0,0.025)" />
        <polygon points="320,0 600,0 600,180 420,280" fill="rgba(0,229,255,0.02)" />
        <polygon points="0,200 180,200 0,450" fill="rgba(200,255,0,0.015)" />
        <polygon points="600,180 800,0 800,300" fill="rgba(200,255,0,0.02)" />
        <polygon points="800,300 800,600 600,500" fill="rgba(0,229,255,0.025)" />
        <polygon points="0,450 180,200 350,500 0,700" fill="rgba(0,229,255,0.015)" />
        <polygon points="350,500 180,200 600,180 700,600" fill="rgba(200,255,0,0.01)" />
        <polygon points="700,600 600,500 800,600 800,800" fill="rgba(200,255,0,0.02)" />
        <polygon points="0,700 350,500 300,900 0,900" fill="rgba(0,229,255,0.015)" />
        <polygon points="300,900 350,500 700,600 600,900" fill="rgba(200,255,0,0.015)" />
        <polygon points="600,900 700,600 800,800 800,900" fill="rgba(0,229,255,0.02)" />

        {/* Top-right cluster */}
        <polygon points="900,0 1200,0 1100,150 950,180" fill="rgba(200,255,0,0.02)" />
        <polygon points="1100,150 1200,0 1400,0 1300,200" fill="rgba(0,229,255,0.025)" />
        <polygon points="1300,200 1400,0 1600,0 1600,250" fill="rgba(200,255,0,0.015)" />
        <polygon points="950,180 1100,150 1200,400 900,350" fill="rgba(0,229,255,0.02)" />
        <polygon points="1200,400 1100,150 1300,200 1400,500" fill="rgba(200,255,0,0.02)" />
        <polygon points="1400,500 1300,200 1600,250 1600,600" fill="rgba(0,229,255,0.015)" />

        {/* Crossroad grid lines */}
        <line x1="0" y1="50%" x2="100%" y2="50%" stroke="rgba(200,255,0,0.04)" strokeWidth="1" />
        <line x1="50%" y1="0" x2="50%" y2="100%" stroke="rgba(200,255,0,0.04)" strokeWidth="1" />

        {/* Corner diamond accent */}
        <polygon points="40,40 80,0 120,40 80,80" fill="none" stroke="rgba(200,255,0,0.15)" strokeWidth="1" />
        <polygon points="40,40 80,0 120,40 80,80" fill="rgba(200,255,0,0.03)" />
      </svg>
    </div>
  );
}
