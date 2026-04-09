require('dotenv').config();
const express = require('express');
const cors = require('cors');
const axios = require('axios');
const admin = require('firebase-admin');

const app = express();
app.use(cors());
app.use(express.json());

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

const CHAPA_SECRET_KEY = process.env.CHAPA_SECRET_KEY || '';
const CHAPA_CALLBACK_URL = process.env.CHAPA_CALLBACK_URL || '';
const PAYMENT_RETURN_URL = process.env.PAYMENT_RETURN_URL || '';
const CHAPA_BASE_URL = 'https://api.chapa.co/v1';
const PORT = Number(process.env.PORT || 8787);
const CHAPA_TIMEOUT_MS = Number(process.env.CHAPA_TIMEOUT_MS || 15000);

const catalog = {
  points_10: { amount: 100, kind: 'points', points: 10 },
  points_25: { amount: 225, kind: 'points', points: 25 },
  points_50: { amount: 400, kind: 'points', points: 50 },
  silver_monthly: { amount: 300, kind: 'subscription', plan: 'silver', days: 30 },
  gold_monthly: { amount: 600, kind: 'subscription', plan: 'gold', days: 30 },
  gold_quarterly: {
    amount: 1600,
    kind: 'subscription',
    plan: 'quarterly_gold',
    days: 90
  }
};

function monthKey(date) {
  const m = String(date.getMonth() + 1).padStart(2, '0');
  return `${date.getFullYear()}-${m}`;
}

app.get('/health', (req, res) => {
  res.json({ ok: true });
});

