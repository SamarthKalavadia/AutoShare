// Seed script using Firebase REST API — no extra npm dependencies needed.
// Firestore rules are temporarily open (allow read, write: if true) for users collection.

const projectId = 'autoshare-df55f';
const baseUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;

const targetDrivers = [
  { name: 'Vijaybhai',     phone: '7874512833' },
  { name: 'Rajubhai',      phone: '7990496596' },
  { name: 'Kantibhai',     phone: '7990697077' },
  { name: 'Sandipbhai',    phone: '9904264835' },
  { name: 'Ghanshyambhai', phone: '9824866946' },
  { name: 'Rahul',         phone: '9727935297' },
  { name: 'Dashrathbhai',  phone: '9265134763' },
];

function toFirestoreValue(val) {
  if (typeof val === 'string') return { stringValue: val };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    if (Number.isInteger(val)) return { integerValue: String(val) };
    return { doubleValue: val };
  }
  return { nullValue: null };
}

function buildDriverDoc(name, phone) {
  return {
    fields: {
      name: toFirestoreValue(name),
      phone: toFirestoreValue(phone),
      role: toFirestoreValue('driver'),
      area: toFirestoreValue('Changa'),
      city: toFirestoreValue('Anand'),
      available: toFirestoreValue(true),
      emailVerified: toFirestoreValue(true),
      averageRating: toFirestoreValue(5.0),
    }
  };
}

async function listAllUsers() {
  const res = await fetch(`${baseUrl}/users?pageSize=100`);
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Failed to list users: ${res.status} ${text}`);
  }
  const data = await res.json();
  return data.documents || [];
}

async function updateDocument(docPath, fields) {
  // PATCH with updateMask for specific fields
  const updateMask = Object.keys(fields.fields).map(f => `updateMask.fieldPaths=${f}`).join('&');
  const url = `https://firestore.googleapis.com/v1/${docPath}?${updateMask}`;
  const res = await fetch(url, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(fields),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Failed to update ${docPath}: ${res.status} ${text}`);
  }
  return await res.json();
}

async function createDocument(docData) {
  const url = `${baseUrl}/users`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(docData),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Failed to create document: ${res.status} ${text}`);
  }
  return await res.json();
}

async function seed() {
  console.log('Fetching existing users...');
  const existingDocs = await listAllUsers();
  console.log(`Found ${existingDocs.length} existing user documents.`);
  
  // Build a map of name -> document path for existing docs
  const existingByName = {};
  for (const doc of existingDocs) {
    const nameField = doc.fields?.name?.stringValue;
    if (nameField) {
      existingByName[nameField] = doc.name; // full document path
    }
  }

  for (const driver of targetDrivers) {
    const docData = buildDriverDoc(driver.name, driver.phone);
    
    if (existingByName[driver.name]) {
      // Update existing document
      const docPath = existingByName[driver.name];
      console.log(`Updating existing driver: ${driver.name} (phone: ${driver.phone})`);
      await updateDocument(docPath, docData);
      console.log(`  ✅ Updated ${driver.name}`);
    } else {
      // Create new document
      console.log(`Creating new driver: ${driver.name} (phone: ${driver.phone})`);
      await createDocument(docData);
      console.log(`  ✅ Created ${driver.name}`);
    }
  }

  // Verify
  console.log('\nVerifying...');
  const finalDocs = await listAllUsers();
  const driverDocs = finalDocs.filter(d => 
    d.fields?.role?.stringValue === 'driver' || d.fields?.role?.stringValue === 'auto_driver'
  );
  console.log(`Total driver documents: ${driverDocs.length}`);
  for (const d of driverDocs) {
    const name = d.fields?.name?.stringValue || '(no name)';
    const phone = d.fields?.phone?.stringValue || '(no phone)';
    console.log(`  - ${name}: ${phone}`);
  }
  
  console.log('\n🎉 Seed complete.');
}

seed().catch(err => {
  console.error('Seed failed:', err);
  process.exit(1);
});
