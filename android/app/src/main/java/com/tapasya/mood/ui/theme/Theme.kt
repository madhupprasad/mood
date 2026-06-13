package com.tapasya.mood.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// Cream palette, matching the Apple app's default theme.
val Cream = Color(0xFFF7F5ED)
val CreamCard = Color(0xFFFCFAF2)
val InkPrimary = Color(0xFF2E2B29)
val InkSecondary = Color(0xFF8C877D)
val Line = Color(0xFFDED9CF)
val Accent = Color(0xFF7AA872)

private val LightColors = lightColorScheme(
    primary = InkPrimary,
    onPrimary = Cream,
    background = Cream,
    onBackground = InkPrimary,
    surface = CreamCard,
    onSurface = InkPrimary,
    surfaceVariant = Cream,
    onSurfaceVariant = InkSecondary,
)

@Composable
fun MoodTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = LightColors,
        content = content
    )
}
