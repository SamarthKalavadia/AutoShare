package com.autoshare.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .build()

            val defaultChannel = NotificationChannel(
                "autoshare_notifications",
                "AutoShare Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Real-time notifications for rides, bookings, and alerts"
                enableVibration(true)
                enableLights(true)
                setSound(defaultSoundUri, audioAttributes)
            }

            val chatChannel = NotificationChannel(
                "chat_messages",
                "Chat Messages",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Real-time chat messages and conversations"
                enableVibration(true)
                enableLights(true)
                setSound(defaultSoundUri, audioAttributes)
            }

            val reminderChannel = NotificationChannel(
                "ride_reminders",
                "Ride Reminders",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications before a ride starts"
                enableVibration(true)
                enableLights(true)
                setSound(defaultSoundUri, audioAttributes)
            }

            notificationManager.createNotificationChannel(defaultChannel)
            notificationManager.createNotificationChannel(chatChannel)
            notificationManager.createNotificationChannel(reminderChannel)
        }
    }
}
