import type { Game } from '../simulation/types';
import { rng } from '../simulation/engine';

export type EventTemplate = { id: string; category: string; location: string; weight: number; cooldown: number; condition: (game: Game) => boolean; text: (game: Game) => string; choices: { label: string; mood: number; money: number; trust: number }[] };
const categories = [
  { id: 'trabajo', places: ['Trabajo', 'Café'], situations: ['Un compañero pide que lo cubras', 'Surge una tarea inesperada', 'Alguien reconoce tu esfuerzo', 'Un cliente cambia sus planes', 'Tu equipo necesita una idea', 'Aparece un turno extra', 'Se abre una vacante', 'Llega una crítica constructiva', 'Conocés a alguien del sector', 'Un proyecto requiere paciencia'] },
  { id: 'dinero', places: ['Tienda', 'Casa'], situations: ['Encontrás una oferta útil', 'Llega un gasto imprevisto', 'Alguien propone compartir gastos', 'Tu presupuesto pide atención', 'Hay un objeto que deseás', 'Recibís una pequeña devolución', 'Un arreglo puede esperar', 'Descubrís un servicio más barato', 'Una compra parece apresurada', 'Surge una oportunidad de ahorro'] },
  { id: 'amistad', places: ['Plaza', 'Café'], situations: ['Alguien te invita a caminar', 'Un amigo recuerda una charla', 'Hay un cumpleaños cerca', 'Te llega un mensaje sincero', 'Alguien necesita compañía', 'Una amistad propone un plan', 'Se cruzan en el barrio', 'Un malentendido necesita diálogo', 'Compartís una buena noticia', 'Alguien te presenta a otra persona'] },
  { id: 'romance', places: ['Café', 'Plaza'], situations: ['Una conversación se alarga', 'Surge una invitación espontánea', 'Compartís una mirada cómplice', 'Alguien pregunta por tus planes', 'Un gesto te sorprende', 'Hay una cita posible', 'Una diferencia merece charla', 'El momento se siente especial', 'Un recuerdo vuelve en común', 'Aparece una oportunidad de acercarse'] },
  { id: 'familia', places: ['Casa', 'Plaza'], situations: ['Llega una llamada familiar', 'Una persona querida quiere verte', 'Recibís una historia de tu infancia', 'Alguien necesita un favor', 'Se organiza una comida', 'Te piden un consejo', 'Una visita cambia tus planes', 'Compartís una buena noticia', 'Una tradición vuelve', 'Hay algo pendiente por hablar'] },
  { id: 'hogar', places: ['Casa', 'Tienda'], situations: ['Tu habitación pide un cambio', 'Un vecino se presenta', 'Hay una reparación pequeña', 'El espacio necesita orden', 'Encontrás una planta bonita', 'La casa se siente distinta', 'Un mueble podría mejorar la rutina', 'Un ruido interrumpe la tarde', 'Te ofrecen ayuda para mudarte', 'La luz del atardecer entra por la ventana'] },
  { id: 'salud', places: ['Hospital', 'Casa'], situations: ['El cansancio se hace sentir', 'Necesitás bajar el ritmo', 'Una caminata te vendría bien', 'Dormiste poco', 'Un chequeo te deja tranquilo', 'Alguien recomienda descansar', 'Te duele la cabeza', 'Pasaste demasiado tiempo sentado', 'Una comida te devuelve energía', 'Tu cuerpo pide una pausa'] },
  { id: 'ocio', places: ['Bar', 'Plaza'], situations: ['Hay música en la plaza', 'Descubrís un evento de barrio', 'Te invitan a jugar', 'Una película llama tu atención', 'Hay un recital pequeño', 'Una tarde libre aparece', 'El barrio celebra algo', 'Probás un hobby nuevo', 'Alguien comparte su afición', 'Una noche promete ser distinta'] },
  { id: 'estudio', places: ['Instituto', 'Casa'], situations: ['Un tema empieza a encajar', 'Una compañera propone estudiar', 'Hay un taller breve', 'Encontrás apuntes útiles', 'Surge una beca pequeña', 'Una clase te desafía', 'Alguien explica algo con paciencia', 'Se abre una capacitación', 'Tenés una idea mientras estudiás', 'Terminás un ejercicio difícil'] },
  { id: 'ciudad', places: ['Parada', 'Plaza'], situations: ['El colectivo se demora', 'Una calle cambia su recorrido', 'Aparece un comercio nuevo', 'Hay feria en el barrio', 'Conocés un rincón tranquilo', 'La ciudad recibe visitantes', 'Un atardecer detiene la marcha', 'El tráfico cambia tus planes', 'Un vecino comparte una noticia', 'Una plaza reúne a todos'] },
  { id: 'azar', places: ['Café', 'Tienda'], situations: ['Una coincidencia te sorprende', 'Encontrás algo perdido', 'Un desconocido inicia conversación', 'Cambian los planes de último momento', 'La suerte te sonríe', 'Una decisión pequeña importa', 'Recibís una propuesta inesperada', 'Una puerta se abre', 'Un encuentro te hace pensar', 'El día toma otro rumbo'] },
];

export const catalog: EventTemplate[] = categories.flatMap(category => category.situations.map((situation, index) => ({
  id: `${category.id}-${index + 1}`, category: category.id, location: category.places[index % category.places.length], weight: 1, cooldown: 12,
  condition: (game: Game) => game.day > 1 && (category.id !== 'romance' || game.npcs.some(n => n.friendship >= 18)),
  text: (game: Game) => `${situation}. ${game.npcs[(game.day + index) % game.npcs.length].name} está cerca.`,
  choices: [{ label: 'Acercarme', mood: 5, money: 0, trust: 3 }, { label: 'Seguir con mi día', mood: 0, money: 0, trust: 0 }],
})));

export function drawEvent(game: Game): EventTemplate | undefined {
  if (game.day < 2 || game.day % 2 !== 0) return undefined;
  const pool = catalog.filter(event => event.condition(game) && !game.recentEvents.includes(event.id));
  return pool[Math.floor(rng(game.seed + game.day * 93)() * pool.length)];
}
