package com.tapasya.mood

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import com.tapasya.mood.data.MoodStore
import com.tapasya.mood.ui.MoodApp
import com.tapasya.mood.ui.theme.MoodTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val store = MoodStore(applicationContext)
        setContent {
            MoodTheme {
                MoodApp(store = store)
            }
        }
    }
}
