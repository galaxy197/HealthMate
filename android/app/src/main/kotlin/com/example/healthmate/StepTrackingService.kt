package com.example.healthmate

import android.app.*
import android.content.*
import android.content.pm.ServiceInfo
import android.hardware.*
import android.os.Build
import android.os.IBinder
import org.json.JSONObject

class StepTrackingService : Service(), SensorEventListener {
    companion object { var runningUid: String? = null; private set }
    private var owner: String? = null
    private var lastCounter: Long? = null
    private var lastDay: String? = null
    private lateinit var sensors: SensorManager
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onCreate() { super.onCreate(); sensors = getSystemService(SensorManager::class.java) }
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            val uid = intent?.getStringExtra("uid")
            if (uid == null || WellnessStorage(this).activeUid() != uid) {
                stopSelf(); return START_NOT_STICKY
            }
            if (owner == uid) return START_NOT_STICKY
            val sensor = sensors.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
            if (sensor == null) { stopSelf(); return START_NOT_STICKY }
            val manager = getSystemService(NotificationManager::class.java)
            val channel = "healthmate_step_tracking"
            if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(
                NotificationChannel(channel, "Theo dõi bước chân", NotificationManager.IMPORTANCE_LOW))
            val tap = PendingIntent.getActivity(this, 6200,
                Intent(this, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, channel)
                else Notification.Builder(this)
            val notification = builder.setSmallIcon(R.drawable.ic_wellness_notification)
                .setContentTitle("HealthMate đang đếm bước")
                .setContentText("Mở ứng dụng để xem hoặc dừng theo dõi.")
                .setContentIntent(tap).setOngoing(true).setVisibility(Notification.VISIBILITY_PRIVATE).build()
            if (Build.VERSION.SDK_INT >= 34) startForeground(6100, notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH)
            else startForeground(6100, notification)
            sensors.unregisterListener(this)
            owner = uid; runningUid = uid; lastCounter = null; lastDay = null
            if (!sensors.registerListener(this, sensor, SensorManager.SENSOR_DELAY_NORMAL)) {
                stopSelf()
            }
        } catch (_: Exception) { stopSelf() }
        return START_NOT_STICKY
    }
    override fun onSensorChanged(event: SensorEvent) {
        try {
            val uid = owner ?: return
            val storage = WellnessStorage(this)
            if (storage.activeUid() != uid) { stopSelf(); return }
            val counter = event.values.firstOrNull()?.toLong() ?: return
            if (counter < 0) return
            val day = MealReminders.day()
            val state = storage.read(uid, "steps")
            val days = state.optJSONObject("days") ?: JSONObject()
            val now = System.currentTimeMillis()
            val record = days.optJSONObject(day) ?: JSONObject()
                .put("steps", 0).put("startedAt", now)
            val previous = lastCounter
            // A first sample/reboot/date change establishes a new baseline.
            // Never assign an unknown midnight gap to today's count.
            val delta = if (previous != null && lastDay == day && counter >= previous)
                counter - previous else 0L
            val count = (record.optLong("steps") + delta).coerceAtMost(150000L)
            record.put("steps", count).put("measuredAt", now)
                .put("timezoneOffsetMinutes", java.util.TimeZone.getDefault().getOffset(now) / 60000)
            days.put(day, record)
            val keep = days.keys().asSequence().toList().sortedDescending().take(31).toSet()
            days.keys().asSequence().toList().filter { it !in keep }.forEach { days.remove(it) }
            state.put("days", days); storage.write(uid, "steps", state)
            lastCounter = counter; lastDay = day
        } catch (_: Exception) { stopSelf() }
    }
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) { }
    override fun onDestroy() {
        sensors.unregisterListener(this)
        if (runningUid == owner) runningUid = null
        owner = null; super.onDestroy()
    }
}
