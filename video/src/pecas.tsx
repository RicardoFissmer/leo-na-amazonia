import React from "react";
import { AbsoluteFill, Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import "@fontsource/baloo-2/700.css";
import "@fontsource/baloo-2/800.css";

export const FONTE = "'Baloo 2', sans-serif";
export const TINTA = "#2a150a";
export const CPS = 26; // letras por segundo que aparecem no balão (ritmo de leitura de criança)

/** Imagem de pixel art ampliada sem borrar. */
export const Pixel: React.FC<{ src: string; w: number; h: number; style?: React.CSSProperties }> = ({
  src,
  w,
  h,
  style,
}) => (
  <Img
    src={staticFile(src)}
    style={{ width: w, height: h, imageRendering: "pixelated", display: "block", ...style }}
  />
);

export type Fala = {
  ini: number;
  dur: number;
  texto: string;
  expressao: "normal" | "falando" | "piscar" | "feliz" | "medo" | "determinado";
};

/** Quantas letras já apareceram na fala (efeito máquina de escrever). */
export const letrasVisiveis = (frame: number, f: Fala) =>
  Math.max(0, Math.floor(((frame - f.ini) / 30) * CPS));

const falaAtiva = (frame: number, falas: Fala[]) => falas.find((f) => frame >= f.ini && frame < f.ini + f.dur);

/**
 * Retrato do Léo que fala: abre e fecha a boca enquanto o texto aparece,
 * pisca a cada 1,5-2,3 s (4 quadros) e respira de leve.
 */
export const Retrato: React.FC<{
  falas: Fala[];
  escala: number;
  x: number;
  y: number;
  base?: Fala["expressao"];
  entrada?: number;
  espelhar?: boolean;
}> = ({ falas, escala, x, y, base = "normal", entrada = 0, espelhar = false }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const fala = falaAtiva(frame, falas);
  let expr: Fala["expressao"] = fala ? fala.expressao : base;
  const digitando = fala && letrasVisiveis(frame, fala) < tamanhoTexto(fala.texto);
  if (digitando && (expr === "normal" || expr === "determinado") && Math.floor(frame / 4) % 2 === 0) {
    expr = "falando";
  }
  // piscadas em intervalos que variam (1,5 s a 2,3 s)
  const ciclo = 45 + ((Math.floor(frame / 69) * 37) % 24);
  if (!digitando && (expr === "normal" || expr === "determinado") && frame % ciclo < 4) {
    expr = "piscar";
  }
  const pop = spring({ frame: frame - entrada, fps, config: { damping: 12, stiffness: 160 } });
  const respira = Math.sin(frame / 14) * escala * 0.6;
  const lado = 64 * escala;
  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y + respira,
        width: lado,
        height: lado,
        transform: `scale(${pop}) ${espelhar ? "scaleX(-1)" : ""}`,
        transformOrigin: "50% 100%",
        filter: "drop-shadow(0 18px 0 rgba(0,0,0,0.25))",
      }}
    >
      <Pixel src={`leo/${expr}.png`} w={lado} h={lado} />
    </div>
  );
};

/** Texto com trechos entre [colchetes] em destaque laranja. */
const Destacado: React.FC<{ texto: string; ate: number }> = ({ texto, ate }) => {
  // cada letra recebe uma cor: destaque, normal ou transparente (ainda não "digitada").
  // As letras transparentes ocupam espaço, então o balão já nasce do tamanho final.
  const letras: { c: string; cor: string }[] = [];
  let destaque = false;
  for (const c of texto) {
    if (c === "[" || c === "]") {
      destaque = c === "[";
      continue;
    }
    const visivel = letras.length < ate;
    letras.push({ c, cor: !visivel ? "transparent" : destaque ? "#d9640a" : TINTA });
  }
  const partes: React.ReactNode[] = [];
  let i = 0;
  while (i < letras.length) {
    let j = i;
    while (j < letras.length && letras[j].cor === letras[i].cor) j++;
    partes.push(
      <span key={i} style={{ color: letras[i].cor }}>
        {letras
          .slice(i, j)
          .map((l) => l.c)
          .join("")}
      </span>,
    );
    i = j;
  }
  return <>{partes}</>;
};

/** Tamanho do texto sem os colchetes de destaque. */
export const tamanhoTexto = (texto: string) => texto.replace(/[[\]]/g, "").length;

