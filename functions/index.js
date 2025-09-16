const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Helper: fetch user data from Realtime DB or Auth
 */
async function getUserData(userId) {
  try {
    const snapshot = await admin.database().ref(`/users/${userId}`).once('value');
    let data = snapshot.val();
    if (!data) {
      const userRecord = await admin.auth().getUser(userId);
      const name = userRecord.displayName || userRecord.email?.split('@')[0] || `User${Math.floor(Math.random() * 1000)}`;
      data = { name, displayName: name, email: userRecord.email || '', createdAt: admin.database.ServerValue.TIMESTAMP };
      await admin.database().ref(`/users/${userId}`).set(data);
    }
    return data;
  } catch (error) {
    console.error('Error fetching user data:', error);
    return { name: `User${Math.floor(Math.random() * 1000)}` };
  }
}

/**
 * Helper: send FCM notification and log to user's notification history
 */
async function sendFCMNotification(userId, payload) {
  try {
    const userSnapshot = await admin.database().ref(`/users/${userId}`).once('value');
    const userData = userSnapshot.val();
    if (!userData?.fcmToken) {
      console.warn(`No FCM token found for user ${userId}`);
      return null;
    }

    const response = await admin.messaging().sendToDevice(userData.fcmToken, payload);
    console.log(`Notification sent to user ${userId}:`, response);

    await admin.database().ref(`/users/${userId}/notifications`).push().set({
      ...payload.notification,
      timestamp: admin.database.ServerValue.TIMESTAMP,
      complaintId: payload.data?.complaintId || null,
      reportId: payload.data?.reportId || null,
      read: false,
    });

    return response;
  } catch (error) {
    console.error('Error sending notification:', error);
    return null;
  }
}

/**
 * Function: Add sender name to discussion messages
 */
exports.addSenderNameToMessage = functions.database
  .ref('/discussion/{messageId}')
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.val();
    const messageId = context.params.messageId;
    if (!messageData.senderName && messageData.senderId) {
      try {
        const userData = await getUserData(messageData.senderId);
        const updateData = {
          senderName: userData.name,
          createdAt: admin.database.ServerValue.TIMESTAMP,
        };

        // Add replied message info
        if (messageData.replyTo) {
          const repliedSnapshot = await admin.database().ref(`/discussion/${messageData.replyTo}`).once('value');
          const repliedData = repliedSnapshot.val();
          if (repliedData) {
            updateData.replyToMessage = repliedData.message || '';
            updateData.replyToSender = repliedData.senderName || 'Unknown User';
          }
        }

        await admin.database().ref(`/discussion/${messageId}`).update(updateData);
        console.log(`Added sender name "${updateData.senderName}" to message ${messageId}`);
      } catch (error) {
        console.error('Error in addSenderNameToMessage:', error);
      }
    }
    return null;
  });

/**
 * Function: Create user profile on Auth creation
 */
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

/**
 * Function: Send status update notification for complaints
 */
