package com.example.nagarsur

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import android.util.Log
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.database.FirebaseDatabase

class MyFirebaseMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        Log.d("FirebaseMsg", "Message Received: ${remoteMessage.data}")
        
        // Process the notification here
        remoteMessage.notification?.let { notification ->
            val title = notification.title
            val body = notification.body
            Log.d("FirebaseMsg", "Notification Title: $title, Body: $body")
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d("FirebaseMsg", "New Token: $token")
        
        // Save the new token to Firebase for the current user
        val currentUser = FirebaseAuth.getInstance().currentUser
        if (currentUser != null) {
            val userId = currentUser.uid
            val database = FirebaseDatabase.getInstance()
            val userRef = database.getReference("users/$userId/fcmToken")
            
            userRef.setValue(token)
                .addOnSuccessListener {
                    Log.d("FirebaseMsg", "Token saved to Firebase for user: $userId")
                }
                .addOnFailureListener { e ->
                    Log.e("FirebaseMsg", "Failed to save token to Firebase", e)
                }
        } else {
            Log.w("FirebaseMsg", "User not logged in, token not saved")
        }
    }
}
