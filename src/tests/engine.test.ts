import { describe, expect, it } from 'vitest';
import { act, advance, createGame } from '../game/simulation/engine';
import { catalog, drawEvent } from '../game/events/catalog';
import { countries } from '../content/countries';
import { validGame } from '../storage/save';

describe('simulación local', () => {
  it('crea una partida reproducible para cada ciudad disponible', () => {
    for (const country of countries) for (const city of country.cities) {
      const a = createGame('Alex', country.id, city.id, 'vida', 42);
      const b = createGame('Alex', country.id, city.id, 'vida', 42);
      expect(a).toEqual(b);
      expect(a.cityId).toBe(city.id);
      expect(validGame(JSON.parse(JSON.stringify(a)))).toBe(true);
    }
  });
  it('guarda la ayuda a un NPC y la resuelve una sola vez días después', () => {
    let game = createGame('A', 'ar', 'san-juan', 'vida', 7);
    game = { ...game, day: 2, money: 9000, hour: 8 };
    const npc = game.npcs[0];
    game = act(game, { id: 'meet', label: 'Ver', action: 'social', npcId: npc.id, hours: 2 });
    expect(game.npcs[0].memories).toContain('Recibió ayuda económica');
    expect(game.threads[0].resolved).toBe(false);
    const due = game.threads[0].dueDay;
    game = advance({ ...game, day: due - 1, hour: 23 }, 2);
    expect(game.threads[0].resolved).toBe(true);
    expect(game.journal[0].text).toContain('recordó');
    const money = game.money;
    game = advance(game, 24);
    expect(game.money).toBeLessThanOrEqual(money);
  });
  it('cobra alquiler semanal, limita necesidades y termina el desafío', () => {
    const game = createGame('A', 'mx', 'cdmx', '30-dias', 9);
    const next = advance({ ...game, day: 6, hour: 23, food: 5 }, 2);
    expect(next.day).toBe(7);
    expect(next.food).toBe(0);
    expect(next.money - next.debt).toBe(game.money - game.debt - countries[1].rent);
    expect(advance({ ...next, day: 30, hour: 23 }, 2).finished).toBe(true);
  });
  it('impide compras sin fondos y rechaza partidas dañadas', () => {
    const game = createGame('A', 'es', 'madrid', 'vida', 1);
    const next = act({ ...game, money: 0 }, { id: 'buy', label: 'Computadora', action: 'shop', item: 'Computadora', cost: 100, hours: 1 });
    expect(next.furniture).not.toContain('Computadora');
    expect(next.money).toBe(0);
    expect(validGame({ version: 1, day: -1, name: 'x' })).toBe(false);
  });
  it('ofrece 100 o más eventos y evita repetir los recientes', () => {
    expect(catalog.length).toBeGreaterThanOrEqual(100);
    const game = { ...createGame('A', 'ar', 'san-juan', 'vida', 5), day: 8 };
    const first = drawEvent(game);
    expect(first).toBeDefined();
    expect(drawEvent({ ...game, recentEvents: [first!.id] })?.id).not.toBe(first!.id);
  });
});
