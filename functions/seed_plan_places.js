const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

initializeApp();
const db = getFirestore();
const SEED = 'bjR9SfUNYZYVYzuGPKiePHyPOk13';

const places = [
  { name: 'Bolera Unicentro', address: 'Av. 15 #124-30, Bogotá', lat: 4.7020, lng: -74.0415, price: 40000, weight: 20 },
  { name: 'Parque de la 93', address: 'Cl. 93A #11A, Bogotá', lat: 4.6767, lng: -74.0483, price: 0, weight: 12 },
  { name: 'Zona T', address: 'Cra. 13 #82, Bogotá', lat: 4.6670, lng: -74.0535, price: 80000, weight: 10 },
  { name: 'Usaquén', address: 'Cra. 6A #119B, Bogotá', lat: 4.6950, lng: -74.0305, price: 50000, weight: 8 },
  { name: 'Parque Simón Bolívar', address: 'Cl. 63 #59A-06, Bogotá', lat: 4.6580, lng: -74.0940, price: 0, weight: 6 },
  { name: 'Monserrate', address: 'Cra. 2 Este #21-48, Bogotá', lat: 4.6058, lng: -74.0556, price: 30000, weight: 5 },
  { name: 'Chorro de Quevedo', address: 'Cl. 12B #1A, Bogotá', lat: 4.5976, lng: -74.0688, price: 20000, weight: 4 },
  { name: 'Movistar Arena', address: 'Dg. 61C #26-36, Bogotá', lat: 4.6494, lng: -74.0770, price: 150000, weight: 3 },
  { name: 'Museo del Oro', address: 'Cra. 6 #15-88, Bogotá', lat: 4.6019, lng: -74.0720, price: 5000, weight: 2 },
  { name: 'Parque El Virrey', address: 'Cl. 88 #15, Bogotá', lat: 4.6735, lng: -74.0565, price: 0, weight: 1 },
];

async function seed() {
  const batch = db.batch();
  const pool = [];

  for (const place of places) {
    const ref = db.collection('activities').doc();
    batch.set(ref, {
      name: place.name,
      address: place.address,
      expectedPrice: place.price,
      notes: '',
      tags: [],
      visibility: 'public',
      ownerId: SEED,
      likedBy: [],
      photoUrl: null,
      lat: place.lat,
      lng: place.lng,
    });
    for (let i = 0; i < place.weight; i++) pool.push(ref.id);
  }

   for (let n = 1; n <= 60; n++) {
    const stops = new Set();
    const count = 1 + Math.floor(Math.random() * 3);
    while (stops.size < count) stops.add(pool[Math.floor(Math.random() * pool.length)]);

    const days = Math.floor(Math.random() * 120) - 90;
    batch.set(db.collection('plans').doc(), {
      name: `Demo plan ${n}`,
      date: Timestamp.fromDate(new Date(Date.now() + days * 86400000)),
      creatorId: SEED,
      tags: [],
      activityIds: [...stops],
      participantsIds: [SEED],
       invitations: [{ userId: SEED, rsvp: 'going' }],
      isPublic: false,
    });
  }

  await batch.commit();
}

seed().then(() => console.log(`Seeded ${places.length} activities and 60 plans`));