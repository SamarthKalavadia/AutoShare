/**
 * AutoShare FCM Notification Worker
 * Listens for new notifications in Firestore (`notifications` and `push_notifications` collections)
 * and dispatches them via Firebase Admin SDK (FCM HTTP v1).
 *
 * Ensures:
 * 1. Single active token per user (NEVER sends duplicate notifications to the same device).
 * 2. 15-second in-memory deduplication window to suppress duplicate events.
 * 3. Android notification `tag` and `collapseKey` so OS notification tray collapses duplicates.
 * 4. Listens directly to `notifications` collection so ride requests, accepts, updates,
 *    and chats trigger instant FCM push notifications to closed apps.
 */

const admin = require('firebase-admin');
const { cert, applicationDefault } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const path = require('path');
const fs = require('fs');

// Locate service account credentials
let serviceAccountPath = path.join(__dirname, 'service-account.json');
if (!fs.existsSync(serviceAccountPath)) {
  const fallbackPath = path.join(__dirname, '../assets/firebase/service-account.json');
  if (fs.existsSync(fallbackPath)) {
    serviceAccountPath = fallbackPath;
  }
}

let credential;
if (fs.existsSync(serviceAccountPath)) {
  try {
    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    credential = cert(serviceAccount);
  } catch (err) {
    console.error('[Worker] Failed to read service account JSON:', err.message);
    credential = applicationDefault();
  }
} else {
  credential = applicationDefault();
}

let app;
try {
  app = admin.initializeApp({
    credential,
    projectId: 'autoshare-df55f',
  });
} catch (e) {
  app = admin.app();
}

console.log('====================================================');
console.log('[AutoShare FCM Worker] INITIALIZED for autoshare-df55f');
console.log('Listening for in-app and push notification events...');
console.log('====================================================');

const db = getFirestore(app);
const messaging = getMessaging(app);

// ─── Deduplication State ──────────────────────────────────────────────────────
const recentDispatches = new Map(); // key: `${uid}:${title}:${body}` -> timestamp

function isDuplicate(uid, title, body) {
  const key = `${uid}:${(title || '').trim()}:${(body || '').trim()}`;
  const now = Date.now();
  const lastSent = recentDispatches.get(key);
  if (lastSent && (now - lastSent) < 15000) {
    return true;
  }
  recentDispatches.set(key, now);
  return false;
}

// Clean up stale deduplication keys older than 60 seconds
setInterval(() => {
  const now = Date.now();
  for (const [key, timestamp] of recentDispatches.entries()) {
    if (now - timestamp > 60000) {
      recentDispatches.delete(key);
    }
  }
}, 60000);

// ─── Token Resolution ─────────────────────────────────────────────────────────
/**
 * Resolves exactly ONE active FCM token for a given user UID.
 * Prefers `uData.fcmToken`, falls back to latest token in `uData.fcmTokens`.
 * NEVER returns multiple tokens to avoid duplicate notification triggers.
 */
async function getActiveTokenForUser(uid) {
  try {
    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;
    const uData = userDoc.data();
    if (!uData) return null;

    if (uData.fcmToken && typeof uData.fcmToken === 'string' && uData.fcmToken.trim().length > 0) {
      return uData.fcmToken.trim();
    }
    if (Array.isArray(uData.fcmTokens) && uData.fcmTokens.length > 0) {
      const last = uData.fcmTokens[uData.fcmTokens.length - 1];
      if (last && typeof last === 'string' && last.trim().length > 0) {
        return last.trim();
      }
    }
    return null;
  } catch (err) {
    console.warn(`[Worker] Error fetching token for user ${uid}:`, err.message);
    return null;
  }
}

// ─── Core Dispatch Function ───────────────────────────────────────────────────
/**
 * Sends a single high-priority push notification to a user's active device.
 */
async function sendPushToUser({
  uid,
  token,
  title,
  body,
  type = 'general',
  relatedId = '',
  dataPayload = {},
}) {
  if (isDuplicate(uid, title, body)) {
    console.log(`[Worker] Dedup: suppressed duplicate push for user ${uid}: "${title}"`);
    return { success: false, duplicate: true };
  }

  const isChat = type === 'chat';
  const channelId = isChat ? 'chat_messages' : 'autoshare_notifications';
  const collapseTag = `${type || 'general'}_${relatedId || uid}`;

  // Prepare stringified data payload for FCM client
  const stringifiedData = {};
  for (const [key, value] of Object.entries(dataPayload || {})) {
    stringifiedData[key] = value != null ? String(value) : '';
  }
  stringifiedData.type = stringifiedData.type || type || 'general';
  stringifiedData.relatedId = stringifiedData.relatedId || relatedId || '';
  stringifiedData.rideId = stringifiedData.rideId || relatedId || '';
  stringifiedData.click_action = 'FLUTTER_NOTIFICATION_CLICK';

  const message = {
    token,
    notification: {
      title,
      body,
    },
    data: stringifiedData,
    android: {
      priority: 'high',
      collapseKey: collapseTag,
      ttl: 2419200000,
      notification: {
        channelId,
        sound: 'default',
        priority: 'max',
        visibility: 'public',
        icon: 'ic_launcher',
        color: '#FFC400',
        tag: collapseTag,
      },
    },
    apns: {
      payload: {
        aps: {
          alert: { title, body },
          sound: 'default',
          badge: 1,
          contentAvailable: true,
        },
      },
    },
  };

  try {
    const response = await messaging.send(message);
    console.log(`[Worker] Push sent to user ${uid} (token ${token.substring(0, 10)}...): "${title}" | ID: ${response}`);
    return { success: true };
  } catch (err) {
    console.error(`[Worker] Error sending push to user ${uid}:`, err.message);
    const errCode = err.code || '';
    if (
      errCode === 'messaging/invalid-registration-token' ||
      errCode === 'messaging/registration-token-not-registered'
    ) {
      try {
        await db.collection('users').doc(uid).update({
          fcmTokens: FieldValue.arrayRemove(token),
          fcmToken: FieldValue.delete(),
        });
        console.log(`[Worker] Pruned unregistered/invalid token for user ${uid}`);
      } catch (_) {}
    }
    return { success: false, error: err };
  }
}

