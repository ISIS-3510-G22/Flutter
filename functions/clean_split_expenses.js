const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const PREFIX = 'Demo split plan';

const creator = (process.env.PARTICIPANT_IDS || '').split(',')[0].trim();
if (!creator) {
  console.error('Set PARTICIPANT_IDS (the same list used for the seed). Nothing was deleted.');
  process.exit(1);
}

initializeApp();
const db = getFirestore();

async function clean() {
  const snapshot = await db.collection('plans').where('creatorId', '==', creator).get();
  const plans = snapshot.docs.filter((doc) => (doc.get('name') || '').startsWith(PREFIX));

  let expenses = 0;
  for (const plan of plans) {
    expenses += (await plan.ref.collection('expenses').get()).size;
    await db.recursiveDelete(plan.ref);
  }
  return { plans: plans.length, expenses };
}

clean().then(({ plans, expenses }) => console.log(`Deleted ${plans} plans and ${expenses} expenses`));
