const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Function to automatically add sender name to discussion messages
exports.addSenderNameToMessage = functions.database
  .ref('/discussion/{messageId}')
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.val();
    const messageId = context.params.messageId;

    // Check if senderName is missing
    if (!messageData.senderName && messageData.senderId) {
      try {
        // Get user data from users collection
        const userSnapshot = await admin.database().ref(`/users/${messageData.senderId}`).once('value');
        const userData = userSnapshot.val();

        let senderName = 'Unknown User';

        if (userData) {
          // Try to get name from various fields
          senderName = userData.name || userData.displayName || userData.email?.split('@')[0] || `User${Math.floor(Math.random() * 1000)}`;
        } else {
          // If user data doesn't exist, try to get from Firebase Auth
          try {
            const userRecord = await admin.auth().getUser(messageData.senderId);
            senderName = userRecord.displayName || userRecord.email?.split('@')[0] || `User${Math.floor(Math.random() * 1000)}`;

            // Create user record if it doesn't exist
            await admin.database().ref(`/users/${messageData.senderId}`).set({
              name: senderName,
              displayName: senderName,
              email: userRecord.email || '',
              createdAt: admin.database.ServerValue.TIMESTAMP,
            });
          } catch (authError) {
            console.error('Error getting user from Auth:', authError);
            senderName = `User${Math.floor(Math.random() * 1000)}`;
          }
        }

        // Update the message with sender name
        await admin.database().ref(`/discussion/${messageId}`).update({
          senderName: senderName
        });

        console.log(`Added sender name "${senderName}" to message ${messageId}`);

      } catch (error) {
        console.error('Error adding sender name to message:', error);
      }
    }

    return null;
  });

// Function to ensure user data exists when a new user is created
exports.createUserProfile = functions.auth.user().onCreate(async (user) => {
  try {
    const defaultName = user.displayName || user.email?.split('@')[0] || `User${Math.floor(Math.random() * 1000)}`;

    await admin.database().ref(`/users/${user.uid}`).set({
      name: defaultName,
      displayName: defaultName,
      email: user.email || '',
      createdAt: admin.database.ServerValue.TIMESTAMP,
    });

    console.log(`Created user profile for ${user.uid} with name "${defaultName}"`);
  } catch (error) {
    console.error('Error creating user profile:', error);
  }
});

