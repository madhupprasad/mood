package com.tapasya.mood.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.List
import androidx.compose.material.icons.automirrored.outlined.ShowChart
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.tapasya.mood.data.MoodStore

@Composable
fun MoodApp(store: MoodStore) {
    var tab by remember { mutableIntStateOf(0) }

    Scaffold(
        bottomBar = {
            NavigationBar {
                NavigationBarItem(
                    selected = tab == 0,
                    onClick = { tab = 0 },
                    icon = { Icon(Icons.Outlined.Edit, contentDescription = null) },
                    label = { Text("Write") }
                )
                NavigationBarItem(
                    selected = tab == 1,
                    onClick = { tab = 1 },
                    icon = { Icon(Icons.AutoMirrored.Outlined.List, contentDescription = null) },
                    label = { Text("Entries") }
                )
                NavigationBarItem(
                    selected = tab == 2,
                    onClick = { tab = 2 },
                    icon = { Icon(Icons.AutoMirrored.Outlined.ShowChart, contentDescription = null) },
                    label = { Text("Trends") }
                )
            }
        }
    ) { innerPadding ->
        when (tab) {
            0 -> WriteScreen(store, Modifier.padding(innerPadding))
            1 -> EntriesScreen(store, Modifier.padding(innerPadding))
            else -> TrendsScreen(store, Modifier.padding(innerPadding))
        }
    }
}
