// Movimento de câmera no estilo da skill claude-animated-shorts:
// - deslizes com smootherstep (18-40 quadros), nada de câmera "na mão";
// - toda pausa tem uma aproximação lenta (push-in), para a imagem nunca parecer congelada;
// - sacudidas de impacto que trocam de lado a cada quadro e somem em 7 quadros.

export const smootherstep = (t: number) => {
  const x = Math.min(1, Math.max(0, t));
  return x * x * x * (x * (x * 6 - 15) + 10);
};

/** Interpola entre chaves {f, v} com smootherstep entre cada par. */
export const glide = (frame: number, keys: { f: number; v: number }[]) => {
  if (frame <= keys[0].f) return keys[0].v;
  for (let i = 0; i < keys.length - 1; i++) {
    const a = keys[i];
    const b = keys[i + 1];
    if (frame <= b.f) {
      return a.v + (b.v - a.v) * smootherstep((frame - a.f) / (b.f - a.f));
    }
  }
  return keys[keys.length - 1].v;
};

/** Aproximação lenta durante uma pausa: `porQuadro` em fração (0.0012 = 0,12 % por quadro). */
export const creep = (frame: number, porQuadro = 0.0012) => 1 + frame * porQuadro;

/** Sacudida de impacto: troca de sinal a cada quadro e decai em 7 quadros. */
export const kick = (frame: number, kicks: { f: number; a: number }[]) => {
  let x = 0;
  let y = 0;
  for (const k of kicks) {
    const d = frame - k.f;
    if (d >= 0 && d < 7) {
      const s = (d % 2 === 0 ? 1 : -1) * k.a * (1 - d / 7);
      x += s;
      y += s * 0.6;
    }
  }
  return { x, y };
};
