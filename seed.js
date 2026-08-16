const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

// Authenticate using Google Application Default Credentials
try {
  initializeApp({
    credential: applicationDefault(),
    projectId: 'autoshare-df55f' // using the project id from firebase.json
  });
} catch (e) {
  console.error("Failed to initialize app with ADC:", e);
  process.exit(1);
}

const db = getFirestore();

const targetDrivers = {
  'Vijaybhai': '7874512833',
  'Rajubhai': '7990496596',
  'Kantibhai': '7990697077',
  'Sandipbhai': '9904264835',
  'Ghanshyambhai': '9824866946',
  'Rahul': '9727935297',
  'Dashrathbhai': '9265134763',
};

async function seed() {
  try {
    const usersRef = db.collection('users');
    const snapshot = await usersRef.get();
    
    const foundDrivers = new Set();

    // Update existing drivers
    for (const doc of snapshot.docs) {
      const data = doc.data();
      const name = data.name;
      
      if (name && targetDrivers[name]) {
        foundDrivers.add(name);
        const targetPhone = targetDrivers[name];
        
        if (data.phone !== targetPhone) {
          await doc.ref.update({ phone: targetPhone });
          console.log(`✅ Updated existing driver ${name} with phone ${targetPhone}`);
        } else {
          console.log(`✅ Existing driver ${name} already has correct phone ${targetPhone}`);
        }
      }
    }

    // Create missing drivers
    for (const [name, phone] of Object.entries(targetDrivers)) {
      if (!foundDrivers.has(name)) {
        const newDriverData = {
          name: name,
          phone: phone,
          role: 'driver',
          area: 'Changa',
          city: 'Anand',
          available: true,
          emailVerified: true,
          averageRating: 5.0,
          createdAt: FieldValue.serverTimestamp(),
        };
        
        await usersRef.add(newDriverData);
        console.log(`✅ Created missing driver ${name} with phone ${phone}`);
      }
    }

    console.log('🎉 Seed complete.');
  } catch (e) {
    console.error('Error seeding drivers:', e);
  }
}

seed();
