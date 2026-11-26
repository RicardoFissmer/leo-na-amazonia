import React from "react";
import {
  AbsoluteFill,
  Audio,
  Img,
  OffthreadVideo,
  Sequence,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import dados from "./apresentacao.json";
import { FONTE, Mata, Moeda, Pixel, Vinheta } from "./pecas";

/**
 * Vídeo de apresentação final (gameplay comentado, ~11 min).
 * A linha do tempo vem de src/apresentacao.json (gerado por apresentacao/montar_timeline.py).
 * `narracao` = false gera a versão sem a voz sintetizada (para gravar a própria voz por cima).
 */
export type Props = { narracao: boolean };

type Segmento = {
  tipo: string;
  ini: number;
  dur: number;
  src?: string;
  de?: number;
  som?: boolean;
  etiqueta?: string;
  cartoes?: number[];
  troca?: number;
  antes_de?: number;
  depois_de?: number;
  fusao?: number;
};
type FalaT = { id: string; ini: number; dur: number; texto: string };

const SEGMENTOS = dados.segmentos as Segmento[];
const FALAS = dados.falas as FalaT[];
const CAPITULOS = dados.capitulos as { texto: string; sub: string; ini: number }[];

const VERDE = "#163d28";
const AMARELO = "#ffd21f";
const CREME = "#fff3d6";

const suave = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

/** 1 quando há narração tocando, 0 quando não; rampa de 8 quadros nas bordas. */
const abafar = (frame: number) => {
  let v = 0;
  for (const f of FALAS) {
    const fim = f.ini + f.dur;
    if (frame >= f.ini && frame < fim) return 1;
    if (frame < f.ini && frame > f.ini - 8) v = Math.max(v, 1 - (f.ini - frame) / 8);
    if (frame >= fim && frame < fim + 10) v = Math.max(v, 1 - (frame - fim) / 10);
  }
  return v;
};

const Painel: React.FC<{ style?: React.CSSProperties; children: React.ReactNode }> = ({ style, children }) => (
  <div
    style={{
      background: "rgba(22,61,40,0.94)",
      border: `6px solid ${AMARELO}`,
      borderRadius: 26,
      boxShadow: "0 18px 0 rgba(0,0,0,0.25)",
      color: CREME,
      fontFamily: FONTE,
      ...style,
    }}
  >
    {children}
  </div>
);

const Entrar: React.FC<{ de: number; children: React.ReactNode; style?: React.CSSProperties }> = ({
  de,
  children,
  style,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const p = spring({ frame: frame - de, fps, config: { damping: 14, stiffness: 140 } });
  if (frame < de) return null;
  return (
    <div style={{ opacity: Math.min(1, p * 1.4), transform: `translateY(${(1 - p) * 40}px)`, ...style }}>
      {children}
    </div>
  );
};

/** Léo animado a partir da folha de sprites do jogo (16x24, 13 quadros). */
const LeoSprite: React.FC<{ escala: number; quadros: number[]; vel?: number; style?: React.CSSProperties }> = ({
  escala,
  quadros,
  vel = 5,
  style,
}) => {
  const frame = useCurrentFrame();
  const q = quadros[Math.floor(frame / vel) % quadros.length];
  return (
    <div
      style={{
        width: 16 * escala,
        height: 24 * escala,
        backgroundImage: `url(${staticFile("img/leo_sheet.png")})`,
        backgroundSize: `${208 * escala}px ${24 * escala}px`,
        backgroundPosition: `${-q * 16 * escala}px 0px`,
        imageRendering: "pixelated",
        ...style,
      }}
    />
  );
};

const LeoAntigo: React.FC<{ escala: number; style?: React.CSSProperties }> = ({ escala, style }) => {
  const frame = useCurrentFrame();
  const q = Math.floor(frame / 7) % 3;
  return (
    <div
      style={{
        width: 12 * escala,
        height: 16 * escala,
        backgroundImage: `url(${staticFile("img/antes/leo_antigo.png")})`,
        backgroundSize: `${36 * escala}px ${16 * escala}px`,
        backgroundPosition: `${-q * 12 * escala}px 0px`,
        imageRendering: "pixelated",
        ...style,
      }}
    />
  );
};

// ---------------------------------------------------------------- trechos

const Video: React.FC<{ s: Segmento; narracao: boolean }> = ({ s, narracao }) => {
  const frame = useCurrentFrame();
  const volume = (f: number) => {
    if (!s.som) return 0;
    const d = narracao ? abafar(s.ini + f) : 0;
    return narracao ? 0.7 - 0.5 * d : 0.45;
  };
  const video = (
    <OffthreadVideo
      src={staticFile(s.src!)}
      startFrom={s.de}
      muted={!s.som}
      volume={volume}
      style={{ width: "100%", height: "100%" }}
    />
  );
  if (!s.etiqueta) {
    const op = s.fusao ? interpolate(frame, [0, s.fusao], [0, 1], suave) : 1;
    return <AbsoluteFill style={{ opacity: op }}>{video}</AbsoluteFill>;
  }
  const antes = s.etiqueta.startsWith("ANTES");
  return (
    <AbsoluteFill style={{ background: "#0c2417" }}>
      <div
        style={{
          position: "absolute",
          left: (1920 - 1600) / 2,
          top: 118,
          width: 1600,
          height: 900,
          borderRadius: 18,
          overflow: "hidden",
          border: `6px solid ${antes ? "#c9c9c9" : AMARELO}`,
          boxShadow: "0 20px 0 rgba(0,0,0,0.35)",
          filter: antes ? "saturate(0.85)" : undefined,
        }}
      >
        {video}
      </div>
      <div
        style={{
          position: "absolute",
          top: 26,
          left: 0,
          width: 1920,
          textAlign: "center",
          fontFamily: FONTE,
          fontWeight: 800,
          fontSize: 54,
          color: antes ? "#e9e9e9" : AMARELO,
          textShadow: "0 5px 0 rgba(0,0,0,0.45)",
        }}
      >
        {s.etiqueta}
      </div>
    </AbsoluteFill>
  );
};

const Abertura: React.FC<{ s: Segmento }> = ({ s }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const a02 = FALAS.find((f) => f.id === "a02")!.ini - s.ini;
  const a03 = FALAS.find((f) => f.id === "a03")!.ini - s.ini;
  const logo = spring({ frame: frame - 6, fps, config: { damping: 12, stiffness: 120 } });
  const subir = interpolate(frame, [a02 - 10, a02 + 10], [0, -90], suave);
  const itens = ["A proposta", "A história", "Primeira vez jogando", "Um desafio completo", "Os ajustes"];
  return (
    <AbsoluteFill>
      <Mata pan={frame * 1.2} escuro={0.25} />
      <div
        style={{
          position: "absolute",
          left: (1920 - 194 * 6) / 2,
          top: 120 + subir,
          transform: `scale(${logo})`,
          transformOrigin: "50% 50%",
        }}
      >
        <Pixel src="img/logo.png" w={194 * 6} h={74 * 6} />
      </div>
      <Entrar de={a02} style={{ position: "absolute", left: 0, width: 1920, top: 520, display: "flex", justifyContent: "center" }}>
        <Painel style={{ padding: "26px 60px", textAlign: "center" }}>
          <div style={{ fontSize: 66, fontWeight: 800, color: AMARELO, lineHeight: 1.1 }}>Ricardo Fissmer Batista</div>
          <div style={{ fontSize: 40, fontWeight: 700, marginTop: 6 }}>Engenharia de Software · projeto individual</div>
        </Painel>
      </Entrar>
      <div style={{ position: "absolute", top: 790, left: 0, width: 1920, display: "flex", justifyContent: "center", gap: 22 }}>
        {itens.map((t, i) => (
          <Entrar key={t} de={a03 + 20 + i * 30}>
            <div
              style={{
                fontFamily: FONTE,
                fontWeight: 800,
                fontSize: 34,
                color: VERDE,
                background: AMARELO,
                borderRadius: 40,
                padding: "8px 26px",
                boxShadow: "0 6px 0 rgba(0,0,0,0.3)",
              }}
            >
              {i + 1}. {t}
            </div>
          </Entrar>
        ))}
      </div>
      <Vinheta forca={0.4} />
    </AbsoluteFill>
  );
};

const Proposta: React.FC<{ s: Segmento }> = ({ s }) => {
  const frame = useCurrentFrame();
  const linhas = [
    ["P", "Plataforma 2D educativo", "pixel art · Godot Engine 4"],
    ["6", "Crianças de 6 a 10 anos", "em fase de alfabetização"],
    ["A", "Coletar letras e montar nomes", "arara, onça, boto, tucano, capivara"],
  ];
  const sair = interpolate(frame, [s.dur - 12, s.dur], [1, 0], suave);
  return (
    <AbsoluteFill style={{ opacity: sair }}>
      <AbsoluteFill style={{ background: "rgba(5,25,14,0.55)", backdropFilter: "blur(7px)" }} />
      <Painel style={{ position: "absolute", left: 360, top: 110, width: 1200, padding: "34px 50px" }}>
        <div style={{ fontSize: 62, fontWeight: 800, color: AMARELO, marginBottom: 10 }}>A proposta</div>
        {linhas.map(([l, t, sub], i) => (
          <Entrar key={t} de={s.cartoes![i]} style={{ display: "flex", alignItems: "center", gap: 30, margin: "20px 0" }}>
            <div style={{ position: "relative", width: 110, height: 110, flex: "none" }}>
              <Moeda letra={l} tam={110} />
            </div>
            <div>
              <div style={{ fontSize: 54, fontWeight: 800, lineHeight: 1.05 }}>{t}</div>
              <div style={{ fontSize: 38, fontWeight: 700, color: "#bfe8cf" }}>{sub}</div>
            </div>
          </Entrar>
        ))}
      </Painel>
    </AbsoluteFill>
  );
};

const Ajustes: React.FC<{ s: Segmento }> = ({ s }) => {
  const frame = useCurrentFrame();
  const j02 = FALAS.find((f) => f.id === "j02")!.ini - s.ini;
  const itens = [
    { de: j02 + 10, t: "Na minha turma não houve o Dia do Analista", sub: "então não recebi ficha técnica de outra equipe" },
    { de: j02 + 190, t: "Base dos ajustes: aula “Quem vai querer jogar?”", sub: "história, tutorial e leitura para o público" },
    { de: j02 + 330, t: "E os meus próprios testes jogando", sub: "o que estava confuso ou difícil de ler" },
  ];
  return (
    <AbsoluteFill>
      <Mata pan={frame * 0.8} escuro={0.45} desfoque={3} />
      <Painel style={{ position: "absolute", left: 210, top: 150, width: 1500, padding: "40px 56px" }}>
        <div style={{ fontSize: 72, fontWeight: 800, color: AMARELO }}>De onde vieram os ajustes</div>
        {itens.map((it) => (
          <Entrar key={it.t} de={it.de} style={{ marginTop: 34 }}>
            <div style={{ fontSize: 52, fontWeight: 800, lineHeight: 1.1 }}>• {it.t}</div>
            <div style={{ fontSize: 38, fontWeight: 700, color: "#bfe8cf", marginLeft: 40 }}>{it.sub}</div>
          </Entrar>
        ))}
      </Painel>
      <Vinheta />
    </AbsoluteFill>
  );
};

const Coluna: React.FC<{ titulo: string; cor: string; legenda: string; children: React.ReactNode; x: number }> = ({
  titulo,
  cor,
  legenda,
  children,
  x,
}) => (
  <div style={{ position: "absolute", left: x, top: 90, width: 760, textAlign: "center", fontFamily: FONTE }}>
    <div style={{ fontSize: 64, fontWeight: 800, color: cor, textShadow: "0 5px 0 rgba(0,0,0,0.4)" }}>{titulo}</div>
    <div
      style={{
        height: 500,
        marginTop: 16,
        background: "rgba(10,36,22,0.75)",
        border: `6px solid ${cor}`,
        borderRadius: 26,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 40,
      }}
    >
      {children}
    </div>
    <div style={{ fontSize: 40, fontWeight: 700, color: CREME, marginTop: 18, textShadow: "0 4px 0 rgba(0,0,0,0.4)" }}>
      {legenda}
    </div>
  </div>
);

const Sprites: React.FC<{ s: Segmento }> = ({ s }) => {
  const frame = useCurrentFrame();
  const animais = frame >= s.troca!;
  return (
    <AbsoluteFill>
      <Mata pan={frame * 1.5} escuro={0.4} desfoque={2} />
      {!animais ? (
        <>
          <Coluna x={150} titulo="ANTES" cor="#d8d8d8" legenda="12 × 16 pixels · 3 quadros">
            <LeoAntigo escala={22} />
          </Coluna>
          <Coluna x={1010} titulo="AGORA" cor={AMARELO} legenda="16 × 24 pixels · 13 quadros">
            <LeoSprite escala={20} quadros={[3, 4, 5, 6, 7, 8]} vel={4} />
          </Coluna>
          <Entrar de={150} style={{ position: "absolute", left: 1178, top: 790 }}>
            <div style={{ display: "flex", gap: 26 }}>
              {[0, 9, 10, 11, 12].map((q) => (
                <LeoSprite key={q} escala={4} quadros={[q]} />
              ))}
            </div>
          </Entrar>
        </>
      ) : (
        <>
          <Coluna x={150} titulo="ANTES" cor="#d8d8d8" legenda="64 × 48 pixels">
            <Pixel src="img/antes/arara.png" w={64 * 5} h={48 * 5} />
          </Coluna>
          <Coluna x={1010} titulo="AGORA" cor={AMARELO} legenda="96 × 72 pixels, com cenário">
            <Pixel src="img/antes/arara_nova.png" w={96 * 3.4} h={72 * 3.4} />
          </Coluna>
        </>
      )}
      <Vinheta />
    </AbsoluteFill>
  );
};

const Menus: React.FC<{ s: Segmento }> = ({ s }) => (
  <AbsoluteFill style={{ background: "#0c2417" }}>
    {[
      { x: 40, src: "clipes/antes.mp4", de: s.antes_de, t: "ANTES · v1.3", cor: "#d8d8d8" },
      { x: 990, src: "clipes/live.mp4", de: s.depois_de, t: "AGORA · v1.7", cor: AMARELO },
    ].map((v) => (
      <div key={v.t} style={{ position: "absolute", left: v.x, top: 200, width: 890 }}>
        <div
          style={{
            fontFamily: FONTE,
            fontWeight: 800,
            fontSize: 56,
            color: v.cor,
            textAlign: "center",
            marginBottom: 16,
            textShadow: "0 5px 0 rgba(0,0,0,0.4)",
          }}
        >
          {v.t}
        </div>
        <div style={{ width: 890, height: 500, borderRadius: 16, overflow: "hidden", border: `6px solid ${v.cor}` }}>
          <OffthreadVideo src={staticFile(v.src)} startFrom={v.de} muted style={{ width: "100%", height: "100%" }} />
        </div>
      </div>
    ))}
  </AbsoluteFill>
);

const Web: React.FC<{ s: Segmento }> = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const p = spring({ frame, fps, config: { damping: 14, stiffness: 120 } });
  return (
    <AbsoluteFill>
      <Mata pan={frame} escuro={0.5} desfoque={3} />
      <div
        style={{
          position: "absolute",
          top: 40,
          width: 1920,
          textAlign: "center",
          fontFamily: FONTE,
          fontWeight: 800,
          fontSize: 66,
          color: AMARELO,
          textShadow: "0 5px 0 rgba(0,0,0,0.4)",
        }}
      >
        Jogue direto no navegador
      </div>
      <Img
        src={staticFile("img/pages.png")}
        style={{
          position: "absolute",
          left: (1920 - 1456) / 2,
          top: 150,
          width: 1456,
          height: 735,
          borderRadius: 14,
          boxShadow: "0 24px 0 rgba(0,0,0,0.35)",
          transform: `scale(${0.9 + 0.1 * p})`,
          opacity: p,
        }}
      />
    </AbsoluteFill>
  );
};

const Encerramento: React.FC<{ s: Segmento }> = ({ s }) => {
  const frame = useCurrentFrame();
  const e02 = FALAS.find((f) => f.id === "e02")!.ini - s.ini;
  const e03 = FALAS.find((f) => f.id === "e03")!.ini - s.ini;
  const links = [
    ["Repositório (código, GDD, instruções)", "github.com/RicardoFissmer/leo-na-amazonia"],
    ["Jogar no navegador", "ricardofissmer.github.io/leo-na-amazonia"],
    ["Versão para Windows", "github.com/RicardoFissmer/leo-na-amazonia/releases"],
  ];
  const fade = interpolate(frame, [s.dur - 40, s.dur], [1, 0], suave);
  return (
    <AbsoluteFill style={{ opacity: fade, background: "#000" }}>
      <Mata pan={frame * 1.2} escuro={0.35} />
      <div style={{ position: "absolute", left: (1920 - 194 * 3.2) / 2, top: 24 }}>
        <Pixel src="img/logo.png" w={194 * 3.2} h={74 * 3.2} />
      </div>
      <Painel style={{ position: "absolute", left: 230, top: 290, width: 1460, padding: "20px 50px" }}>
        {links.map(([t, url], i) => (
          <Entrar key={url} de={i === 0 ? 10 : e02 + (i - 1) * 60} style={{ margin: "14px 0" }}>
            <div style={{ fontSize: 38, fontWeight: 700, color: "#bfe8cf" }}>{t}</div>
            <div style={{ fontSize: 54, fontWeight: 800, color: AMARELO, lineHeight: 1.1 }}>{url}</div>
          </Entrar>
        ))}
      </Painel>
      <Entrar de={e03} style={{ position: "absolute", left: 0, width: 1920, top: 760, textAlign: "center" }}>
        <div style={{ fontFamily: FONTE, fontWeight: 800, fontSize: 80, color: CREME, textShadow: "0 6px 0 rgba(0,0,0,0.5)" }}>
          Obrigado!
        </div>
      </Entrar>
      <div style={{ position: "absolute", left: interpolate(frame, [0, s.dur], [-120, 1960]), top: 800 }}>
        <LeoSprite escala={5} quadros={[3, 4, 5, 6, 7, 8]} vel={4} />
      </div>
    </AbsoluteFill>
  );
};

// ---------------------------------------------------------------- sobreposições

const Legenda: React.FC = () => {
  const frame = useCurrentFrame();
  const f = FALAS.find((x) => frame >= x.ini && frame < x.ini + x.dur);
  if (!f) return null;
  const op = interpolate(frame, [f.ini, f.ini + 5, f.ini + f.dur - 5, f.ini + f.dur], [0, 1, 1, 0], suave);
  return (
    <div style={{ position: "absolute", left: 0, width: 1920, bottom: 34, display: "flex", justifyContent: "center", opacity: op }}>
      <div
        style={{
          maxWidth: 1560,
          background: "rgba(0,0,0,0.72)",
          borderRadius: 16,
          padding: "10px 30px 12px",
          fontFamily: FONTE,
          fontWeight: 700,
          fontSize: 40,
          lineHeight: 1.22,
          color: "#ffffff",
          textAlign: "center",
        }}
      >
        {f.texto}
      </div>
    </div>
  );
};

const Capitulo: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const c = [...CAPITULOS].reverse().find((x) => frame >= x.ini && frame < x.ini + 120);
  if (!c) return null;
  const p = spring({ frame: frame - c.ini, fps, config: { damping: 15, stiffness: 130 } });
  const sair = interpolate(frame, [c.ini + 100, c.ini + 120], [0, 1], suave);
  const x = -700 + 740 * p - 760 * sair;
  return (
    <div style={{ position: "absolute", left: x, top: 610, fontFamily: FONTE }}>
      <div
        style={{
          background: AMARELO,
          color: VERDE,
          fontWeight: 800,
          fontSize: 56,
          padding: "6px 34px 2px 30px",
          borderRadius: "0 18px 0 0",
          boxShadow: "0 6px 0 rgba(0,0,0,0.3)",
        }}
      >
        {c.texto}
      </div>
      {c.sub ? (
        <div
          style={{
            background: "rgba(22,61,40,0.95)",
            color: CREME,
            fontWeight: 700,
            fontSize: 34,
            padding: "4px 34px 6px 30px",
            borderRadius: "0 0 18px 0",
            display: "inline-block",
          }}
        >
          {c.sub}
        </div>
      ) : null}
    </div>
  );
};