// ─── Real-time Listener 1: `notifications` Collection ─────────────────────────
// This collection receives all in-app notifications (new ride requests, accepts, updates, chats).
const workerStartTime = Date.now();
// Disregard notifications created more than 45 seconds before the worker started
const historicalCutoffMs = workerStartTime - 45000;

const unsubscribeNotifications = db
  .collection('notifications')
  .onSnapshot(
    async (snapshot) => {
      for (const change of snapshot.docChanges()) {
        if (change.type === 'added' || change.type === 'modified') {
          const doc = change.doc;
          const data = doc.data();

          if (!data) continue;
          if (data.pushSent === true) continue;

          // Check timestamp to avoid blasting past notifications on worker reboot
          let createdAtMs = Date.now();
          if (data.createdAt && typeof data.createdAt.toMillis === 'function') {
            createdAtMs = data.createdAt.toMillis();
          } else if (data.createdAt && typeof data.createdAt.toDate === 'function') {
            createdAtMs = data.createdAt.toDate().getTime();
          }

          if (createdAtMs < historicalCutoffMs) {
            // Mark pushSent: true without sending FCM message to avoid historical blast
            await doc.ref.update({ pushSent: true }).catch(() => {});
            continue;
          }

          const uid = data.userId;
          if (!uid || typeof uid !== 'string') continue;

          const title = data.title || 'AutoShare';
          const body = data.body || '';
          const type = data.type || 'general';
          const relatedId = data.relatedId || '';

          // Mark as pushSent immediately to prevent race conditions across parallel snapshot fires
          try {
            await doc.ref.update({
              pushSent: true,
              pushSentAt: FieldValue.serverTimestamp(),
            });
          } catch (updateErr) {
            continue;
          }

          const token = await getActiveTokenForUser(uid);
          if (token) {
            await sendPushToUser({
              uid,
              token,
              title,
              body,
              type,
              relatedId,
              dataPayload: {
                type,
                relatedId,
                rideId: relatedId,
                senderId: data.senderId || '',
              },
            });
          } else {
            console.log(`[Worker] No active FCM token found for user ${uid} (notification: "${title}")`);
          }
        }
      }
    },
    (err) => {
      console.error('[Worker] notifications snapshot listener error:', err);
    }
  );

// ─── Real-time Listener 2: `push_notifications` Queue Collection ──────────────
const unsubscribeQueue = db
  .collection('push_notifications')
  .where('status', '==', 'pending')
  .onSnapshot(
    async (snapshot) => {
      for (const change of snapshot.docChanges()) {
        if (change.type === 'added' || change.type === 'modified') {
          const doc = change.doc;
          const data = doc.data();

          if (data.status !== 'pending') continue;

          try {
            await doc.ref.update({
              status: 'processing',
              processingStartedAt: FieldValue.serverTimestamp(),
            });
          } catch (_) {
            continue;
          }

          let recipientUids = data.recipientUids || [];
          if (typeof recipientUids === 'string') {
            recipientUids = [recipientUids];
          }
          if (data.recipientUid && !recipientUids.includes(data.recipientUid)) {
            recipientUids.push(data.recipientUid);
          }

          const uniqueRecipients = Array.from(new Set(recipientUids.filter(Boolean)));
          const title = data.title || 'AutoShare';
          const body = data.body || '';
          const type = data.type || 'general';
          const relatedId = data.relatedId || '';
          const dataPayload = data.data || {};

          for (const uid of uniqueRecipients) {
            const token = await getActiveTokenForUser(uid);
            if (token) {
              await sendPushToUser({
                uid,
                token,
                title,
                body,
                type,
                relatedId,
                dataPayload,
              });
            } else {
              console.log(`[Worker] No token found for queue recipient ${uid}`);
            }
          }

          await doc.ref.update({
            status: 'completed',
            completedAt: FieldValue.serverTimestamp(),
          }).catch(() => {});
        }
      }
    },
    (err) => {
      console.error('[Worker] push_notifications snapshot listener error:', err);
    }
  );

// ─── Graceful Shutdown ────────────────────────────────────────────────────────
function shutdown() {
  console.log('[Worker] Shutting down AutoShare notification worker gracefully...');
  unsubscribeNotifications();
  unsubscribeQueue();
  process.exit(0);
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
