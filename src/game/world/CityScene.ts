import Phaser from 'phaser';
import type { Game } from '../simulation/types';
import { cityById, countryById } from '../../content/countries';

export class CityScene extends Phaser.Scene {
  private gameState!: Game;
  private onPlace!: (place: string) => void;
  constructor(game: Game, onPlace: (place: string) => void) { super('city'); this.gameState = game; this.onPlace = onPlace; }
  create() {
    const { width, height } = this.scale;
    const g = this.add.graphics(); const day = this.gameState.hour >= 7 && this.gameState.hour < 19;
    this.cameras.main.setBackgroundColor(day ? '#d8e6dd' : '#263b55');
    const hill = day ? 0x849d91 : 0x415363;
    g.fillStyle(hill); g.fillTriangle(0, height * .37, width * .2, height * .16, width * .54, height * .39); g.fillTriangle(width * .22, height * .39, width * .67, height * .1, width, height * .4);
    g.fillStyle(day ? 0xe6c7a1 : 0x8f8490); g.fillRect(0, height * .36, width, height * .64);
    const centerX = width / 2, baseY = height * .45;
    for (let x = -4; x <= 4; x++) for (let y = -3; y <= 4; y++) {
      const px = centerX + (x - y) * 32, py = baseY + (x + y) * 16;
      g.fillStyle((x + y) % 2 ? 0xe6d4b4 : 0xf0dfbf); g.fillPoints([{ x: px, y: py }, { x: px + 32, y: py + 16 }, { x: px, y: py + 32 }, { x: px - 32, y: py + 16 }], true);
      g.lineStyle(1, 0xc3ac91, .55); g.strokePoints([{ x: px, y: py }, { x: px + 32, y: py + 16 }, { x: px, y: py + 32 }, { x: px - 32, y: py + 16 }], true);
    }
    const city = cityById(countryById(this.gameState.countryId), this.gameState.cityId);
    const places = city.landmarks.slice(0, 9);
    places.forEach((place, i) => {
      const col = i % 3, row = Math.floor(i / 3), px = centerX + (col - row) * 80, py = baseY + (col + row) * 40 - 32;
      const colors = [0xc4745b, 0x8a9d92, 0x6d9879, 0xa97763, 0x718fa0, 0x879477, 0x947986, 0xad806d, 0x84a0a2];
      const b = this.add.graphics(); const color = colors[i];
      b.fillStyle(0x000000, .13); b.fillEllipse(px, py + 44, 72, 18);
      b.fillStyle(color); b.fillRect(px - 24, py + 3, 48, 37);
      b.fillStyle(Phaser.Display.Color.ValueToColor(color).brighten(19).color); b.fillPoints([{ x: px - 29, y: py + 4 }, { x: px, y: py - 15 }, { x: px + 29, y: py + 4 }], true);
      b.fillStyle(0x3d5360); b.fillRect(px - 5, py + 25, 10, 15); b.fillStyle(0xf7e5b7); b.fillRect(px - 17, py + 13, 8, 8); b.fillRect(px + 9, py + 13, 8, 8);
      const zone = this.add.zone(px, py + 12, 65, 72).setInteractive({ useHandCursor: true }); zone.on('pointerdown', () => this.onPlace(place));
      this.add.text(px, py + 51, place, { fontFamily: 'system-ui', fontSize: '11px', color: '#20323b', backgroundColor: '#fff8e9', padding: { x: 6, y: 4 } }).setOrigin(.5).setDepth(5);
    });
    this.add.text(14, 12, `${city.name.toUpperCase()}  ·  ${city.districts[this.gameState.district]}`, { fontFamily: 'system-ui', fontSize: '12px', color: day ? '#263f48' : '#ffffff', fontStyle: 'bold', backgroundColor: day ? '#ffffffbb' : '#172833cc', padding: { x: 10, y: 7 } });
    const npcCount = Math.max(1, Math.min(4, this.gameState.hour >= 22 ? 1 : this.gameState.npcs.length));
    for (let i = 0; i < npcCount; i++) { const x = centerX - 100 + i * 65, y = baseY + 130 + i % 2 * 19; g.fillStyle([0x3f6671, 0xa36f80, 0x806e9c, 0x64916c][i]); g.fillRect(x - 6, y - 16, 12, 19); g.fillStyle([0xbf896b, 0xe5bb8a, 0xa16e56, 0xd3a578][i]); g.fillCircle(x, y - 20, 6); g.fillStyle(0x38343b); g.fillRect(x - 6, y + 2, 5, 6); g.fillRect(x + 1, y + 2, 5, 6); }
  }
}
