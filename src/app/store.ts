import { create } from 'zustand';
import type { Game } from '../game/simulation/types';
import type { Choice } from '../game/simulation/engine';
import { act } from '../game/simulation/engine';
import { loadGame, saveGame } from '../storage/save';
type Store = { game: Game | null; start: (game: Game) => void; decide: (choice: Choice) => void; replace: (game: Game) => void; setGoal: (goal: string) => void; setCareer: (career: string) => void };
export const useGame = create<Store>((set) => ({
  game: loadGame(),
  start: game => { saveGame(game); set({ game }); },
  replace: game => { saveGame(game); set({ game }); },
  decide: choice => set(state => { if (!state.game) return state; const game = act(state.game, choice); saveGame(game); return { game }; }),
  setGoal: goal => set(state => { if (!state.game) return state; const game = { ...state.game, goal }; saveGame(game); return { game }; }),
  setCareer: career => set(state => { if (!state.game) return state; const game = { ...state.game, career, employed: false }; saveGame(game); return { game }; }),
}));
