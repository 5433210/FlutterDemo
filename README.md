# Flutter Demo Project

This is a basic Flutter demo project.

## Getting Started

To run this project, follow these steps:

1.  **Install Flutter:** Make sure you have Flutter installed and configured on your system. You can download it from [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install).
2.  **Navigate to the project directory:** Open your terminal or command prompt and navigate to the root directory of this project.
3.  **Run the app:** Execute the command `flutter run`. This will build the app and install it on a connected device (either a physical device or an emulator).

    *   If you have multiple devices connected, you may need to specify the target device using the `-d` flag (e.g., `flutter run -d chrome` to run in Chrome).

## Finding the Executable (Desktop Builds)

After building the desktop version of your app (e.g., using `flutter build windows`, `flutter build macos`, or `flutter build linux`), the executable can be found in the `build` directory:

*   **Windows:** `build\windows\runner\Release` (or `Debug`)
*   **macOS:** `build\macos\Build\Products\Release` (or `Debug`)
*   **Linux:** `build\linux\x64\release\bundle` (or `debug\bundle`)

## Generating a Windows Installer

To create a distributable installer for Windows, follow these steps:

1.  **Add `msix` to `pubspec.yaml`:**

    ```yaml
    dev_dependencies:
      msix: ^3.6.4
    ```

    Run `flutter pub get` to install the dependency.
2.  **Configure `msix_config.json`:**

    Create a file named `msix_config.json` in the root of your Flutter project with the following content (adjust the values as needed):

    ```json
    {
      "identityName": "Your.Company.DemoApp",
      "publisher": "CN=Your Company Name",
      "displayName": "Demo App",
      "publisherDisplayName": "Your Company",
      "description": "A simple Flutter demo application.",
      "msixVersion": "1.0.0.0",
      "logoPath": "assets/app_icon.png",
      "outputName": "DemoAppInstaller",
      "capabilities": "internetClient"
    }
    ```

3.  **Create or Update the `assets` Folder:**

    Create an `assets` folder in the root of your project and place your application icon (`app_icon.png`) in this folder. The icon should be a square PNG image.
4.  **Build the MSIX Package:**

    Run the following command in your terminal:

    ```
    flutter pub run msix:create
    ```

5.  **Locate the Installer:**

    The generated MSIX installer will be located in the `build\windows\msix` directory.
6.  **Distribute the Installer:**

    You can now distribute the generated MSIX installer to other Windows machines.

A few resources to get you started if this is your first Flutter project:

-   [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
-   [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
