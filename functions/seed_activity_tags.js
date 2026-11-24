const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp();
const db = getFirestore();
const SEED = 'bjR9SfUNYZYVYzuGPKiePHyPOk13';

const tagsByName = {
  'Bolera Unicentro': ['sports'],
  'Parque de la 93': ['outdoors', 'chill'],
  'Zona T': ['party', 'food'],
  'Usaquén': ['food', 'shopping'],
  'Parque Simón Bolívar': ['outdoors', 'sports'],
  'Monserrate': ['outdoors'],
  'Chorro de Quevedo': ['party', 'chill'],
  'Movistar Arena': ['concert'],
  'Museo del Oro': ['culture'],
  'Parque El Virrey': ['outdoors'],
};

async function seed() {
  const snapshot = await db.collection('activities').where('ownerId', '==', SEED).get();
  const batch = db.batch();
  for (const doc of snapshot.docs) {
    const tags = tagsByName[doc.get('name')];
    if (tags) batch.update(doc.ref, { tags });
  }
  await batch.commit();
  return snapshot.size;
}

seed().then((n) => console.log(`Found ${n} seeded activities`));