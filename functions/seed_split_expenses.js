const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

// How often each split case is picked: 6 of every 11 expenses are split
// between everyone, 3 between some people and 2 with custom amounts.
const CASE_WEIGHTS = { everyone: 6, some: 3, custom: 2 };

const PLANS = 20;
const DAY = 86400000;
const names = ['Dinner', 'Taxi', 'Tickets', 'Drinks', 'Groceries', 'Coffee', 'Snacks', 'Parking', 'Gas', 'Bowling'];

const participants = [...new Set(
  (process.env.PARTICIPANT_IDS || '').split(',').map((id) => id.trim()).filter(Boolean),
)];
if (participants.length < 3) {
  console.error('Set PARTICIPANT_IDS to at least 3 real user IDs, separated by commas. Nothing was written.');
  process.exit(1);
}

initializeApp();
const db = getFirestore();
const creator = participants[0];

const randomInt = (min, max) => min + Math.floor(Math.random() * (max - min + 1));
const pick = (list) => list[Math.floor(Math.random() * list.length)];

function pickCase() {
  const pool = [];
  for (const [kind, weight] of Object.entries(CASE_WEIGHTS)) {
    for (let i = 0; i < weight; i++) pool.push(kind);
  }
  return pick(pool);
}

function pickSome(min, max) {
  const shuffled = [...participants].sort(() => Math.random() - 0.5);
  return shuffled.slice(0, randomInt(min, max));
}

// Whole pesos, in thousands, with the last person taking what's left so the
// amounts add up to exactly `value`.
function customAmounts(value, ids) {
  const amounts = {};
  let left = value;
  ids.forEach((id, i) => {
    const last = i === ids.length - 1;
    const share = last ? left : randomInt(1, (left / 1000) - (ids.length - i - 1)) * 1000;
    amounts[id] = share;
    left -= share;
  });
  return amounts;
}

function expenseData(kind, planDate) {
  let splitAmongIds = participants;
  if (kind === 'some') splitAmongIds = pickSome(2, participants.length - 1);
  if (kind === 'custom') splitAmongIds = pickSome(2, participants.length);
  // At least 1000 per person, so every custom share is 1000 or more.
  const value = randomInt(Math.max(10, splitAmongIds.length), 200) * 1000;

  const createdAt = new Date(Math.min(planDate.getTime() + randomInt(0, 6) * 3600000, Date.now()));
  return {
    name: pick(names),
    value,
    paidById: pick(participants),
    createdAt: Timestamp.fromDate(createdAt),
    splitAmongIds,
    splitMethod: kind === 'custom' ? 'custom' : 'equal',
    customAmounts: kind === 'custom' ? customAmounts(value, splitAmongIds) : {},
  };
}

async function seed() {
  const batch = db.batch();
  const counts = { everyone: 0, some: 0, custom: 0 };

  for (let n = 1; n <= PLANS; n++) {
    const date = new Date(Date.now() - randomInt(1, 60) * DAY);
    const plan = db.collection('plans').doc();
    batch.set(plan, {
      name: `Demo split plan ${n}`,
      date: Timestamp.fromDate(date),
      creatorId: creator,
      tags: [],
      activityIds: [],
      participantsIds: participants,
      invitations: participants.map((userId) => ({ userId, rsvp: 'going' })),
      isPublic: false,
    });

    const expenses = randomInt(2, 5);
    for (let i = 0; i < expenses; i++) {
      const kind = pickCase();
      batch.set(plan.collection('expenses').doc(), expenseData(kind, date));
      counts[kind]++;
    }
  }

  await batch.commit();
  return counts;
}

seed().then((counts) => {
  const total = counts.everyone + counts.some + counts.custom;
  console.log(`Seeded ${PLANS} plans and ${total} expenses`);
  console.log(`  equal, everyone: ${counts.everyone}`);
  console.log(`  equal, some:     ${counts.some}`);
  console.log(`  custom:          ${counts.custom}`);
});
