package com.example.healthmate

import android.app.*
import android.content.*
import android.os.Build
import java.util.Calendar

object BedtimeReminders {
    private fun pending(context: Context) = PendingIntent.getBroadcast(context, 7100,
        Intent(context, BedtimeReminderReceiver::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    fun cancel(context: Context, dismiss: Boolean = true) {
        context.getSystemService(AlarmManager::class.java).cancel(pending(context))
        if (dismiss) context.getSystemService(NotificationManager::class.java).cancel(7300)
    }
    fun schedule(context: Context) {
        cancel(context, false)
        val storage = WellnessStorage(context)
        val uid = storage.activeUid() ?: return
        val settings = storage.read(uid, "sleepReminder")
        if (!MealReminders.allowed(context) || !settings.optBoolean("enabled")) return
        val minute = settings.optInt("minute", -1)
        if (minute !in 0..1439) return
        val next = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, minute / 60); set(Calendar.MINUTE, minute % 60)
            set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DAY_OF_YEAR, 1)
        }
        context.getSystemService(AlarmManager::class.java).setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.timeInMillis, pending(context))
    }
    fun show(context: Context) {
        if (!MealReminders.allowed(context)) return
        val uid = WellnessStorage(context).activeUid() ?: return
        val manager = context.getSystemService(NotificationManager::class.java)
        val channel = "healthmate_bedtime"
        if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(NotificationChannel(channel, "Nhắc giờ ngủ", NotificationManager.IMPORTANCE_DEFAULT))
        val launch = Intent(context, MainActivity::class.java).setAction("healthmate.OPEN_SLEEP")
            .putExtra("sleepReminderUid", uid).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val tap = PendingIntent.getActivity(context, 7200, launch, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, channel) else Notification.Builder(context)
        manager.notify(7300, builder.setSmallIcon(R.drawable.ic_wellness_notification).setContentTitle("Đến giờ nghỉ ngơi bạn đã chọn")
            .setContentText("Mở HealthMate khi bạn muốn ghi lại giờ ngủ.").setContentIntent(tap).setAutoCancel(true)
            .setVisibility(Notification.VISIBILITY_PRIVATE).build())
    }
}
class BedtimeReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            val storage = WellnessStorage(context)
            val uid = storage.activeUid() ?: return
            if (storage.read(uid,"sleepReminder").optBoolean("enabled")) BedtimeReminders.show(context)
            BedtimeReminders.schedule(context)
        } catch (_: Exception) { }
    }
}
