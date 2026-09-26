export type Trait = 'creativo' | 'tranquilo' | 'ambicioso' | 'familiar' | 'aventurero' | 'ahorrador';
export type NPC = { id: string; name: string; profession: string; location: string; traits: Trait[]; money: number; friendship: number; trust: number; attraction: number; conflict: number; memories: string[]; goal: string; connections: string[] };
export type Thread = { id: string; npcId?: string; createdDay: number; dueDay: number; resolved: boolean };
export type Entry = { day: number; text: string; kind: 'story' | 'money' | 'social' };
export type Mode = 'vida' | '30-dias' | 'diario' | 'generaciones';
export type Game = { version: 1; seed: number; name: string; countryId: string; cityId: string; mode: Mode; day: number; hour: number; money: number; debt: number; energy: number; mood: number; food: number; skill: number; career: string; experience: number; employed: boolean; district: number; home: number; furniture: string[]; npcs: NPC[]; threads: Thread[]; journal: Entry[]; recentEvents: string[]; goal: string; finished: boolean };
