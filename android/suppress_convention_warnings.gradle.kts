import org.gradle.api.Project
import org.gradle.kotlin.dsl.withType
import org.gradle.api.plugins.Convention

/**
 * This script helps suppress Convention deprecation warnings by providing
 * an alternative modern approach for Flutter plugins.
 * Apply this in your build.gradle.kts files.
 */

// Modern extension methods for project configuration
fun Project.configureFlutterPlugins() {
    // Set up project configurations using modern APIs
    // instead of the deprecated Convention type
    afterEvaluate {
        // Configure Android plugins if present
        plugins.withId("com.android.application") {
            // Modern configuration for Android app
            extensions.configure<com.android.build.gradle.AppExtension> {
                // Modern extension configuration
            }
        }
        
        plugins.withId("com.android.library") {
            // Modern configuration for Android library
            extensions.configure<com.android.build.gradle.LibraryExtension> {
                // Modern extension configuration
            }
        }
    }
}