exports.sendStatusUpdateNotification = functions.database
  .ref('/complaints/{complaintId}')
  .onUpdate(async (change, context) => {
    const before = change.before.val();
    const after = change.after.val();

    // Check if status has changed
    if (before.status === after.status) {
      console.log('Status unchanged, no notification needed');
      return null;
    }

    try {
      // Get user details
      const userId = after.user_id;
      if (!userId) {
        console.error('No user_id found in complaint data');
        return null;
      }

      const userSnapshot = await admin.database().ref(`/users/${userId}`).once('value');
      const userData = userSnapshot.val();

      if (!userData) {
        console.error('User data not found for ID:', userId);
        return null;
      }

      // Check for FCM token
      const fcmToken = userData.fcmToken;
      if (!fcmToken) {
        console.warn('No FCM token found for user:', userId);
        return null;
      }

      const issueTitle = after.issue_type || 'Your complaint';
      const newStatus = after.status;
      const adminNote = after.admin_note || '';

      // Create notification payload
      const payload = {
        notification: {
          title: `Status Update: ${issueTitle}`,
          body: adminNote
            ? `Your issue has been marked as ${newStatus}. ${adminNote}`
            : `Your issue has been marked as ${newStatus}.`,
          icon: '@mipmap/ic_launcher',
          sound: 'default',
        },
        data: {
          complaintId: context.params.complaintId,
          newStatus: newStatus,
          issueTitle: issueTitle,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
      };

      // Send notification with retry logic
      let response;
      try {
        response = await admin.messaging().sendToDevice(fcmToken, payload);
        console.log('Successfully sent notification:', response);

        // Count successful and failed message sends
        const successCount = response.successCount || 0;
        const failureCount = response.failureCount || 0;

        if (failureCount > 0 && response.results && response.results.length > 0) {
          console.warn('Some notification sends failed:', response.results);
        }
      } catch (sendError) {
        console.error('Error sending notification:', sendError);
        // Allow function to continue to store notification history even if send fails
      }

      // Log the notification in user's notification history (even if send fails)
      try {
        const notificationRef = admin.database().ref(`/users/${userId}/notifications`).push();
        await notificationRef.set({
          title: payload.notification.title,
          body: payload.notification.body,
          timestamp: admin.database.ServerValue.TIMESTAMP,
          complaintId: context.params.complaintId,
          status: newStatus,
          read: false,
        });
        console.log('Notification saved to history');
      } catch (historyError) {
        console.error('Failed to save notification to history:', historyError);
      }

      return response || null;
    } catch (error) {
      console.error('Error in sendStatusUpdateNotification function:', error);
      return null;
    }
  });

// Function to handle admin notes with notifications
exports.sendAdminNoteNotification = functions.database
  .ref('/complaints/{complaintId}/admin_note')
  .onUpdate(async (change, context) => {
    const newNote = change.after.val();
    const beforeNote = change.before.val();

    if (!newNote || newNote === beforeNote) {
      console.log('Admin note unchanged or empty, no notification needed');
      return null;
    }

    try {
      const complaintSnapshot = await admin.database().ref(`/complaints/${context.params.complaintId}`).once('value');
      const complaint = complaintSnapshot.val();

      if (!complaint) {
        console.error('Complaint data not found for ID:', context.params.complaintId);
        return null;
      }

      if (!complaint.user_id) {
        console.error('No user_id found in complaint data');
        return null;
      }

      const userId = complaint.user_id;
      const userSnapshot = await admin.database().ref(`/users/${userId}`).once('value');
      const userData = userSnapshot.val();

      if (!userData) {
        console.error('User data not found for ID:', userId);
        return null;
      }

      // Check for FCM token
      if (!userData.fcmToken) {
        console.warn('No FCM token found for user:', userId);
        return null;
      }

      const payload = {
        notification: {
          title: `Update on: ${complaint.issue_type || 'Your complaint'}`,
          body: newNote,
          icon: '@mipmap/ic_launcher',
          sound: 'default',
        },
        data: {
          complaintId: context.params.complaintId,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
      };

      // Send notification with error handling
      let response;
      try {
        response = await admin.messaging().sendToDevice(userData.fcmToken, payload);
        console.log('Successfully sent admin note notification:', response);

        // Count successful and failed message sends
        const successCount = response.successCount || 0;
        const failureCount = response.failureCount || 0;

        if (failureCount > 0 && response.results && response.results.length > 0) {
          console.warn('Some admin note notification sends failed:', response.results);
        }
      } catch (sendError) {
        console.error('Error sending admin note notification:', sendError);
        // Allow function to continue to store notification history even if send fails
      }

      // Log the notification in history even if send fails
      try {
        const notificationRef = admin.database().ref(`/users/${userId}/notifications`).push();
        await notificationRef.set({
          title: payload.notification.title,
          body: payload.notification.body,
          timestamp: admin.database.ServerValue.TIMESTAMP,
          complaintId: context.params.complaintId,
          read: false,
        });
        console.log('Admin note notification saved to history');
      } catch (historyError) {
        console.error('Failed to save admin note notification to history:', historyError);
      }

      return response || null;
    } catch (error) {
      console.error('Error in sendAdminNoteNotification function:', error);
      return null;
    }
  });

// Function to handle FCM token refreshes
exports.handleTokenRefresh = functions.database
  .ref('/users/{userId}/fcmToken')
  .onWrite(async (change, context) => {
    const newToken = change.after.val();
    const userId = context.params.userId;

    // If token is being deleted, skip
    if (!newToken) {
      console.log('FCM token removed for user:', userId);
      return null;
    }

    try {
      console.log(`FCM token ${change.before.exists() ? 'updated' : 'created'} for user: ${userId}`);

      // You could add additional logic here if needed, such as:
      // - Update user's subscription topics
      // - Send a welcome notification to the new token
      // - Log device information

      return null;
    } catch (error) {
      console.error('Error in handleTokenRefresh function:', error);
      return null;
    }
  });
