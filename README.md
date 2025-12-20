# RM2kx Android Builder on Docker

This project allows you to convert **RPG Maker 2000/2003** games for **Android** using **Docker** and **[EasyRPG](https://easyrpg.org/)**.

## Install

To install this **Docker image**, you must have **Docker** installed on your machine and in the terminal execute the following command:

```sh
docker pull carlsonsantana/rm2kx-android-builder:latest
```

Or build it yourself executing the following command on the terminal:

```sh
docker build -t rm2kx-android-builder .
```

### Volumes

You must mount the following volumes when running the Docker image. These mounts provide the necessary input files and define the location for the final output.

* `/rpgmaker2kx_game` your RPG Maker 2000/2003 game (remove the files that Android will not use like `RPG_RT.exe`, any documentation, any extra and of course `Thumbs.db` files);
* `/icon.png` the icon for your Android game;
* `/output` the directory where the aligned or signed `.apk` and `.aab` will be created;
* **(Optional)** `/game_certificate.key` the keystore file used to [sign the `.apk` file](https://developer.android.com/build/building-cmdline#sign_manually) and [sign the `.aab` file](https://learn.microsoft.com/en-us/power-apps/maker/common/wrap/code-sign-aab-file), if passed you must pass the following environment variables `GAME_KEYSTORE_PASSWORD`, `GAME_KEYSTORE_KEY_ALIAS` and `GAME_KEYSTORE_KEY_PASSWORD`;

### Environment Variables

* `GAME_APK_NAME` the [Application ID](https://developer.android.com/build/configure-app-module#set-application-id) (e.g., `com.mycompany.mygame`) of your Android game;
* `GAME_NAME` the name displayed beneath the app icon on the device;
* `GAME_VERSION_CODE` the version number code of your game (example: "100"), new versions must have a greater value than old ones;
* `GAME_VERSION_NAME` the version showed to the user that allows use letters and dots (example: "1.0.0");
* `GAME_KEYSTORE_PASSWORD` the keystore password, required when `/game_certificate.key` volume is filled;
* `GAME_KEYSTORE_KEY_ALIAS` the key alias in keystore, required when `/game_certificate.key` volume is filled;
* `GAME_KEYSTORE_KEY_PASSWORD` the key password in keystore, required when `/game_certificate.key` volume is filled;
* `GAME_METADATA_SITE` the website showed on the side menu.
