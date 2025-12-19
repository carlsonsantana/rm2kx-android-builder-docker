#!/bin/sh

set -e

# Remove previous apk build
rm -f /tmp/rpgmaker2kx-unsigned.apk /tmp/rpgmaker2kx-aligned.apk /output/rpgmaker2kx-aligned.apk /output/rpgmaker2kx-signed.apk

if [ -f "/game_certificate.key" ]; then
  if [ -z "$GAME_KEYSTORE_PASSWORD" ] || [ -z "$GAME_KEYSTORE_KEY_ALIAS" ] || [ -z "$GAME_KEYSTORE_KEY_PASSWORD" ]; then
    echo "ERROR: Partial keystore configuration detected."
    echo "You must provide ALL THREE variables, when pass '/game_certificate.key' VOLUME."
    echo "Missing values for: "
    [ -z "$GAME_KEYSTORE_PASSWORD" ] && echo "- GAME_KEYSTORE_PASSWORD"
    [ -z "$GAME_KEYSTORE_KEY_ALIAS" ] && echo "- GAME_KEYSTORE_KEY_ALIAS"
    [ -z "$GAME_KEYSTORE_KEY_PASSWORD" ] && echo "- GAME_KEYSTORE_KEY_PASSWORD"
    exit 1
  fi
fi

# Convert icons
magick /icon.png -resize 36x36 /easyrpg-android/res/drawable-ldpi/ic_launcher.png
magick /icon.png -resize 48x48 /easyrpg-android/res/drawable-mdpi/ic_launcher.png
magick /icon.png -resize 72x72 /easyrpg-android/res/drawable-hdpi/ic_launcher.png
magick /icon.png -resize 96x96 /easyrpg-android/res/drawable-xhdpi/ic_launcher.png
magick /icon.png -resize 144x144 /easyrpg-android/res/drawable-xxhdpi/ic_launcher.png
magick /icon.png -resize 192x192 /easyrpg-android/res/drawable-xxxhdpi/ic_launcher.png

# Rename APK name and application ID
sed -i "s|EasyRPG Player|$GAME_NAME|g" /easyrpg-android/res/values/strings.xml
sed -i "s|\"aaaaa\.bbbbb\.ccccc\"|\"$GAME_APK_NAME\"|g" /easyrpg-android/AndroidManifest.xml
sed -i "s|https://easyrpg\.org/|$GAME_METADATA_SITE|g" /easyrpg-android/res/layout/browser_nav_header.xml
printf "version: 2.12.1\napkFileName: app-release.apk\nusesFramework:\n  ids:\n  - 1\nsdkInfo:\n  minSdkVersion: 21\n  targetSdkVersion: 36\npackageInfo:\n  forcedPackageId: 127\n  renameManifestPackage: "$GAME_APK_NAME"\nversionInfo:\n  versionCode: "$GAME_VERSION_CODE"\n  versionName: "$GAME_VERSION_NAME"\ndoNotCompress:\n- arsc\n- png\n- META-INF/androidx.activity_activity.version\n- META-INF/androidx.annotation_annotation-experimental.version\n- META-INF/androidx.appcompat_appcompat-resources.version\n- META-INF/androidx.appcompat_appcompat.version\n- META-INF/androidx.cardview_cardview.version\n- META-INF/androidx.constraintlayout_constraintlayout.version\n- META-INF/androidx.coordinatorlayout_coordinatorlayout.version\n- META-INF/androidx.core_core-ktx.version\n- META-INF/androidx.core_core-viewtree.version\n- META-INF/androidx.core_core.version\n- META-INF/androidx.cursoradapter_cursoradapter.version\n- META-INF/androidx.customview_customview-poolingcontainer.version\n- META-INF/androidx.customview_customview.version\n- META-INF/androidx.documentfile_documentfile.version\n- META-INF/androidx.drawerlayout_drawerlayout.version\n- META-INF/androidx.dynamicanimation_dynamicanimation.version\n- META-INF/androidx.emoji2_emoji2-views-helper.version\n- META-INF/androidx.emoji2_emoji2.version\n- META-INF/androidx.fragment_fragment.version\n- META-INF/androidx.interpolator_interpolator.version\n- META-INF/androidx.legacy_legacy-support-core-utils.version\n- META-INF/androidx.loader_loader.version\n- META-INF/androidx.localbroadcastmanager_localbroadcastmanager.version\n- META-INF/androidx.print_print.version\n- META-INF/androidx.profileinstaller_profileinstaller.version\n- META-INF/androidx.recyclerview_recyclerview.version\n- META-INF/androidx.savedstate_savedstate.version\n- META-INF/androidx.startup_startup-runtime.version\n- META-INF/androidx.tracing_tracing.version\n- META-INF/androidx.transition_transition.version\n- META-INF/androidx.vectordrawable_vectordrawable-animated.version\n- META-INF/androidx.vectordrawable_vectordrawable.version\n- META-INF/androidx.versionedparcelable_versionedparcelable.version\n- META-INF/androidx.viewpager2_viewpager2.version\n- META-INF/androidx.viewpager_viewpager.version\n- META-INF/com.google.android.material_material.version\n- META-INF/kotlinx_coroutines_android.version\n- META-INF/kotlinx_coroutines_core.version\n- assets/dexopt/baseline.prof\n- assets/dexopt/baseline.profm" > /easyrpg-android/apktool.yml

# Create game.zip asset
cd /rpgmaker2kx_game
zip -Z deflate -vr /easyrpg-android/assets/game.zip *

# Build an aligned version of the Android app
java -jar /apktool/apktool.jar b /easyrpg-android -o /tmp/rpgmaker2kx-unsigned.apk
zipalign -v -p 4 /tmp/rpgmaker2kx-unsigned.apk /tmp/rpgmaker2kx-aligned.apk

if [ -f "/game_certificate.key" ]; then
  java -jar /opt/signmyapp.jar -ks /game_certificate.key -ks-pass "$GAME_KEYSTORE_PASSWORD" -ks-key-alias "$GAME_KEYSTORE_KEY_ALIAS" -key-pass "$GAME_KEYSTORE_KEY_PASSWORD" -in /tmp/rpgmaker2kx-aligned.apk -out /output/rpgmaker2kx-signed.apk
  rm /tmp/rpgmaker2kx-aligned.apk
else
  mv /tmp/rpgmaker2kx-aligned.apk /output/rpgmaker2kx-aligned.apk
fi

rm /tmp/rpgmaker2kx-unsigned.apk