exports.sendStatusUpdateNotification = functions.database
  .ref('/complaints/{complaintId}')
  .onUpdate(async (change, context) => {
    const before = change.before.val();
    const after = change.after.val();
    if (before.status === after.status) return null;

    const payload = {
      notification: {
        title: `Status Update: ${after.issue_type || 'Your complaint'}`,
        body: after.admin_note ? `Your issue has been marked as ${after.status}. ${after.admin_note}` : `Your issue has been marked as ${after.status}.`,
        icon: '@mipmap/ic_launcher',
        sound: 'default',
      },
      data: {
        complaintId: context.params.complaintId,
        newStatus: after.status,
        issueTitle: after.issue_type || 'Your complaint',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    };

    return await sendFCMNotification(after.user_id, payload);
  });

/**
 * Function: Send admin note notification
 */
exports.sendAdminNoteNotification = functions.database
  .ref('/complaints/{complaintId}/admin_note')
  .onUpdate(async (change, context) => {
    const newNote = change.after.val();
    if (!newNote || newNote === change.before.val()) return null;

    const complaintSnapshot = await admin.database().ref(`/complaints/${context.params.complaintId}`).once('value');
    const complaint = complaintSnapshot.val();
    if (!complaint?.user_id) return null;

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

    return await sendFCMNotification(complaint.user_id, payload);
  });

/**
 * Function: Handle FCM token refresh
 */
exports.handleTokenRefresh = functions.database
  .ref('/users/{userId}/fcmToken')
  .onWrite(async (change, context) => {
    const newToken = change.after.val();
    if (!newToken) return null;
    console.log(`FCM token ${change.before.exists() ? 'updated' : 'created'} for user ${context.params.userId}`);
    return null;
  });

/**
 * Function: Prevent banned users from posting
 */
exports.checkUserBanStatus = functions.database
  .ref('/discussion/{messageId}')
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.val();
    const messageId = context.params.messageId;
    const senderId = messageData.senderId;
    if (!senderId) return null;

    const bannedSnapshot = await admin.database().ref(`/banned_users/${senderId}`).once('value');
    if (bannedSnapshot.exists()) {
      await admin.database().ref(`/discussion/${messageId}`).remove();
      await admin.database().ref('/discussion').push().set({
        message: "A message from a banned user was automatically removed",
        messageType: "system",
        timestamp: admin.database.ServerValue.TIMESTAMP,
        createdAt: admin.database.ServerValue.TIMESTAMP,
        senderName: "System",
        senderId: "system",
      });
      console.log(`Blocked message from banned user ${senderId}`);
    }
    return null;
  });

/**
 * Function: Handle message reports
 */
exports.handleMessageReport = functions.database
  .ref('/message_reports/{reportId}')
  .onCreate(async (snapshot, context) => {
    const reportData = snapshot.val();
    const reportId = context.params.reportId;

    const messageSnapshot = await admin.database().ref(`/discussion/${reportData.messageId}`).once('value');
    const messageData = messageSnapshot.val();
    if (!messageData) return null;

    const reporterData = await getUserData(reportData.reporterId);
    const reportedUserData = await getUserData(reportData.reportedUserId);

    const adminNotification = {
      type: 'message_report',
      reportId,
      messageId: reportData.messageId,
      reportedUserId: reportData.reportedUserId,
      reportedUserName: reportedUserData.name || 'Unknown User',
      reporterId: reportData.reporterId,
      reporterName: reporterData.name || 'Unknown User',
      reason: reportData.reportReason,
      messageContent: reportData.messageContent || messageData.message || 'Media/Poll content',
      additionalDetails: reportData.additionalDetails || '',
      timestamp: admin.database.ServerValue.TIMESTAMP,
      status: 'pending',
      priority: _getReportPriority(reportData.reportReason),
    };

    await admin.database().ref('/admin_notifications').push().set(adminNotification);
    console.log(`Message report created: ${reportId} for reason: ${reportData.reportReason}`);
    return null;
  });

function _getReportPriority(reason) {
  const high = ['harassment', 'hate_speech', 'privacy_violation'];
  const medium = ['inappropriate_content', 'misinformation'];
  if (high.includes(reason)) return 'high';
  if (medium.includes(reason)) return 'medium';
  return 'low';
}

/**
 * Function: Send report update notifications
 */
exports.sendReportUpdateNotification = functions.database
  .ref('/message_reports/{reportId}')
  .onUpdate(async (change, context) => {
    const before = change.before.val();
    const after = change.after.val();
    if (before.status === after.status) return null;

    let body = '';
    switch (after.status) {
      case 'reviewed':
        body = 'Your report has been reviewed by our moderation team.';
        break;
      case 'resolved':
        body = 'Your report has been resolved. Thank you for helping keep our community safe.';
        break;
      case 'dismissed':
        body = 'Your report has been reviewed and dismissed. No violation was found.';
        break;
      default:
        body = `Your report status has been updated to ${after.status}.`;
    }
    if (after.adminNote && after.adminNote !== before.adminNote) body += ` Note: ${after.adminNote}`;

    const payload = {
      notification: { title: 'Report Update', body, icon: '@mipmap/ic_launcher', sound: 'default' },
      data: { reportId: context.params.reportId, newStatus: after.status, click_action: 'FLUTTER_NOTIFICATION_CLICK' },
    };

    return await sendFCMNotification(after.reporterId, payload);
  });