export const Apresentacao: React.FC<Props> = ({ narracao }) => {
  const total = dados.total;
  const musica = (f: number) => {
    const entrada = interpolate(f, [0, 45], [0, 1], suave);
    const saida = interpolate(f, [total - 90, total - 10], [1, 0], suave);
    const nivel = narracao ? 0.11 - 0.07 * abafar(f) : 0.06;
    return nivel * entrada * saida;
  };
  return (
    <AbsoluteFill style={{ background: "#000" }}>
      {SEGMENTOS.map((s, i) => (
        <Sequence key={i} from={s.ini} durationInFrames={s.dur} layout="none">
          <AbsoluteFill>
            {s.tipo === "video" ? <Video s={s} narracao={narracao} /> : null}
            {s.tipo === "abertura" ? <Abertura s={s} /> : null}
            {s.tipo === "proposta" ? <Proposta s={s} /> : null}
            {s.tipo === "ajustes" ? <Ajustes s={s} /> : null}
            {s.tipo === "sprites" ? <Sprites s={s} /> : null}
            {s.tipo === "menus" ? <Menus s={s} /> : null}
            {s.tipo === "web" ? <Web s={s} /> : null}
            {s.tipo === "encerramento" ? <Encerramento s={s} /> : null}
          </AbsoluteFill>
        </Sequence>
      ))}
      <Capitulo />
      {narracao ? <Legenda /> : null}
      {narracao
        ? FALAS.map((f) => (
            <Sequence key={f.id} from={f.ini} durationInFrames={f.dur + 4} layout="none">
              <Audio src={staticFile(`voz/${f.id}.wav`)} volume={1} />
            </Sequence>
          ))
        : null}
      <Audio src={staticFile("audio/musica.ogg")} loop volume={musica} />
    </AbsoluteFill>
  );
};
