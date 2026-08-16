const { initializeApp } = require('firebase/app');
const { getAuth, createUserWithEmailAndPassword, signInWithEmailAndPassword, signOut } = require('firebase/auth');
const { getFirestore, collection, doc, setDoc, getDoc, updateDoc, serverTimestamp } = require('firebase/firestore');

const firebaseConfig = {
  apiKey: "AIzaSyCnM88EidG3BSnFWL1wpxgbfNSqkStCoXU",
  authDomain: "autoshare-df55f.firebaseapp.com",
  projectId: "autoshare-df55f",
  storageBucket: "autoshare-df55f.firebasestorage.app",
  messagingSenderId: "669295324518",
  appId: "1:669295324518:web:4472a39d44473170e1aca7"
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

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
  for (const [name, phone] of Object.entries(targetDrivers)) {
    const email = `${name.toLowerCase()}@autoshare.driver`;
    const password = 'Password123!';
    
    try {
      // Create user
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);
      const uid = userCredential.user.uid;
      
      console.log(`Created Auth for ${name}`);
      
      // Since we are now logged in as this user, we have permission to write their profile
      await setDoc(doc(db, 'users', uid), {
        name: name,
        phone: phone,
        role: 'driver',
        area: 'Changa',
        city: 'Anand',
        available: true,
        emailVerified: true,
        averageRating: 5.0,
        createdAt: serverTimestamp(),
      });
      
      console.log(`Created Profile for ${name}`);
      await signOut(auth);
      
    } catch (e) {
      if (e.code === 'auth/email-already-in-use') {
        console.log(`${name} already exists. Signing in to update...`);
        try {
          const userCredential = await signInWithEmailAndPassword(auth, email, password);
          const uid = userCredential.user.uid;
          
          await updateDoc(doc(db, 'users', uid), {
            phone: phone
          });
          console.log(`Updated Profile for ${name}`);
          await signOut(auth);
        } catch (signInErr) {
          console.log(`Could not update ${name} due to sign-in error: ${signInErr.code}`);
        }
      } else {
        console.error(`Error processing ${name}:`, e);
      }
    }
  }
  
  console.log('Seed Complete');
  process.exit(0);
}

seed();
