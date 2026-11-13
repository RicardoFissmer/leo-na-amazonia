import React from "react";
import { Composition } from "remotion";
import roteiro from "./roteiro.json";
import { Trailer } from "./Trailer";

export const Root: React.FC = () => (
  <Composition
    id="LeoTrailer"
    component={Trailer}
    durationInFrames={roteiro.total}
    fps={roteiro.fps}
    width={1920}
    height={1080}
  />
);
