export type City = { id: string; name: string; tint: number; districts: string[]; landmarks: string[] };
export type Country = { id: string; name: string; locale: string; currency: string; names: string[]; salaries: number; rent: number; food: number; transport: number; cities: City[] };
// Fictional, balanced economies. These values are gameplay parameters, not current prices.
export const countries: Country[] = [
  { id: 'ar', name: 'Argentina', locale: 'es-AR', currency: 'ARS', names: ['Luz', 'Mateo', 'Sofía', 'Tomás', 'Valentina'], salaries: 4500, rent: 3000, food: 420, transport: 120, cities: [
    { id: 'san-juan', name: 'San Juan', tint: 0xe7aa75, districts: ['Centro', 'Barrio del Sol', 'Parque Oeste'], landmarks: ['Casa', 'Trabajo', 'Plaza', 'Café', 'Supermercado', 'Gimnasio', 'Instituto', 'Bar', 'Hospital', 'Tienda', 'Parada'] },
    { id: 'buenos-aires', name: 'Buenos Aires', tint: 0x94b6be, districts: ['Centro', 'Ribera', 'Barrio Norte'], landmarks: ['Casa', 'Trabajo', 'Plaza', 'Café', 'Supermercado', 'Instituto'] }] },
  { id: 'mx', name: 'México', locale: 'es-MX', currency: 'MXN', names: ['Ana', 'Diego', 'Mariana', 'Emilio'], salaries: 520, rent: 350, food: 48, transport: 15, cities: [{ id: 'cdmx', name: 'Ciudad de México', tint: 0xa5b98c, districts: ['Centro', 'Colonia Norte', 'Parque Sur'], landmarks: ['Casa', 'Trabajo', 'Plaza', 'Café', 'Supermercado', 'Instituto'] }] },
  { id: 'es', name: 'España', locale: 'es-ES', currency: 'EUR', names: ['Lucía', 'Pablo', 'Nora', 'Hugo'], salaries: 110, rent: 72, food: 10, transport: 3, cities: [{ id: 'madrid', name: 'Madrid', tint: 0xd6aa8c, districts: ['Centro', 'Barrio Este', 'Parque Norte'], landmarks: ['Casa', 'Trabajo', 'Plaza', 'Café', 'Supermercado', 'Instituto'] }] },
  { id: 'us', name: 'Estados Unidos', locale: 'en-US', currency: 'USD', names: ['Alex', 'Jordan', 'Taylor', 'Sam'], salaries: 125, rent: 86, food: 12, transport: 4, cities: [{ id: 'miami', name: 'Miami', tint: 0x85c4bb, districts: ['Downtown', 'Bay Side', 'West Park'], landmarks: ['Home', 'Work', 'Park', 'Café', 'Market', 'College'] }] },
];
export const countryById = (id: string) => countries.find(c => c.id === id) ?? countries[0];
export const cityById = (country: Country, id: string) => country.cities.find(c => c.id === id) ?? country.cities[0];
