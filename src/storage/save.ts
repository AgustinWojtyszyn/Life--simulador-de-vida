import type { Game } from '../game/simulation/types';
const KEY = 'vida.save.v1';
export function validGame(input: unknown): input is Game {
  if (!input || typeof input !== 'object') return false;
  const g = input as Partial<Game>;
  return g.version === 1 && typeof g.name === 'string' && typeof g.day === 'number' && Number.isFinite(g.day) && g.day > 0 && typeof g.money === 'number' && Array.isArray(g.npcs) && Array.isArray(g.threads) && Array.isArray(g.journal) && Array.isArray(g.furniture) && Array.isArray(g.recentEvents);
}
export function loadGame(): Game | null { try { const raw = localStorage.getItem(KEY); const parsed: unknown = raw ? JSON.parse(raw) : null; return validGame(parsed) ? parsed : null; } catch { return null; } }
export function saveGame(game: Game): void { localStorage.setItem(KEY, JSON.stringify(game)); }
export function exportGame(game: Game): void { const blob = new Blob([JSON.stringify(game, null, 2)], { type: 'application/json' }); const url = URL.createObjectURL(blob); const link = document.createElement('a'); link.href = url; link.download = `vida-${game.name.toLowerCase().replace(/[^a-z0-9]/g, '-')}-dia-${game.day}.json`; link.click(); setTimeout(() => URL.revokeObjectURL(url), 2000); }
export async function importGame(file: File): Promise<Game> { if (file.size > 2_000_000) throw new Error('La partida es demasiado grande.'); const parsed: unknown = JSON.parse(await file.text()); if (!validGame(parsed)) throw new Error('El archivo no es una partida compatible.'); return parsed; }
