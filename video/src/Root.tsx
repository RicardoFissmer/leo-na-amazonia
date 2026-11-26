import React from "react";
import { Composition } from "remotion";
import roteiro from "./roteiro.json";
import apresentacao from "./apresentacao.json";
import { Trailer } from "./Trailer";
import { Apresentacao } from "./Apresentacao";

export const Root: React.FC = () => (
  <>
    <Composition
      id="LeoTrailer"
      component={Trailer}
      durationInFrames={roteiro.total}
      fps={roteiro.fps}
      width={1920}
      height={1080}
    />
    <Composition
      id="Apresentacao"
      component={Apresentacao}
      durationInFrames={apresentacao.total}
      fps={apresentacao.fps}
      width={1920}
      height={1080}
      defaultProps={{ narracao: true }}
    />
    <Composition
      id="ApresentacaoSemNarracao"
      component={Apresentacao}
      durationInFrames={apresentacao.total}
      fps={apresentacao.fps}
      width={1920}
      height={1080}
      defaultProps={{ narracao: false }}
    />
  </>
);
