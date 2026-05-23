package ai.purepath

import android.content.res.Configuration
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        try {
            normalizeDensity()
            adjustForStandardScreen()
            adjustForZoomLevels()
        } catch (e: Exception) {
            Log.d("MainActivity", "Error in main activity: $e")
        }
    }

    override fun onResume() {
        super.onResume()
        // Normalize density based on detected zoom levels
        normalizeDensity()
        // Or adjust to standard screen sizes
        adjustForStandardScreen()

        adjustForZoomLevels()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        // Normalize density based on detected zoom levels
        normalizeDensity()
        // Or adjust to standard screen sizes
        adjustForStandardScreen()

        adjustForZoomLevels()
    }

    private fun normalizeDensity() {
        val displayMetrics = resources.displayMetrics
        val defaultDensity = getZoomDensity()
        val scaleFactor = displayMetrics.densityDpi / defaultDensity
        Log.d("MainActivity", "Screen scaling factor: $scaleFactor")
        if (scaleFactor != 1.0f) {
            displayMetrics.density = 1.0f / scaleFactor
            displayMetrics.scaledDensity = 1.0f / scaleFactor
            displayMetrics.densityDpi = (defaultDensity * scaleFactor).toInt()
        }
    }

    private fun adjustForStandardScreen() {
        val displayMetrics = resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels / displayMetrics.density
        val standardDensity =
                when {
                    screenWidth < 360 -> 160.0f // Small screens
                    screenWidth < 720 -> 240.0f // Normal screens
                    screenWidth < 1080 -> 320.0f // Large screens
                    else -> 480.0f // Extra-large screens
                }
        displayMetrics.density = standardDensity / getZoomDensity()
        displayMetrics.scaledDensity = standardDensity / getZoomDensity()
        displayMetrics.densityDpi = (standardDensity).toInt()
        Log.d("MainActivity", "Adjusted density to standard: $standardDensity")
    }

    private fun adjustForZoomLevels() {
        val displayMetrics = resources.displayMetrics

        val zoomThreshold = 1.1f // 25% zoom threshold
        val scaleFactor = displayMetrics.scaledDensity / displayMetrics.density

        if (scaleFactor > zoomThreshold) {
            Log.d("MainActivity", "Zoom detected: Scaling down layout")
            displayMetrics.density /= scaleFactor
            displayMetrics.scaledDensity /= scaleFactor
        } else if (scaleFactor < 1.0f / zoomThreshold) {
            Log.d("MainActivity", "Zoom out detected: Scaling up layout")
            displayMetrics.density *= scaleFactor
            displayMetrics.scaledDensity *= scaleFactor
        }
    }

    private fun getZoomDensity(): Float {
        val displayMetrics = resources.displayMetrics
        val screenWidthDp = displayMetrics.widthPixels
        Log.d(
                "TAG",
                "Screen size: $screenWidthDp ",
        )
        return when {
            screenWidthDp <= 720 -> 245.0f // Small screens
            screenWidthDp <= 1080 -> 185.0f // Normal screens
            screenWidthDp <= 1440 -> 150.0f // Large screens
            else -> 140.0f // Extra-large screens
        }
    }
}
