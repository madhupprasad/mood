package com.tapasya.mood.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tapasya.mood.data.MoodLevel
import com.tapasya.mood.data.MoodStore
import com.tapasya.mood.ui.theme.Cream
import com.tapasya.mood.ui.theme.InkPrimary
import com.tapasya.mood.ui.theme.InkSecondary
import com.tapasya.mood.ui.theme.Line

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun WriteScreen(store: MoodStore, modifier: Modifier = Modifier) {
    var note by remember { mutableStateOf("") }
    var selectedMood by remember { mutableStateOf<Int?>(null) }
    var selectedEmotions by remember { mutableStateOf(setOf<String>()) }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(Cream)
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        Text(
            text = "how are you, right now?",
            fontSize = 24.sp,
            fontWeight = FontWeight.Medium,
            color = InkPrimary
        )

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            MoodLevel.all.forEach { level ->
                val active = selectedMood == level.value
                val color = Color(level.colorArgb)
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.clickable {
                        val newValue = if (active) null else level.value
                        // Feelings are scoped to a mood level, so changing or
                        // clearing the mood clears the chosen feelings.
                        if (newValue != selectedMood) selectedEmotions = emptySet()
                        selectedMood = newValue
                    }
                ) {
                    Box(
                        contentAlignment = Alignment.Center,
                        modifier = Modifier
                            .size(52.dp)
                            .clip(CircleShape)
                            .background(if (active) color.copy(alpha = 0.22f) else Line.copy(alpha = 0.4f))
                            .border(2.dp, if (active) color else Color.Transparent, CircleShape)
                    ) {
                        MoodShape(
                            value = level.value,
                            color = if (active) color else InkPrimary.copy(alpha = 0.7f),
                            size = 18.dp
                        )
                    }
                    Spacer(Modifier.height(6.dp))
                    Text(
                        text = level.title,
                        fontSize = 11.sp,
                        color = if (active) color else InkSecondary
                    )
                }
            }
        }

        // Optional feeling chips — appear once a mood is chosen, scoped to it.
        selectedMood?.let { mv ->
            val color = Color(MoodLevel.forValue(mv)?.colorArgb ?: 0xFF888888)
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = "FEELING",
                    fontSize = 10.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = InkSecondary
                )
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    MoodLevel.emotionsFor(mv).forEach { emotion ->
                        val on = emotion in selectedEmotions
                        Text(
                            text = emotion,
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Medium,
                            color = if (on) color else InkSecondary,
                            modifier = Modifier
                                .clip(CircleShape)
                                .background(if (on) color.copy(alpha = 0.15f) else Line.copy(alpha = 0.4f))
                                .border(
                                    1.dp,
                                    if (on) color.copy(alpha = 0.5f) else Color.Transparent,
                                    CircleShape
                                )
                                .clickable {
                                    selectedEmotions =
                                        if (on) selectedEmotions - emotion else selectedEmotions + emotion
                                }
                                .padding(horizontal = 12.dp, vertical = 6.dp)
                        )
                    }
                }
            }
        }

        OutlinedTextField(
            value = note,
            onValueChange = { note = it },
            placeholder = { Text("a few words, if you want…", color = InkSecondary) },
            modifier = Modifier.fillMaxWidth(),
            minLines = 2,
            shape = RoundedCornerShape(14.dp)
        )

        Text(
            text = "a note is optional — pick a mood and tap Log to keep just that",
            fontSize = 11.sp,
            color = InkSecondary
        )

        Button(
            onClick = {
                store.add(note.trim(), selectedMood, selectedEmotions.toList())
                note = ""
                selectedMood = null
                selectedEmotions = emptySet()
            },
            enabled = selectedMood != null,
            modifier = Modifier
                .fillMaxWidth()
                .height(50.dp),
            shape = RoundedCornerShape(14.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = InkPrimary,
                contentColor = Cream
            )
        ) {
            Text("Log")
        }
    }
}
