# RM2kx Android Builder on Docker

This project allows you to convert **RPG Maker 2000/2003** games for **Android** using **Docker** and **[EasyRPG](https://easyrpg.org/)**.

## Prerequisites

Before you start, make sure you have:

* **[Docker](https://docs.docker.com/get-docker/)** installed on your machine;
* your **RPG Maker 2000/2003 game** files (see the [`/rpgmaker2kx_game`](#volumes) volume below);
* an **icon** for your game as a square `.png` image (see the [`/icon.png`](#volumes) volume below);
* **(Optional, only to sign the build)** a **keystore file**. See [Creating a keystore](#creating-a-keystore).

## Install

To install this **Docker image**, you must have **Docker** installed on your machine and in the terminal execute the following command:

```sh
docker pull carlsonsantana/rm2kx-android-builder:latest
```

Or build it yourself executing the following command on the terminal:

```sh
docker build -t rm2kx-android-builder .
```

## Usage

Run the Docker image, mounting your game files and passing the environment variables that describe your game. The generated `.apk` and `.aab` files will be written to the directory you mount at `/output`.

### Unsigned build

```sh
docker run --rm \
  -v "$(pwd)/rpgmaker2kx_game:/rpgmaker2kx_game" \
  -v "$(pwd)/icon.png:/icon.png" \
  -v "$(pwd)/output:/output" \
  -e GAME_APK_NAME="com.mycompany.mygame" \
  -e GAME_NAME="My Game" \
  -e GAME_VERSION_CODE="100" \
  -e GAME_VERSION_NAME="1.0.0" \
  -e GAME_METADATA_SITE="https://example.com/" \
  -e GAME_OPTIMIZATION_MINIFY_IMAGES="true" \
  carlsonsantana/rm2kx-android-builder:latest
```

> **Note:** Android **cannot install an unsigned `.apk`** — every app must be signed before it can be installed on a device or uploaded to Google Play. Use the unsigned build only if you plan to sign the files yourself with your own tooling; otherwise use the [Signed build](#signed-build) below.

### Signed build

To sign the output, also mount your keystore file at `/game_certificate.key` and provide the keystore credentials, either through environment variables or through secret files. This example uses environment variables:

```sh
docker run --rm \
  -v "$(pwd)/rpgmaker2kx_game:/rpgmaker2kx_game" \
  -v "$(pwd)/icon.png:/icon.png" \
  -v "$(pwd)/output:/output" \
  -v "$(pwd)/game_certificate.key:/game_certificate.key" \
  -e GAME_APK_NAME="com.mycompany.mygame" \
  -e GAME_NAME="My Game" \
  -e GAME_VERSION_CODE="100" \
  -e GAME_VERSION_NAME="1.0.0" \
  -e GAME_METADATA_SITE="https://example.com/" \
  -e GAME_OPTIMIZATION_MINIFY_IMAGES="true" \
  -e GAME_KEYSTORE_PASSWORD="your_keystore_password" \
  -e GAME_KEYSTORE_KEY_ALIAS="your_key_alias" \
  -e GAME_KEYSTORE_KEY_PASSWORD="your_key_password" \
  carlsonsantana/rm2kx-android-builder:latest
```

To keep the keystore credentials out of the command line, mount them as plain text secret files instead of setting the `GAME_KEYSTORE_PASSWORD`, `GAME_KEYSTORE_KEY_ALIAS` and `GAME_KEYSTORE_KEY_PASSWORD` variables:

```sh
docker run --rm \
  -v "$(pwd)/rpgmaker2kx_game:/rpgmaker2kx_game" \
  -v "$(pwd)/icon.png:/icon.png" \
  -v "$(pwd)/output:/output" \
  -v "$(pwd)/game_certificate.key:/game_certificate.key" \
  -v "$(pwd)/keystore_password.txt:/run/secrets/game_keystore_password" \
  -v "$(pwd)/key_alias.txt:/run/secrets/game_keystore_key_alias" \
  -v "$(pwd)/key_password.txt:/run/secrets/game_keystore_key_password" \
  -e GAME_APK_NAME="com.mycompany.mygame" \
  -e GAME_NAME="My Game" \
  -e GAME_VERSION_CODE="100" \
  -e GAME_VERSION_NAME="1.0.0" \
  -e GAME_METADATA_SITE="https://example.com/" \
  -e GAME_OPTIMIZATION_MINIFY_IMAGES="true" \
  carlsonsantana/rm2kx-android-builder:latest
```

### Volumes

You must mount the following volumes when running the Docker image. These mounts provide the necessary input files and define the location for the final output.

* `/rpgmaker2kx_game` the folder containing your RPG Maker 2000/2003 game. This is the same folder you would run `RPG_RT.exe` from: it must contain the game files at its root, such as `RPG_RT.ldb` (database), `RPG_RT.lmt` (map tree), the `Map####.lmu` map files and the asset folders (`CharSet`, `ChipSet`, `Music`, `Sound`, `Picture`, etc.). You do not need to delete unused files like `RPG_RT.exe`, any documentation, any extras or `Thumbs.db`: the build automatically skips `.exe`, `.gitkeep` and `Thumbs.db` files, so they will not be packed into the game (removing them beforehand only makes the final download smaller);
* `/icon.png` the icon for your Android game. It must be a **square `.png` image**; for best results use at least **512x512** pixels, since it is downscaled for every screen density (the largest generated icon is 192x192);
* `/output` the directory where the generated `.apk` and `.aab` files will be created (see [Output files](#output-files));
* **(Optional)** `/game_certificate.key` the keystore file used to [sign the `.apk` file](https://developer.android.com/build/building-cmdline#sign_manually) and [sign the `.aab` file](https://learn.microsoft.com/en-us/power-apps/maker/common/wrap/code-sign-aab-file); if provided, you must also set the `GAME_KEYSTORE_PASSWORD`, `GAME_KEYSTORE_KEY_ALIAS` and `GAME_KEYSTORE_KEY_PASSWORD` environment variables;
* **(Optional)** `/run/secrets/game_keystore_password` a plain text file containing the keystore password, required when the `/game_certificate.key` volume is provided and the `GAME_KEYSTORE_PASSWORD` environment variable isn't set;
* **(Optional)** `/run/secrets/game_keystore_key_alias` a plain text file containing the key alias in the keystore, required when the `/game_certificate.key` volume is provided and the `GAME_KEYSTORE_KEY_ALIAS` environment variable isn't set;
* **(Optional)** `/run/secrets/game_keystore_key_password` a plain text file containing the key password in the keystore, required when the `/game_certificate.key` volume is provided and the `GAME_KEYSTORE_KEY_PASSWORD` environment variable isn't set.

### Environment Variables

* `GAME_APK_NAME` the [Application ID](https://developer.android.com/build/configure-app-module#set-application-id) (e.g., `com.mycompany.mygame`) of your Android game. Use lowercase letters, digits and underscores; it must have at least two segments separated by dots, and each segment must start with a letter;
* `GAME_NAME` the name displayed beneath the app icon on the device;
* `GAME_VERSION_CODE` the version code of your game (example: "100"); newer versions must have a greater value than older ones;
* `GAME_VERSION_NAME` the version name shown to the user, which may contain letters and dots (example: "1.0.0");
* `GAME_KEYSTORE_PASSWORD` the keystore password, required when the `/game_certificate.key` volume is provided and the `/run/secrets/game_keystore_password` volume isn't provided;
* `GAME_KEYSTORE_KEY_ALIAS` the key alias in the keystore, required when the `/game_certificate.key` volume is provided and the `/run/secrets/game_keystore_key_alias` volume isn't provided;
* `GAME_KEYSTORE_KEY_PASSWORD` the key password in the keystore, required when the `/game_certificate.key` volume is provided and the `/run/secrets/game_keystore_key_password` volume isn't provided;
* `GAME_METADATA_SITE` the website shown in the side menu (has a default value);
* `GAME_OPTIMIZATION_MINIFY_IMAGES` set to `true` to minify images without losing quality (defaults to `false`).

## Creating a keystore

Signing requires a keystore file. If you don't have one yet, you can create it with `keytool` (included with the Java JDK). This command creates a keystore named `game_certificate.key` with a key valid for about 27 years:

```sh
keytool -genkeypair -v \
  -keystore game_certificate.key \
  -alias game_cert \
  -keyalg RSA -keysize 4096 -validity 10000
```

`keytool` will prompt you for a keystore password (use it as `GAME_KEYSTORE_PASSWORD`), some identity details, and a key password (use it as `GAME_KEYSTORE_KEY_PASSWORD`). The value passed to `-alias` (here `game_cert`) is your `GAME_KEYSTORE_KEY_ALIAS`.

> **Keep this file and its passwords safe.** To publish updates on Google Play you must sign every version with the same keystore; if you lose it, you cannot update your app.

For more details, see the official [Android app signing guide](https://developer.android.com/studio/publish/app-signing).

## Output files

The build writes its results to the `/output` directory. The filenames depend on whether you provided a keystore:

* **Signed build** (keystore provided):
  * `rpgmaker2kx-signed.apk`
  * `rpgmaker2kx-signed.aab`
* **Unsigned build** (no keystore):
  * `rpgmaker2kx-aligned.apk`
  * `rpgmaker2kx-unsigned.aab`

### APK vs AAB

* An **APK** (`.apk`, Android Package) is the file you install directly on a device. Use it to test your game or to distribute it outside of Google Play (for example, by sideloading). To install a signed APK on a device with USB debugging enabled, run `adb install rpgmaker2kx-signed.apk`, or copy the file to the device and open it.
* An **AAB** (`.aab`, Android App Bundle) is the publishing format required by Google Play. You upload it to the Play Console and Google generates the optimized APKs delivered to each device. You cannot install an `.aab` directly on a device.

For a detailed comparison, see the official [Android App Bundle documentation](https://developer.android.com/guide/app-bundle).

## Troubleshooting

* **`ERROR: Partial keystore configuration detected.`** You mounted the `/game_certificate.key` volume but did not provide all three keystore credentials. When signing, you must provide the keystore password, key alias and key password — each either as an environment variable (`GAME_KEYSTORE_PASSWORD`, `GAME_KEYSTORE_KEY_ALIAS`, `GAME_KEYSTORE_KEY_PASSWORD`) or as the matching secret file under `/run/secrets/`.
* **The output icon looks blurry or pixelated.** Provide a larger, square `.png` icon (at least 512x512 pixels). Small icons are upscaled and lose quality.
* **The game doesn't start or assets are missing.** Make sure the `/rpgmaker2kx_game` volume points at the folder that contains `RPG_RT.ldb` and `RPG_RT.lmt` at its root, not a parent folder that contains the game in a subdirectory.
* **The build can't be installed on the device.** An unsigned APK cannot be installed; use the [Signed build](#signed-build).

## Android ports made with this

* [RM2K Standalone Game](https://play.google.com/store/apps/details?id=br.com.carlsonsantana.gamedev.rm2k_standalone_game) — a game of mine, published on Google Play.

## Source

The source code is available on [GitHub](https://github.com/carlsonsantana/easyrpg-android-builder-docker).
