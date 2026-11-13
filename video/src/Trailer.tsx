import React from "react";
import {
  AbsoluteFill,
  Audio,
  interpolate,
  OffthreadVideo,
  Sequence,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import roteiro from "./roteiro.json";
import { creep, glide, kick } from "./camera";
import { Balao, Fala, FONTE, Mata, Moeda, Pixel, Retrato, TINTA, Vinheta } from "./pecas";

const FALAS = roteiro.falas as Fala[];
const cena = (id: string) => roteiro.cenas.find((c) => c.id === id)!;
const falasEntre = (a: number, b: number) => FALAS.filter((f) => f.ini >= a && f.ini < b);

/** Mostra a cena no intervalo dela, entrando com um fade rápido (crossfade de 8 quadros). */
const Cena: React.FC<{ id: string; fade?: number; children: React.ReactNode }> = ({ id, fade = 8, children }) => {
  const frame = useCurrentFrame();
  const c = cena(id);
  if (frame < c.ini - fade || frame >= c.fim) return null;
  const op = fade ? interpolate(frame, [c.ini - fade, c.ini], [0, 1], { extrapolateRight: "clamp" }) : 1;
  return <AbsoluteFill style={{ opacity: op }}>{children}</AbsoluteFill>;
};

/** Trecho gravado do jogo, com uma aproximação lenta para não parecer parado. */
const Clipe: React.FC<{ id: string; zoom?: number }> = ({ id, zoom = 0.0004 }) => {
  const c = cena(id) as { ini: number; fim: number; clipe: string; de: number };
  const frame = useCurrentFrame();
  const s = creep(frame - c.ini, zoom);
  return (
    <Sequence from={c.ini - 8} durationInFrames={c.fim - c.ini + 8} layout="none">
      <AbsoluteFill style={{ transform: `scale(${s})` }}>
        <OffthreadVideo src={staticFile(`clipes/${c.clipe}.mp4`)} startFrom={Math.max(0, c.de - 8)} muted />
      </AbsoluteFill>
    </Sequence>
  );
};

/** Trecho do jogo em "janela" (para telas com muito texto), com a mata desfocada atrás. */
const ClipeJanela: React.FC<{ id: string }> = ({ id }) => {
  const c = cena(id) as { ini: number; fim: number; clipe: string; de: number };
  const frame = useCurrentFrame();
  const s = creep(frame - c.ini, 0.0003);
  return (
    <>
      <Mata pan={frame * 1.2} desfoque={10} escuro={0.35} />
      <Sequence from={c.ini - 8} durationInFrames={c.fim - c.ini + 8} layout="none">
        <div
          style={{
            position: "absolute",
            left: 560,
            top: 170,
            width: 1300,
            height: 731,
            transform: `scale(${s})`,
            transformOrigin: "50% 50%",
            border: `10px solid ${TINTA}`,
            borderRadius: 18,
            overflow: "hidden",
            boxShadow: "0 22px 0 rgba(0,0,0,0.35)",
          }}
        >
          <OffthreadVideo
            src={staticFile(`clipes/${c.clipe}.mp4`)}
            startFrom={Math.max(0, c.de - 8)}
            muted
            style={{ width: "100%", height: "100%" }}
          />
        </div>
      </Sequence>
    </>
  );
};

const Brilhos: React.FC<{ cx: number; cy: number; raio: number; ini: number; n?: number }> = ({
  cx,
  cy,
  raio,
  ini,
  n = 10,
}) => {
  const frame = useCurrentFrame();
  return (
    <>
      {Array.from({ length: n }).map((_, i) => {
        const periodo = 40 + ((i * 13) % 25);
        const t = ((frame - ini + i * 11) % periodo) / periodo;
        const ang = i * 2.399;
        const r = raio * (0.55 + 0.45 * ((i * 7) % 10) / 10);
        const x = cx + Math.cos(ang) * r;
        const y = cy + Math.sin(ang) * r * 0.7;
        const op = Math.sin(t * Math.PI);
        const tam = 10 + (i % 3) * 6;
        return (
          <div key={i} style={{ position: "absolute", left: x, top: y, opacity: op }}>
            <div style={{ position: "absolute", left: -tam, top: -3, width: tam * 2, height: 6, background: "#fffbe0" }} />
            <div style={{ position: "absolute", left: -3, top: -tam, width: 6, height: tam * 2, background: "#fffbe0" }} />
          </div>
        );
      })}
    </>
  );
};

/** Moedas com letras saindo do livro com a ventania. */
const LetrasVoando: React.FC<{ ini: number }> = ({ ini }) => {
  const frame = useCurrentFrame();
  const letras = "ARONÇABTUCPIVAONÇA".split("");
  return (
    <>
      {letras.map((l, i) => {
        const t0 = ini + i * 4;
        const t = (frame - t0) / 45;
        if (t < 0 || t > 1.2) return null;
        const x = 1310 + t * (500 + (i % 4) * 160) + Math.sin(t * 6 + i) * 30;
        const y = 470 - t * (380 + (i % 5) * 70) + t * t * 160;
        const rot = t * (i % 2 ? 540 : -480);
        return <Moeda key={i} letra={l} tam={84} style={{ left: x - 42, top: y - 42, transform: `rotate(${rot}deg)` }} />;
      })}
      {Array.from({ length: 8 }).map((_, i) => {
        const t = ((frame - ini + i * 9) % 30) / 30;
        return (
          <div
            key={`v${i}`}
            style={{
              position: "absolute",
              left: -400 + t * 2600,
              top: 140 + i * 105,
              width: 360,
              height: 10,
              borderRadius: 5,
              background: "rgba(255,255,255,0.55)",
              opacity: Math.sin(t * Math.PI),
            }}
          />
        );
      })}
    </>
  );
};

const Desfile: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const c = cena("desfile");
  const juntar = interpolate(frame, [2170, 2210], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const livro = interpolate(frame, [2175, 2200], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return (
    <>
      <Mata pan={frame * 1.5} desfoque={8} escuro={0.3} />
      <div
        style={{
          position: "absolute",
          left: 960 - 384,
          top: 140,
          opacity: livro,
          transform: `scale(${0.8 + 0.2 * livro + creep(frame - 2175, 0.0006) - 1})`,
        }}
      >
        <Pixel src="img/livro_completo.png" w={768} h={576} />
      </div>
      {livro > 0 ? <Brilhos cx={960} cy={430} raio={420} ini={2175} n={14} /> : null}
      {roteiro.desfile.map((a, i) => {
        const entrar = spring({ frame: frame - a.f, fps, config: { damping: 12, stiffness: 140 } });
        if (frame < a.f) return null;
        const x0 = 150 + i * 330;
        const y0 = 250 + (1 - entrar) * 500;
        const x = x0 + (960 - 150 - x0) * juntar;
        const y = y0 + (430 - 120 - y0) * juntar;
        const s = 1 - 0.8 * juntar;
        return (
          <div key={a.nome} style={{ position: "absolute", left: x, top: y, transform: `scale(${s})`, opacity: 1 - juntar }}>
            <div style={{ border: `8px solid ${TINTA}`, borderRadius: 14, overflow: "hidden", boxShadow: "0 14px 0 rgba(0,0,0,0.3)" }}>
              <Pixel src={`img/${a.img}.png`} w={288} h={216} />
            </div>
            <div
              style={{
                marginTop: 14,
                textAlign: "center",
                fontFamily: FONTE,
                fontWeight: 800,
                fontSize: 50,
                color: "#ffe14a",
                WebkitTextStroke: `10px ${TINTA}`,
                paintOrder: "stroke fill",
              }}
            >
              {a.nome}
            </div>
          </div>
        );
      })}
      {void c}
    </>
  );
};

const Final: React.FC = () => {
  const frame = useCurrentFrame();
  const c = cena("final");
  const s = creep(frame - c.ini, 0.0005);
  const entrar = interpolate(frame, [c.ini + 10, c.ini + 30], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const preto = interpolate(frame, [c.fim - 22, c.fim - 2], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return (
    <>
      <AbsoluteFill style={{ transform: `scale(${s})` }}>
        <Pixel src="img/capa.png" w={1920} h={1080} />
      </AbsoluteFill>
      <AbsoluteFill style={{ background: "linear-gradient(to top, rgba(4,20,12,0.92) 0%, rgba(4,20,12,0.6) 26%, rgba(4,20,12,0) 45%)" }} />
      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          bottom: 70,
          textAlign: "center",
          fontFamily: FONTE,
          opacity: entrar,
          transform: `translateY(${(1 - entrar) * 40}px)`,
        }}
      >
        <div style={{ fontWeight: 800, fontSize: 76, color: "#fff", WebkitTextStroke: `12px ${TINTA}`, paintOrder: "stroke fill" }}>
          Jogue grátis no computador!
        </div>
        <div style={{ fontWeight: 800, fontSize: 46, color: "#ffe14a", WebkitTextStroke: `9px ${TINTA}`, paintOrder: "stroke fill" }}>
          github.com/RicardoFissmer/leo-na-amazonia
        </div>
        <div style={{ fontWeight: 700, fontSize: 26, color: "#c8f0d8", marginTop: 8 }}>
          Feito com Godot 4 · efeitos de tela VesperaFX · vídeo em Remotion
        </div>
      </div>
      <AbsoluteFill style={{ background: "#000", opacity: preto }} />
    </>
  );
};

export const Trailer: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const shake = kick(frame, roteiro.kicks);
  // durante a sacudida, um leve zoom esconde as bordas pretas que apareceriam
  const sacudindo = roteiro.kicks.some((k) => frame - k.f >= 0 && frame - k.f < 7);

  // gancho: preto, flash branco, Léo aparece
  const preto = interpolate(frame, [0, 16], [1, 0], { extrapolateRight: "clamp" });
  const flash = interpolate(frame, [18, 19, 26], [0, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

  const cenario = cena("cenario");
  // só a parte de baixo da capa (bichos e Léo), sem cortar o título no meio
  const zoomCapa = glide(frame, [
    { f: cenario.ini, v: 1.8 },
    { f: cenario.fim, v: 1.7 },
  ]);
  const panCapa = glide(frame, [
    { f: cenario.ini, v: 520 },
    { f: cenario.ini + 120, v: 240 },
    { f: cenario.fim, v: -360 },
  ]);
  const onca = spring({ frame: frame - 918, fps, config: { damping: 14, stiffness: 120 } });

  return (
    <AbsoluteFill style={{ background: "#000", overflow: "hidden" }}>
      <AbsoluteFill style={{ transform: `translate(${shake.x}px, ${shake.y}px) scale(${sacudindo ? 1.035 : 1})` }}>
        {/* 1. Gancho */}
        <Cena id="gancho" fade={0}>
          <AbsoluteFill style={{ transform: `scale(${creep(frame, 0.0006)})` }}>
            <Mata pan={frame * 0.8} desfoque={9} escuro={0.15} />
          </AbsoluteFill>
          <Retrato falas={falasEntre(0, 180)} escala={9} x={230} y={430} entrada={18} />
          {falasEntre(0, 180).map((f) => (
            <Balao key={f.ini} fala={f} x={900} y={300} largura={820} tamanho={78} />
          ))}
        </Cena>

        {/* 2. Cenário: a capa do jogo com a câmera deslizando */}
        <Cena id="cenario">
          <AbsoluteFill
            style={{ transform: `scale(${zoomCapa}) translate(${panCapa / zoomCapa}px, ${-230}px)` }}
          >
            <Pixel src="img/capa.png" w={1920} h={1080} />
          </AbsoluteFill>
          <Vinheta />
          <Retrato falas={falasEntre(180, 420)} escala={5} x={60} y={730} entrada={180} />
          {falasEntre(180, 420).map((f) => (
            <Balao key={f.ini} fala={f} x={440} y={760} largura={1340} tamanho={58} />
          ))}
        </Cena>

        {/* 3. O Livro da Floresta */}
        <Cena id="livro">
          <Mata pan={frame * 1.0} desfoque={10} escuro={0.25} />
          <div style={{ position: "absolute", left: 880, top: 150, transform: `scale(${creep(frame - 420, 0.0008)})` }}>
            <Pixel src="img/livro.png" w={864} h={648} />
          </div>
          <Brilhos cx={1312} cy={470} raio={420} ini={420} />
          <Retrato falas={falasEntre(420, 630)} escala={6} x={120} y={630} entrada={420} />
          {falasEntre(420, 630).map((f) => (
            <Balao key={f.ini} fala={f} x={110} y={150} largura={760} tamanho={60} cauda="baixo-esquerda" />
          ))}
        </Cena>

        {/* 4. A ventania */}
        <Cena id="vento" fade={0}>
          <Mata pan={frame * 3.0} desfoque={10} escuro={0.3} />
          <div style={{ position: "absolute", left: 880, top: 150, transform: `rotate(${Math.sin(frame / 2) * 1.2}deg)` }}>
            <Pixel src="img/livro_vento.png" w={864} h={648} />
          </div>
          <LetrasVoando ini={640} />
          <Retrato falas={falasEntre(630, 810)} escala={6} x={120} y={630} base="medo" entrada={630} />
          {falasEntre(630, 810).map((f) => (
            <Balao key={f.ini} fala={f} x={110} y={150} largura={760} tamanho={62} cauda="baixo-esquerda" />
          ))}
        </Cena>

        {/* 5. Boa notícia / má notícia */}
        <Cena id="dupla">
          <AbsoluteFill style={{ transform: `scale(${creep(frame - 810, 0.0005)})` }}>
            <Mata pan={frame * 0.8} desfoque={8} escuro={0.2} />
          </AbsoluteFill>
          {/* a onça entra andando pela mata (recortada, sem fundo), pisando no chão */}
          <div style={{ position: "absolute", left: 1960 - 820 * onca, top: 884 - 414 }}>
            <Pixel src="img/onca_recorte.png" w={675} h={414} style={{ transform: "scaleX(-1)" }} />
          </div>
          <Retrato falas={falasEntre(810, 1020)} escala={8} x={160} y={560} base="determinado" entrada={810} />
          {falasEntre(810, 1020).map((f) => (
            <Balao key={f.ini} fala={f} x={700} y={130} largura={1100} tamanho={66} cauda="baixo-esquerda" />
          ))}
        </Cena>

        {/* 6. Gameplay: corre, pula, onça, piranha, cobra */}
        <Cena id="acao" fade={0}>
          <Clipe id="acao" />
        </Cena>
        <Cena id="fase3" fade={6}>
          <Clipe id="fase3" />
        </Cena>
        <Cena id="fase5" fade={6}>
          <Clipe id="fase5" />
        </Cena>
        <Cena id="dano" fade={0}>
          <Clipe id="dano" zoom={0.001} />
        </Cena>
        <Cena id="queda" fade={6}>
          <Clipe id="queda" />
        </Cena>
        {frame >= 1020 && frame < 1700 ? (
          <>
            <Retrato falas={falasEntre(1020, 1700)} escala={4} x={30} y={800} base="determinado" entrada={1020} />
            {falasEntre(1020, 1700).map((f) => (
              <Balao key={f.ini} fala={f} x={330} y={850} largura={1000} tamanho={56} />
            ))}
          </>
        ) : null}

        {/* 8. Montar a palavra e Verdadeiro ou Falso */}
        <Cena id="montar">
          <ClipeJanela id="montar" />
        </Cena>
        <Cena id="quiz" fade={6}>
          <ClipeJanela id="quiz" />
        </Cena>
        <Cena id="resultado" fade={6}>
          <ClipeJanela id="resultado" />
        </Cena>
        {frame >= 1700 && frame < 2030 ? (
          <>
            <Retrato falas={falasEntre(1700, 2030)} escala={6} x={40} y={680} base="feliz" entrada={1700} />
            {falasEntre(1700, 2030).map((f) => (
              <Balao key={f.ini} fala={f} x={60} y={24} largura={1100} tamanho={54} cauda="nenhuma" />
            ))}
          </>
        ) : null}

        {/* 9. Desfile dos animais e o livro completo */}
        <Cena id="desfile">
          <Desfile />
          <Retrato falas={falasEntre(2030, 2250)} escala={4} x={60} y={800} base="feliz" entrada={2030} />
          {falasEntre(2030, 2250).map((f) => (
            <Balao key={f.ini} fala={f} x={360} y={850} largura={1100} tamanho={56} />
          ))}
        </Cena>

        {/* 10. Convite */}
        <Cena id="convite">
          <AbsoluteFill style={{ transform: `scale(${creep(frame - 2250, 0.0007)})` }}>
            <Mata pan={frame * 1.2} desfoque={9} escuro={0.15} />
          </AbsoluteFill>
          {frame >= 2368 ? <Brilhos cx={560} cy={560} raio={520} ini={2368} n={16} /> : null}
          <Retrato falas={falasEntre(2250, 2460)} escala={10} x={240} y={440} entrada={2250} />
          {falasEntre(2250, 2460).map((f) => (
            <Balao key={f.ini} fala={f} x={1000} y={260} largura={820} tamanho={80} />
          ))}
        </Cena>

        {/* 11. Menu do jogo e tela final */}
        <Cena id="menu" fade={6}>
          <Clipe id="menu" zoom={0.0006} />
        </Cena>
        <Cena id="final" fade={10}>
          <Final />
        </Cena>
      </AbsoluteFill>

      <AbsoluteFill style={{ background: "#000", opacity: preto }} />
      <AbsoluteFill style={{ background: "#fff", opacity: flash }} />
      <Audio src={staticFile("audio/mix.wav")} />
    </AbsoluteFill>
  );
};
