package com.tapasya.mood.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tapasya.mood.data.MoodLevel
import com.tapasya.mood.data.MoodStore
import com.tapasya.mood.ui.theme.Accent
import com.tapasya.mood.ui.theme.Cream
import com.tapasya.mood.ui.theme.CreamCard
import com.tapasya.mood.ui.theme.InkPrimary
import com.tapasya.mood.ui.theme.InkSecondary
import com.tapasya.mood.ui.theme.Line
import java.util.Calendar
import kotlin.math.roundToInt

@Composable
fun TrendsScreen(store: MoodStore, modifier: Modifier = Modifier) {
    val entries = store.entries
    val rated = entries.filter { it.moodValue != null }.sortedBy { it.date }

    val average = rated.mapNotNull { it.moodValue }.average() // NaN when empty
    val avgLevel = if (average.isNaN()) null else MoodLevel.forValue(average.roundToInt())
    val streak = currentStreak(entries.map { it.date })

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(Cream)
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = "TRENDS · ${entries.size} ${if (entries.size == 1) "entry" else "entries"}",
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold,
            color = InkSecondary
        )

        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            StatCard(
                label = "AVERAGE MOOD",
                modifier = Modifier.weight(1f)
            ) {
                if (avgLevel != null) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        MoodShape(avgLevel.value, Color(avgLevel.colorArgb), 16.dp)
                        Spacer(Modifier.size(8.dp))
                        Text(avgLevel.title, fontSize = 18.sp, fontWeight = FontWeight.Medium, color = InkPrimary)
                    }
                } else {
                    Text("—", fontSize = 18.sp, color = InkSecondary)
                }
            }
            StatCard(
                label = "CURRENT STREAK",
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = "$streak ${if (streak == 1) "day" else "days"}",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Medium,
                    color = InkPrimary
                )
            }
        }

        Text("MOOD OVER TIME", fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = InkSecondary)
        MoodLineChart(
            values = rated.mapNotNull { it.moodValue },
            modifier = Modifier
                .fillMaxWidth()
                .height(180.dp)
                .clip(RoundedCornerShape(14.dp))
                .background(CreamCard)
                .padding(16.dp)
        )
    }
}

@Composable
private fun StatCard(label: String, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(14.dp))
            .background(CreamCard)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Text(label, fontSize = 10.sp, fontWeight = FontWeight.SemiBold, color = InkSecondary)
        content()
    }
}

@Composable
private fun MoodLineChart(values: List<Int>, modifier: Modifier = Modifier) {
    if (values.size < 2) {
        Column(modifier, verticalArrangement = Arrangement.Center) {
            Text(
                text = "Log a few moods to see the line take shape.",
                fontSize = 12.sp,
                color = InkSecondary
            )
        }
        return
    }
    Canvas(modifier) {
        val w = size.width
        val h = size.height
        // Mood values run 1..5; map to y with 5 at the top.
        fun yFor(v: Int) = h - ((v - 1).toFloat() / 4f) * h
        val stepX = if (values.size == 1) 0f else w / (values.size - 1).toFloat()

        // baseline grid
        drawLine(Line, Offset(0f, h), Offset(w, h), strokeWidth = 1f)

        val path = Path()
        values.forEachIndexed { i, v ->
            val x = i * stepX
            val y = yFor(v)
            if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
        }
        drawPath(path, Accent, style = Stroke(width = 3f))

        values.forEachIndexed { i, v ->
            drawCircle(Accent, radius = 4f, center = Offset(i * stepX, yFor(v)))
        }
    }
}

/** Consecutive days (ending today) that have at least one entry. */
private fun currentStreak(dates: List<Long>): Int {
    if (dates.isEmpty()) return 0
    val daySet = dates.map { dayNumber(it) }.toSet()
    var streak = 0
    var day = dayNumber(System.currentTimeMillis())
    while (daySet.contains(day)) {
        streak++
        day--
    }
    return streak
}

private fun dayNumber(millis: Long): Long {
    val cal = Calendar.getInstance()
    cal.timeInMillis = millis
    cal.set(Calendar.HOUR_OF_DAY, 0)
    cal.set(Calendar.MINUTE, 0)
    cal.set(Calendar.SECOND, 0)
    cal.set(Calendar.MILLISECOND, 0)
    return cal.timeInMillis / 86_400_000L
}
