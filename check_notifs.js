const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs, query, orderBy, limit } = require('firebase/firestore');

const firebaseConfig = {
  apiKey: "AIzaSyCnM88EidG3BSnFWL1wpxgbfNSqkStCoXU",
  authDomain: "autoshare-df55f.firebaseapp.com",
  projectId: "autoshare-df55f",
  storageBucket: "autoshare-df55f.firebasestorage.app",
  messagingSenderId: "669295324518",
  appId: "1:669295324518:web:4472a39d44473170e1aca7"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function check() {
  const q = query(collection(db, 'notifications'), orderBy('createdAt', 'desc'), limit(5));
  const snapshot = await getDocs(q);
  snapshot.forEach((doc) => {
    console.log(doc.id, "=>", doc.data());
  });
  process.exit(0);
}

check();
