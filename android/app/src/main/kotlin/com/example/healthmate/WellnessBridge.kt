package com.example.healthmate

import android.Manifest
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorManager
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class WellnessBridge(private val activity: MainActivity, private val channel: MethodChannel) :
        MethodChannel.MethodCallHandler {
    private var permissionResult: MethodChannel.Result? = null
    private var tappedUid: String? = null
    private var sleepTappedUid: String? = null
    private val storage = WellnessStorage(activity)
    fun receiveIntent(intent: Intent?) {
        if (intent?.action == "healthmate.OPEN_JOURNAL") {
            tappedUid = intent.getStringExtra("reminderUid")
            channel.invokeMethod("notificationTap", null)
        }
        if (intent?.action == "healthmate.OPEN_SLEEP") {
            sleepTappedUid = intent.getStringExtra("sleepReminderUid")
            channel.invokeMethod("sleepNotificationTap", null)
        }
    }
    private fun owner(call: MethodCall): String {
        val uid = requireNotNull(call.argument<String>("uid"))
        require(uid.isNotBlank() && uid.length <= 128 && storage.activeUid() == uid)
        return uid
    }
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "setAccount" -> {
                    val uid = call.argument<String>("uid")
                    require(uid == null || (uid.isNotBlank() && uid.length <= 128))
                    if (storage.activeUid() != uid) {
                        MealReminders.cancel(activity)
                        BedtimeReminders.cancel(activity)
                        activity.stopService(Intent(activity, StepTrackingService::class.java))
                        storage.setActive(uid)
                    }
                    MealReminders.schedule(activity); BedtimeReminders.schedule(activity); result.success(null)
                }
                "takeReminderTap" -> {
                    val uid = owner(call)
                    val matches = tappedUid == uid; tappedUid = null; result.success(matches)
                }
                "takeSleepReminderTap" -> {
                    val uid=owner(call); val matches=sleepTappedUid==uid
                    sleepTappedUid=null; result.success(matches)
                }
                "readSleepReminder" -> result.success(storage.read(owner(call),"sleepReminder").toString())
                "saveSleepReminder" -> {
                    val uid=owner(call)
                    val value=JSONObject(requireNotNull(call.argument<String>("json")))
                    require(value.length()==2 && value.get("enabled") is Boolean && value.getInt("minute") in 0..1439)
                    if(value.getBoolean("enabled")) check(MealReminders.allowed(activity))
                    storage.write(uid,"sleepReminder",value)
                    BedtimeReminders.cancel(activity); BedtimeReminders.schedule(activity); result.success(null)
                }
                "testSleepReminder" -> { owner(call); check(MealReminders.allowed(activity)); BedtimeReminders.show(activity); result.success(null) }
                "readSettings" -> result.success(storage.read(owner(call), "settings").toString())
                "saveSettings" -> {
                    val uid = owner(call)
                    val value = JSONObject(requireNotNull(call.argument<String>("json")))
                    val list = value.getJSONArray("reminders")
                    require(list.length() == 4 && value.length() == 1)
                    val seen = mutableSetOf<String>()
                    for (i in 0 until list.length()) {
                        val item = list.getJSONObject(i)
                        val meal = item.getString("meal")
                        require(item.length() == 3 && meal in MealReminders.meals && seen.add(meal)
                            && item.getInt("minute") in 0..1439 && item.get("enabled") is Boolean)
                    }
                    if ((0 until list.length()).any { list.getJSONObject(it).getBoolean("enabled") }) {
                        check(MealReminders.allowed(activity))
                    }
                    storage.write(uid, "settings", value)
                    MealReminders.cancel(activity); MealReminders.schedule(activity); result.success(null)
                }
                "notificationsAllowed" -> result.success(MealReminders.allowed(activity))
                "activeNotifications" -> {
                    owner(call)
                    result.success(activity.getSystemService(NotificationManager::class.java)
                        .activeNotifications.map { it.id })
                }
                "requestNotifications" -> requestPermission(
                    if (Build.VERSION.SDK_INT >= 33) Manifest.permission.POST_NOTIFICATIONS else null, result)
                "requestMotion" -> requestPermission(
                    if (Build.VERSION.SDK_INT >= 29) Manifest.permission.ACTIVITY_RECOGNITION else null, result)
                "testReminder" -> { owner(call); check(MealReminders.allowed(activity))
                    MealReminders.show(activity, 0, true); result.success(null) }
                "recordMeals" -> {
                    val uid = owner(call)
                    val value = JSONObject(requireNotNull(call.argument<String>("json")))
                    require(value.optString("day").matches(Regex("[0-9]{4}-[0-9]{2}-[0-9]{2}")))
                    val meals = value.getJSONArray("meals"); require(meals.length() <= 4)
                    for (i in 0 until meals.length()) {
                        val index = MealReminders.meals.indexOf(meals.getString(i))
                        require(index >= 0)
                        activity.getSystemService(NotificationManager::class.java).cancel(5100 + index)
                    }
                    storage.write(uid, "recordedMeals", value); result.success(null)
                }
                "getSteps" -> {
                    val uid = owner(call)
                    val state = storage.read(uid, "steps")
                    state.put("running", StepTrackingService.runningUid == uid)
                    state.put("supported", activity.getSystemService(SensorManager::class.java)
                        .getDefaultSensor(Sensor.TYPE_STEP_COUNTER) != null)
                    result.success(state.toString())
                }
                "startSteps" -> {
                    val uid = owner(call)
                    check(MealReminders.allowed(activity))
                    check(activity.getSystemService(SensorManager::class.java)
                        .getDefaultSensor(Sensor.TYPE_STEP_COUNTER) != null)
                    if (Build.VERSION.SDK_INT >= 29) check(activity.checkSelfPermission(
                        Manifest.permission.ACTIVITY_RECOGNITION) == PackageManager.PERMISSION_GRANTED)
                    val intent = Intent(activity, StepTrackingService::class.java).putExtra("uid", uid)
                    if (Build.VERSION.SDK_INT >= 26) activity.startForegroundService(intent)
                    else activity.startService(intent)
                    result.success(null)
                }
                "stopSteps" -> { owner(call)
                    activity.stopService(Intent(activity, StepTrackingService::class.java)); result.success(null) }
                "clearAccount" -> {
                    val uid = owner(call)
                    MealReminders.cancel(activity)
                    BedtimeReminders.cancel(activity)
                    activity.stopService(Intent(activity, StepTrackingService::class.java))
                    for (scope in listOf("settings", "steps", "recordedMeals", "sleepReminder")) storage.clear(uid, scope)
                    storage.setActive(null); tappedUid = null; sleepTappedUid=null; result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (_: Exception) {
            result.error("wellness", "Không thể hoàn tất trên thiết bị. Kiểm tra quyền và thử lại.", null)
        }
    }
    private fun requestPermission(permission: String?, result: MethodChannel.Result) {
        if (permission == null || activity.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) {
            result.success(true); return
        }
        if (permissionResult != null) { result.error("busy", "Đang chờ cấp quyền.", null); return }
        permissionResult = result
        activity.requestPermissions(arrayOf(permission), 6274)
    }
    fun onPermissionResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != 6274) return false
        permissionResult?.success(grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)
        permissionResult = null; return true
    }
}
