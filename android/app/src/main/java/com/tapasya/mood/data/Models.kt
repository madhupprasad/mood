package com.tapasya.mood.data

import android.content.Context
import androidx.compose.runtime.mutableStateListOf
import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File
import java.util.UUID

/**
 * One journal entry. `mood` is the free-text note (may be empty — mood-only
 * entries are allowed); `moodValue` is the 1–5 rating. Shape mirrors the
 * Swift `MoodEntry` so the two apps stay conceptually in sync.
 */
@Serializable
data class MoodEntry(
    val id: String = UUID.randomUUID().toString(),
    val mood: String,
    val date: Long,
    val moodValue: Int? = null
)

/** The 1–5 mood scale, colours pulled from the Apple app's MoodLevel. */
data class MoodLevel(
    val value: Int,
    val title: String,
    val colorArgb: Long
) {
    companion object {
        val all = listOf(
            MoodLevel(5, "Elevated", 0xFF7FBF86),
            MoodLevel(4, "Good", 0xFFA8C779),
            MoodLevel(3, "Steady", 0xFFCDBF76),
            MoodLevel(2, "Low", 0xFFD49A68),
            MoodLevel(1, "Flat", 0xFFC87A72),
        )

        fun forValue(v: Int?): MoodLevel? = all.firstOrNull { it.value == v }
    }
}

/**
 * Plain-JSON store in the app's private filesDir, matching the Swift app's
 * "your data is just a readable file" philosophy.
 */
class MoodStore(context: Context) {
    private val file = File(context.filesDir, "mood-entries.json")
    private val json = Json { ignoreUnknownKeys = true; prettyPrint = true }

    val entries = mutableStateListOf<MoodEntry>()

    init {
        load()
    }

    fun add(mood: String, moodValue: Int?) {
        entries.add(0, MoodEntry(mood = mood, date = System.currentTimeMillis(), moodValue = moodValue))
        save()
    }

    fun clearAll() {
        entries.clear()
        save()
    }

    private fun load() {
        if (!file.exists()) return
        runCatching {
            val list = json.decodeFromString<List<MoodEntry>>(file.readText())
            entries.clear()
            entries.addAll(list)
        }
    }

    private fun save() {
        runCatching { file.writeText(json.encodeToString(entries.toList())) }
    }
}
