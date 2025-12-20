#!/bin/sh

set -e

# Remove previous files build
rm -f /tmp/rpgmaker2kx-unsigned.apk /tmp/rpgmaker2kx-aligned.apk /tmp/rpgmaker2kx-unsigned.aab
rm -fr /tmp/apk /tmp/res.zip /tmp/_base.zip /tmp/base /tmp/base.zip /tmp/easyrpg-android-res-aab
rm -f /output/rpgmaker2kx-aligned.apk /output/rpgmaker2kx-signed.apk /output/rpgmaker2kx-unsigned.aab /output/rpgmaker2kx-signed.aab

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

resize_icon() {
  magick /icon.png -resize $1 $2 && oxipng -o 6 --strip safe $2
}

get_sigalg() {
  RAW_INFO=$(keytool -list -v -keystore /game_certificate.key -alias "$GAME_KEYSTORE_KEY_ALIAS" -storepass "$GAME_KEYSTORE_PASSWORD" | grep "Signature algorithm name")

  case "$RAW_INFO" in
    *RSA*) echo "SHA256withRSA" ;;
    *ECDSA*) echo "SHA256withECDSA" ;;
    *EC*) echo "SHA256withECDSA" ;;
    *DSA*) echo "SHA256withDSA" ;;
    *) echo "Unknown or unsupported key type."; exit 1 ;;
  esac
}

# Convert icons
resize_icon "36x36" "/easyrpg-android/res/drawable-ldpi/ic_launcher.png"
resize_icon "48x48" "/easyrpg-android/res/drawable-mdpi/ic_launcher.png"
resize_icon "72x72" "/easyrpg-android/res/drawable-hdpi/ic_launcher.png"
resize_icon "96x96" "/easyrpg-android/res/drawable-xhdpi/ic_launcher.png"
resize_icon "144x144" "/easyrpg-android/res/drawable-xxhdpi/ic_launcher.png"
resize_icon "192x192" "/easyrpg-android/res/drawable-xxxhdpi/ic_launcher.png"

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

# Build the Android App Bundle (.aab)
cp -r /easyrpg-android/res/ /tmp/easyrpg-android-res-aab
cd /tmp/easyrpg-android-res-aab
find . -type f -name '$*' | while read -r file; do
    # Get the directory name and the base filename
    dir=$(dirname "$file")
    base=$(basename "$file")

    # Remove the $ (first char) and add the prefix
    new_name="rm2kx_${base#\$}"

    # Perform the move
    mv -v "$file" "$dir/$new_name"
    echo "s/"${base%.*}"/"${new_name%.*}"/g"

    find . -type f -name '*.xml' -exec sed -i "s/"${base%.*}"/"${new_name%.*}"/g" {} +
done
cd /
unzip /tmp/rpgmaker2kx-unsigned.apk -d /tmp/apk
aapt2 compile --dir /tmp/easyrpg-android-res-aab -o /tmp/res.zip
aapt2 link --proto-format -o /tmp/_base.zip -I /opt/android.jar --manifest /easyrpg-android/AndroidManifest.xml --min-sdk-version 21 --target-sdk-version 36 --version-code "$GAME_VERSION_CODE" --version-name "$GAME_VERSION_NAME" -R /tmp/res.zip --auto-add-overlay
unzip /tmp/_base.zip -d /tmp/base
cp -r /easyrpg-android/assets/ /easyrpg-android/lib/ /easyrpg-android/unknown/ /tmp/base
mkdir /tmp/base/manifest /tmp/base/dex
mv /tmp/base/AndroidManifest.xml /tmp/base/manifest/AndroidManifest.xml
mv /tmp/base/unknown /tmp/base/root
mv /tmp/apk/*.dex /tmp/base/dex
cd /tmp/base
jar cMf /tmp/base.zip manifest dex res root lib assets resources.pb
cd /
java -jar /opt/bundletool.jar build-bundle --modules=/tmp/base.zip --output=/tmp/rpgmaker2kx-unsigned.aab
chmod 644 /tmp/rpgmaker2kx-unsigned.aab

# Sign the APK and AAB
if [ -f "/game_certificate.key" ]; then
  java -jar /opt/signmyapp.jar -ks /game_certificate.key -ks-pass "$GAME_KEYSTORE_PASSWORD" -ks-key-alias "$GAME_KEYSTORE_KEY_ALIAS" -key-pass "$GAME_KEYSTORE_KEY_PASSWORD" -in /tmp/rpgmaker2kx-aligned.apk -out /output/rpgmaker2kx-signed.apk

  SIGALG=$(get_sigalg)
  jarsigner -verbose -sigalg $SIGALG -digestalg SHA-256 -signedjar /output/rpgmaker2kx-signed.aab -keystore /game_certificate.key -storepass "$GAME_KEYSTORE_PASSWORD" /tmp/rpgmaker2kx-unsigned.aab "$GAME_KEYSTORE_KEY_ALIAS"

  rm /tmp/rpgmaker2kx-aligned.apk /tmp/rpgmaker2kx-unsigned.aab
else
  mv /tmp/rpgmaker2kx-aligned.apk /output/rpgmaker2kx-aligned.apk
  mv /tmp/rpgmaker2kx-unsigned.aab /output/rpgmaker2kx-unsigned.aab
fi

rm /tmp/rpgmaker2kx-unsigned.apk
rm -fr /tmp/apk /tmp/res.zip /tmp/_base.zip /tmp/base /tmp/base.zip /tmp/easyrpg-android-res-aab
