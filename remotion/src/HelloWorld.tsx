import React from "react";
import {
  AbsoluteFill,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";

export type HelloWorldProps = {
  title: string;
  subtitle: string;
};

export const HelloWorld: React.FC<HelloWorldProps> = ({ title, subtitle }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const titleOpacity = interpolate(frame, [0, 30], [0, 1], {
    extrapolateRight: "clamp",
  });

  const subtitleScale = spring({
    frame: frame - 20,
    fps,
    config: { damping: 12 },
  });

  return (
    <AbsoluteFill
      style={{
        background:
          "radial-gradient(circle at 30% 30%, #1f2a44 0%, #0b0f1f 100%)",
        color: "white",
        fontFamily: "system-ui, -apple-system, Helvetica, Arial, sans-serif",
        justifyContent: "center",
        alignItems: "center",
      }}
    >
      <div
        style={{
          opacity: titleOpacity,
          fontSize: 140,
          fontWeight: 700,
          letterSpacing: -2,
        }}
      >
        {title}
      </div>
      <div
        style={{
          transform: `scale(${subtitleScale})`,
          marginTop: 24,
          fontSize: 48,
          opacity: 0.8,
        }}
      >
        {subtitle}
      </div>
    </AbsoluteFill>
  );
};
