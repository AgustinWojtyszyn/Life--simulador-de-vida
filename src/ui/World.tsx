import { useEffect, useRef } from 'react';
import Phaser from 'phaser';
import { CityScene } from '../game/world/CityScene';
import type { Game } from '../game/simulation/types';
export function World({ game, onPlace }: { game: Game; onPlace: (place: string) => void }) {
  const host = useRef<HTMLDivElement>(null); const callback = useRef(onPlace); callback.current = onPlace;
  useEffect(() => {
    if (!host.current) return;
    const instance = new Phaser.Game({ type: Phaser.CANVAS, parent: host.current, width: 360, height: 370, transparent: false, scale: { mode: Phaser.Scale.RESIZE, autoCenter: Phaser.Scale.CENTER_BOTH }, render: { pixelArt: true, antialias: false }, scene: [new CityScene(game, place => callback.current(place))] });
    return () => instance.destroy(true);
  }, [game.cityId, game.district, game.hour >= 7 && game.hour < 19]);
  return <div ref={host} className="world" aria-label="Mapa isométrico interactivo de la ciudad" />;
}
