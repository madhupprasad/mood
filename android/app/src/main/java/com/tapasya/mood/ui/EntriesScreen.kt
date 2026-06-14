package com.tapasya.mood.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tapasya.mood.data.MoodEntry
import com.tapasya.mood.data.MoodLevel
import com.tapasya.mood.data.MoodStore
import com.tapasya.mood.ui.theme.Accent
import com.tapasya.mood.ui.theme.Cream
import com.tapasya.mood.ui.theme.InkPrimary
import com.tapasya.mood.ui.theme.InkSecondary
import com.tapasya.mood.ui.theme.Line
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun EntriesScreen(store: MoodStore, modifier: Modifier = Modifier) {
    val entries = store.entries

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(Cream)
    ) {
        Text(
            text = "ALL ENTRIES · ${entries.size} ${if (entries.size == 1) "entry" else "entries"}",
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold,
            color = InkSecondary,
            modifier = Modifier.padding(horizontal = 20.dp, vertical = 14.dp)
        )
        HorizontalDivider(color = Line)

        if (entries.isEmpty()) {
            Text(
                text = "No entries yet. Pick a mood on the Write tab to start.",
                fontSize = 13.sp,
                color = InkSecondary,
                modifier = Modifier.padding(20.dp)
            )
        } else {
            LazyColumn {
                items(entries) { entry ->
                    EntryRow(entry)
                    HorizontalDivider(color = Line.copy(alpha = 0.6f))
                }
            }
        }
    }
}

private val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun EntryRow(entry: MoodEntry) {
    val level = MoodLevel.forValue(entry.moodValue)
    val tint = level?.let { Color(it.colorArgb) } ?: Accent

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 12.dp)
    ) {
        Column(modifier = Modifier.width(56.dp)) {
            Text(
                text = timeFormat.format(Date(entry.date)),
                fontSize = 11.sp,
                fontFamily = FontFamily.Monospace,
                color = InkSecondary
            )
            Spacer(Modifier.height(6.dp))
            if (level != null) {
                MoodShape(
                    value = level.value,
                    color = Color(level.colorArgb),
                    size = 11.dp
                )
            }
        }

        Column(
            modifier = Modifier.padding(start = 4.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            if (entry.mood.isNotBlank()) {
                Text(
                    text = entry.mood,
                    fontSize = 13.sp,
                    color = InkPrimary
                )
            }
            if (entry.emotions.isNotEmpty()) {
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    entry.emotions.forEach { emotion ->
                        Text(
                            text = emotion,
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Medium,
                            color = tint,
                            modifier = Modifier
                                .clip(CircleShape)
                                .background(tint.copy(alpha = 0.12f))
                                .padding(horizontal = 7.dp, vertical = 2.dp)
                        )
                    }
                }
            }
        }
    }
}
