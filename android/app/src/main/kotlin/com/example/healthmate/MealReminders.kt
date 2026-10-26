package com.example.healthmate

import android.app.*
import android.content.*
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

object MealReminders {
    val meals = listOf("breakfast", "lunch", "dinner", "snack")
    private val labels = listOf("bữa sáng", "bữa trưa", "bữa tối", "bữa phụ")
    private const val channelId = "healthmate_meal_reminders"
    fun day(): String = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
    fun allowed(context: Context): Boolean =
        context.getSystemService(NotificationManager::class.java).areNotificationsEnabled() &&
        (Build.VERSION.SDK_INT < 33 ||
            context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
            android.content.pm.PackageManager.PERMISSION_GRANTED)
    private fun pending(context: Context, meal: Int): PendingIntent =
        PendingIntent.getBroadcast(context, 4100 + meal,
            Intent(context, MealReminderReceiver::class.java).putExtra("meal", meal),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    fun cancel(context: Context, dismiss: Boolean = true) {
        val alarms = context.getSystemService(AlarmManager::class.java)
        val notifications = context.getSystemService(NotificationManager::class.java)
        for (i in meals.indices) {
            alarms.cancel(pending(context, i))
            if (dismiss) notifications.cancel(5100 + i)
        }
    }
    fun schedule(context: Context) {
        cancel(context, false)
        val storage = WellnessStorage(context)
        val uid = storage.activeUid() ?: return
        if (!allowed(context)) return
        val settings = storage.read(uid, "settings").optJSONArray("reminders") ?: return
        for (i in 0 until settings.length()) {
            val r = settings.getJSONObject(i)
            val index = meals.indexOf(r.optString("meal"))
            val minute = r.optInt("minute", -1)
            if (index < 0 || !r.optBoolean("enabled") || minute !in 0..1439) continue
            val next = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, minute / 60); set(Calendar.MINUTE, minute % 60)
                set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
                if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DAY_OF_YEAR, 1)
            }
            // Meal logging is not an alarm-clock use case. No exact-alarm access.
            context.getSystemService(AlarmManager::class.java).setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP, next.timeInMillis, pending(context, index))
        }
    }
    fun show(context: Context, index: Int, test: Boolean = false) {
        if (!allowed(context)) return
        val uid = WellnessStorage(context).activeUid() ?: return
        val manager = context.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(
            NotificationChannel(channelId, "Nhắc ghi bữa", NotificationManager.IMPORTANCE_DEFAULT))
        val launch = Intent(context, MainActivity::class.java)
            .setAction("healthmate.OPEN_JOURNAL").putExtra("reminderUid", uid)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val tap = PendingIntent.getActivity(context, 5200 + index, launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, channelId)
            else Notification.Builder(context)
        manager.notify(5100 + index, builder.setSmallIcon(R.drawable.ic_wellness_notification)
            .setContentTitle(if (test) "Thử nhắc ghi bữa" else "Đến giờ ghi " + labels[index])
            .setContentText("Mở HealthMate để ghi lại bữa ăn khi thuận tiện.")
            .setContentIntent(tap).setAutoCancel(true)
            .setVisibility(Notification.VISIBILITY_PRIVATE).build())
    }
}

class MealReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            val storage = WellnessStorage(context)
            val uid = storage.activeUid() ?: return
            val index = intent.getIntExtra("meal", -1)
            if (index !in MealReminders.meals.indices) return
            val settings = storage.read(uid, "settings")
            val entries = settings.optJSONArray("reminders") ?: JSONArray()
            val enabled = (0 until entries.length()).any {
                val r = entries.getJSONObject(it)
                r.optString("meal") == MealReminders.meals[index] && r.optBoolean("enabled")
            }
            val recorded = storage.read(uid, "recordedMeals")
            val logged = recorded.optString("day") == MealReminders.day() &&
                recorded.optJSONArray("meals")?.let { list ->
                    (0 until list.length()).any { list.optString(it) == MealReminders.meals[index] }
                } == true
            if (enabled && !logged) MealReminders.show(context, index)
            MealReminders.schedule(context)
        } catch (_: Exception) { /* Fail closed; never expose stored data in logs. */ }
    }
}

class MealReminderBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in listOf(Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_TIME_CHANGED,
                Intent.ACTION_TIMEZONE_CHANGED, Intent.ACTION_MY_PACKAGE_REPLACED)) return
        try { MealReminders.schedule(context) } catch (_: Exception) { }
        try { BedtimeReminders.schedule(context) } catch (_: Exception) { }
    }
}