/** Balão de fala com cauda apontando para o Léo; o texto aparece letra a letra. */
export const Balao: React.FC<{
  fala: Fala;
  x: number;
  y: number;
  largura: number;
  tamanho?: number;
  cauda?: "esquerda" | "baixo-esquerda" | "nenhuma";
}> = ({ fala, x, y, largura, tamanho = 58, cauda = "esquerda" }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  if (frame < fala.ini || frame >= fala.ini + fala.dur) return null;
  const entrar = spring({ frame: frame - fala.ini, fps, config: { damping: 11, stiffness: 220 } });
  const sair = interpolate(frame, [fala.ini + fala.dur - 6, fala.ini + fala.dur], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const ate = letrasVisiveis(frame, fala);
  const escala = Math.min(entrar, 1) * sair + (1 - sair) * 0.85;
  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        maxWidth: largura,
        opacity: sair,
        transform: `scale(${escala})`,
        transformOrigin: cauda === "esquerda" ? "0% 50%" : "0% 100%",
      }}
    >
      <div
        style={{
          background: "#fffdf6",
          border: `8px solid ${TINTA}`,
          borderRadius: 34,
          padding: "22px 34px 26px",
          boxShadow: "0 12px 0 rgba(0,0,0,0.28)",
          display: "inline-block",
          fontFamily: FONTE,
          fontWeight: 800,
          fontSize: tamanho,
          lineHeight: 1.12,
          color: TINTA,
          position: "relative",
        }}
      >
        <Destacado texto={fala.texto} ate={ate} />
        {cauda === "nenhuma" ? null : (
          <div
            style={{
              position: "absolute",
              width: 0,
              height: 0,
              ...(cauda === "esquerda"
                ? {
                    left: -46,
                    top: "50%",
                    marginTop: -26,
                    borderTop: "26px solid transparent",
                    borderBottom: "26px solid transparent",
                    borderRight: `46px solid ${TINTA}`,
                  }
                : {
                    left: 60,
                    bottom: -52,
                    borderLeft: "26px solid transparent",
                    borderRight: "26px solid transparent",
                    borderTop: `52px solid ${TINTA}`,
                  }),
            }}
          />
        )}
      </div>
    </div>
  );
};

/** Fundo da mata montado com as camadas do próprio jogo (parallax + desfoque nas camadas de trás). */
export const Mata: React.FC<{ pan: number; desfoque?: number; chao?: boolean; escuro?: number }> = ({
  pan,
  desfoque = 0,
  chao = true,
  escuro = 0,
}) => {
  const E = 6; // 1 pixel do jogo = 6 pixels do vídeo
  const camada = (src: string, fator: number, alt: number, top: number, blur: number) => (
    <div
      style={{
        position: "absolute",
        left: 0,
        top,
        width: 1920,
        height: alt * E,
        backgroundImage: `url(${staticFile(src)})`,
        backgroundRepeat: "repeat-x",
        backgroundSize: `${640 * E}px ${alt * E}px`,
        backgroundPosition: `${-pan * fator}px 0px`,
        imageRendering: "pixelated",
        filter: blur ? `blur(${blur}px)` : undefined,
      }}
    />
  );
  return (
    <AbsoluteFill style={{ background: "#8fd9b0", overflow: "hidden" }}>
      {camada("jogo/bg_far.png", 0.15, 180, 0, desfoque * 1.4)}
      {camada("jogo/bg_mid.png", 0.4, 180, 0, desfoque)}
      {camada("jogo/bg_canopy.png", 0.8, 90, 0, desfoque * 0.6)}
      {chao ? (
        <>
          <div
            style={{
              position: "absolute",
              left: 0,
              top: 144 * E,
              width: 1920,
              height: 16 * E,
              backgroundImage: `url(${staticFile("jogo/ground.png")})`,
              backgroundSize: `${16 * E}px ${16 * E}px`,
              backgroundPosition: `${-pan}px 0px`,
              imageRendering: "pixelated",
            }}
          />
          <div
            style={{
              position: "absolute",
              left: 0,
              top: 160 * E,
              width: 1920,
              height: 20 * E,
              backgroundImage: `url(${staticFile("jogo/dirt.png")})`,
              backgroundSize: `${16 * E}px ${16 * E}px`,
              backgroundPosition: `${-pan}px 0px`,
              imageRendering: "pixelated",
            }}
          />
        </>
      ) : null}
      {escuro ? <AbsoluteFill style={{ background: `rgba(4,20,12,${escuro})` }} /> : null}
    </AbsoluteFill>
  );
};

/** Vinheta leve em volta da imagem (mesma ideia do efeito do jogo). */
export const Vinheta: React.FC<{ forca?: number }> = ({ forca = 0.45 }) => (
  <AbsoluteFill
    style={{
      background: `radial-gradient(ellipse at center, rgba(0,0,0,0) 55%, rgba(0,0,0,${forca}) 100%)`,
      pointerEvents: "none",
    }}
  />
);

/** Moeda do jogo com uma letra. */
export const Moeda: React.FC<{ letra: string; tam: number; style?: React.CSSProperties }> = ({ letra, tam, style }) => (
  <div style={{ position: "absolute", width: tam, height: tam, ...style }}>
    <Pixel src="jogo/coin.png" w={tam} h={tam} />
    <div
      style={{
        position: "absolute",
        inset: 0,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontFamily: FONTE,
        fontWeight: 800,
        fontSize: tam * 0.6,
        color: "#6b3e00",
        lineHeight: 1,
        paddingTop: tam * 0.08,
      }}
    >
      {letra}
    </div>
  </div>
);
