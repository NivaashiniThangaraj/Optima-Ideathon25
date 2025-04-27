const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

exports.autoPlaceOrder = functions.firestore
  .document('materials/{materialId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    const quantity = after.quantity;
    const threshold = after.threshold ?? 0;
    const name = after.name;

    // If quantity dropped below threshold
    if (quantity < threshold && before.quantity >= threshold) {
      // Check if an order is already placed (optional: prevent duplicate orders)
      const recentOrders = await db.collection('orders')
        .where('name', '==', name)
        .orderBy('time', 'desc')
        .limit(1)
        .get();

      if (!recentOrders.empty) {
        const lastOrderTime = recentOrders.docs[0].data().time.toDate();
        const now = new Date();
        const timeDiff = (now - lastOrderTime) / (1000 * 60); // in minutes
        if (timeDiff < 10) {
          console.log("Order already placed recently. Skipping...");
          return null;
        }
      }

      // Add new order
      await db.collection('orders').add({
        name: name,
        quantity: quantity,
        time: admin.firestore.FieldValue.serverTimestamp()
      });

      console.log(`Order placed for ${name}`);
    }

    return null;
  });
