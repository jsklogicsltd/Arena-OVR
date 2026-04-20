const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
admin.initializeApp();

exports.morningMotivationPush = onSchedule({
    schedule: "0 7 * * *",
    timeZone: "America/Chicago"
}, async (event) => {
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = yesterday.toISOString().split('T')[0];

    const usersRef = admin.firestore().collection('users');
    const snapshot = await usersRef.where('role', '==', 'athlete').get();

    const messages = [];

    snapshot.forEach(doc => {
        const user = doc.data();

        // Ensure token, date, and points exist
        if (user.fcmToken && user.lastPointDate && user.dailyPoints) {
            const lastPointStr = user.lastPointDate.toDate().toISOString().split('T')[0];

            // Check if points were earned yesterday AND if they earned 5 or more
            if (lastPointStr === yesterdayStr && user.dailyPoints >= 5) {
                messages.push({
                    token: user.fcmToken,
                    notification: {
                        title: "You Crushed It! 🔥",
                        body: `Great job yesterday! You earned ${user.dailyPoints} points. Let's do it again today.`
                    }
                });
            }
        }
    });

    if (messages.length > 0) {
        await admin.messaging().sendEach(messages);
        console.log(`Sent ${messages.length} personalized motivation notifications.`);
    } else {
        console.log("No users qualified for the morning notification today. (Test)");
    }
});