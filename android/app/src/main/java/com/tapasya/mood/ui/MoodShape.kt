package com.tapasya.mood.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * The mood vocabulary, matching the Apple app: 5 ▲ Elevated, 4 ● Good,
 * 3 ■ Steady, 2 ▼ Low, 1 ○ Flat. Drawn with Canvas so it scales cleanly.
 */
@Composable
fun MoodShape(value: Int, color: Color, size: Dp, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier.size(size)) {
        val w = this.size.width
        val h = this.size.height
        when (value) {
            5 -> {
                val p = Path().apply {
                    moveTo(w / 2f, 0f); lineTo(w, h); lineTo(0f, h); close()
                }
                drawPath(p, color)
            }
            4 -> drawCircle(color)
            3 -> drawRect(color)
            2 -> {
                val p = Path().apply {
                    moveTo(0f, 0f); lineTo(w, 0f); lineTo(w / 2f, h); close()
                }
                drawPath(p, color)
            }
            1 -> {
                val stroke = 2.dp.toPx()
                drawCircle(color, radius = (minOf(w, h) / 2f) - stroke / 2f, style = Stroke(width = stroke))
            }
        }
    }
}