/**
 * Haversine formula to calculate distance between two lat/lng points in km.
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth's radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// --- DISCOVERY & MATCHING ---

app.post('/api/discovery/nearby', async (req, res) => {
  try {
    const { uid, lat, lng, radius = 50 } = req.body;
    if (!uid || lat === undefined || lng === undefined) {
      return res.status(400).json({ message: 'uid, lat, and lng are required.' });
    }

    // Get requester's gender to filter
    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) return res.status(404).json({ message: 'User not found' });
    
    const userData = userDoc.data();
    const myGender = (userData.gender || 'male').toLowerCase();
    const targetGender = myGender === 'male' ? 'female' : 'male';

    // Fetch potential matches
    const usersSnap = await db.collection('users')
      .where('gender', '==', targetGender)
      .limit(100)
      .get();

    const nearbyUsers = [];
    usersSnap.forEach(doc => {
      if (doc.id === uid) return;
      const data = doc.data();
      if (data.latitude && data.longitude) {
        const dist = calculateDistance(lat, lng, data.latitude, data.longitude);
        if (dist <= radius) {
          nearbyUsers.push({
            id: doc.id,
            name: data.name,
            age: data.age,
            profileImageUrl: data.profileImageUrl,
            gender: data.gender,
            heritage: data.heritage,
            religion: data.religion,
            distance: parseFloat(dist.toFixed(2))
          });
        }
      }
    });

    // Sort by distance
    nearbyUsers.sort((a, b) => a.distance - b.distance);
    
    return res.json(nearbyUsers.slice(0, 20));
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
});

app.get('/payment-return', (req, res) => {
  res.status(200).send('Payment completed. You can return to the app.');
});

app.post('/payments/chapa/webhook', async (req, res) => {
  try {
    // Chapa callback target: keep it 200/OK so callbacks do not fail.
    // Payload shapes can vary; we persist minimal audit fields.
    const body = req.body || {};
    const txRef = body?.tx_ref || body?.txRef || body?.data?.tx_ref || null;
    await db.collection('payment_webhooks').add({
      provider: 'chapa',
      txRef,
      payload: body,
      receivedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    return res.status(200).json({ received: true });
  } catch (error) {
    return res.status(500).json({ received: false, message: error.message });
  }
});

app.post('/payments/chapa/initialize', async (req, res) => {
  try {
    if (!CHAPA_SECRET_KEY) {
      return res.status(500).json({ message: 'Missing CHAPA_SECRET_KEY in server env.' });
    }

    const { uid, email, firstName, lastName, phoneNumber, sku, amount, currency } = req.body || {};
    if (!uid || !email || !sku) {
      return res.status(400).json({ message: 'uid, email, and sku are required.' });
    }
    if (!CHAPA_CALLBACK_URL) {
      return res.status(500).json({
        message:
          'Missing CHAPA_CALLBACK_URL in server env. It must be a public https webhook endpoint.'
      });
    }
    if (!PAYMENT_RETURN_URL || !/^https?:\/\//i.test(PAYMENT_RETURN_URL)) {
      return res.status(500).json({
        message:
          'Missing/invalid PAYMENT_RETURN_URL in server env. Use a public https URL.'
      });
    }
    const product = catalog[sku];
    if (!product) {
      return res.status(400).json({ message: 'Invalid sku.' });
    }
    if (Number(amount) !== product.amount) {
      return res.status(400).json({ message: 'Amount mismatch for sku.' });
    }

    let safeEmail = (email || '').toString().trim();
    const isEmailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(safeEmail);
    if (!isEmailPattern || safeEmail.endsWith('@example.com')) {
      const key = (uid || 'user').toString().replace(/[^a-zA-Z0-9]/g, '').slice(0, 12) || 'user';
      safeEmail = `${key}@gmail.com`;
    }

    const txRef = `hd_${uid}_${Date.now()}`;
    const safeDescription = `Purchase ${sku}`.replace(/[^A-Za-z0-9\-_. ]/g, '');

    const payload = {
      amount: String(product.amount),
      currency: currency || 'ETB',
      email: safeEmail,
      first_name: firstName || 'Habesha',
      last_name: lastName || 'User',
      phone_number: phoneNumber || undefined,
      tx_ref: txRef,
      callback_url: CHAPA_CALLBACK_URL,
      return_url: PAYMENT_RETURN_URL,
      customization: {
        title: 'Habesha Dates',
        description: safeDescription
      },
      meta: {
        app: 'habesha_dates',
        sku
      }
    };

    const chapaRes = await axios.post(
      `${CHAPA_BASE_URL}/transaction/initialize`,
      payload,
      {
        headers: {
          Authorization: `Bearer ${CHAPA_SECRET_KEY}`,
          'Content-Type': 'application/json'
        },
        timeout: CHAPA_TIMEOUT_MS
      }
    );

    const checkoutUrl = chapaRes.data?.data?.checkout_url;
    if (!checkoutUrl) {
      return res.status(502).json({ message: 'Chapa did not return checkout_url.', raw: chapaRes.data });
    }

    await db.collection('payment_intents').doc(txRef).set({
      uid,
      sku,
      amount: product.amount,
      currency: 'ETB',
      status: 'initialized',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return res.json({ checkoutUrl, txRef });
  } catch (error) {
    return res.status(500).json({
      message: 'Failed to initialize payment.',
      error: error?.response?.data || error.message || 'Unknown error'
    });
  }
});

app.post('/payments/chapa/verify', async (req, res) => {
  try {
    if (!CHAPA_SECRET_KEY) {
      return res.status(500).json({ success: false, message: 'Missing CHAPA_SECRET_KEY in server env.' });
    }
    const { txRef, uid, sku } = req.body || {};
    if (!txRef || !uid || !sku) {
      return res.status(400).json({ success: false, message: 'txRef, uid, sku are required.' });
    }
    const product = catalog[sku];
    if (!product) {
      return res.status(400).json({ success: false, message: 'Invalid sku.' });
    }

    const verifyRes = await axios.get(
      `${CHAPA_BASE_URL}/transaction/verify/${txRef}`,
      {
        headers: { Authorization: `Bearer ${CHAPA_SECRET_KEY}` },
        timeout: CHAPA_TIMEOUT_MS
      }
    );
    const data = verifyRes.data?.data || {};
    const status = String(data?.status || '').toLowerCase();
    const paidAmount = Number(data?.amount || 0);
    const currency = String(data?.currency || '').toUpperCase();

    if (status !== 'success') {
      return res.json({
        success: false,
        txRef,
        message: `Payment status is ${status || 'unknown'}.`
      });
    }
    if (paidAmount !== product.amount || currency !== 'ETB') {
      return res.status(400).json({
        success: false,
        txRef,
        message: 'Payment amount or currency does not match expected values.'
      });
    }

    const paymentRef = db.collection('payment_transactions').doc(txRef);
    const userRef = db.collection('users').doc(uid);

    await db.runTransaction(async (tx) => {
      const paidDoc = await tx.get(paymentRef);
      if (paidDoc.exists) {
        return;
      }

      if (product.kind === 'points') {
        tx.set(
          userRef,
          {
            access: {
              pointsBalance: admin.firestore.FieldValue.increment(product.points)
            }
          },
          { merge: true }
        );
      } else {
        const now = new Date();
        const endsAt = new Date(now.getTime() + product.days * 24 * 60 * 60 * 1000);
        tx.set(
          userRef,
          {
            access: {
              subscriptionPlan: product.plan,
              subscriptionStartedAt: admin.firestore.Timestamp.fromDate(now),
              subscriptionEndsAt: admin.firestore.Timestamp.fromDate(endsAt),
              monthlyUsageKey: monthKey(now),
              monthlyFreeUsed: 0
            }
          },
          { merge: true }
        );
      }

      tx.set(paymentRef, {
        uid,
        sku,
        txRef,
        transactionId: data?.id?.toString() || null,
        amount: product.amount,
        currency: 'ETB',
        provider: 'chapa',
        status: 'applied',
        paidAt: admin.firestore.FieldValue.serverTimestamp()
      });

      tx.set(
        db.collection('payment_intents').doc(txRef),
        {
          status: 'verified',
          verifiedAt: admin.firestore.FieldValue.serverTimestamp()
        },
        { merge: true }
      );
    });

    return res.json({
      success: true,
      message: 'Payment verified and entitlement applied.',
      txRef,
      transactionId: data?.id?.toString() || null
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to verify payment.',
      error: error?.response?.data || error.message || 'Unknown error'
    });
  }
});

app.listen(PORT, () => {
  console.log(`Payment server listening on http://localhost:${PORT}`);
});
