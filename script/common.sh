#!/bin/sh

TEMP_UNSIGNED_APK_FILE="/tmp/$APP_BASENAME-unsigned.apk"
TEMP_ALIGNED_APK_FILE="/tmp/$APP_BASENAME-aligned.apk"
TEMP_UNSIGNED_AAB_FILE="/tmp/$APP_BASENAME-unsigned.aab"
OUTPUT_ALIGNED_APK_FILE="/output/$APP_BASENAME-aligned.apk"
OUTPUT_SIGNED_APK_FILE="/output/$APP_BASENAME-signed.apk"
OUTPUT_UNSIGNED_AAB_FILE="/output/$APP_BASENAME-unsigned.aab"
OUTPUT_SIGNED_AAB_FILE="/output/$APP_BASENAME-signed.aab"
TEMP_RESOURCES_AAB_PATH="/tmp/$APKTOOL_DECODED_PATH-res-aab"

init_keystore_variables() {
  if [ -f "/run/secrets/game_keystore_password" ]; then
    export GAME_KEYSTORE_PASSWORD=$(cat /run/secrets/game_keystore_password)
  fi
  if [ -f "/run/secrets/game_keystore_key_alias" ]; then
    export GAME_KEYSTORE_KEY_ALIAS=$(cat /run/secrets/game_keystore_key_alias)
  fi
  if [ -f "/run/secrets/game_keystore_key_password" ]; then
    export GAME_KEYSTORE_KEY_PASSWORD=$(cat /run/secrets/game_keystore_key_password)
  fi
}

remove_previous_build_files() {
  rm -f "$TEMP_UNSIGNED_APK_FILE" "$TEMP_ALIGNED_APK_FILE" "$TEMP_UNSIGNED_AAB_FILE"
  rm -fr /tmp/apk /tmp/res.zip /tmp/_base.zip /tmp/base /tmp/base.zip "$TEMP_RESOURCES_AAB_PATH"
  rm -f "$OUTPUT_ALIGNED_APK_FILE" "$OUTPUT_SIGNED_APK_FILE" "$OUTPUT_UNSIGNED_AAB_FILE" "$OUTPUT_SIGNED_AAB_FILE"
}

validate_secrets_filled() {
  if [ -f "/game_certificate.key" ]; then
    if [ -z "$GAME_KEYSTORE_PASSWORD" ] || [ -z "$GAME_KEYSTORE_KEY_ALIAS" ] || [ -z "$GAME_KEYSTORE_KEY_PASSWORD" ]; then
      echo "ERROR: Partial keystore configuration detected."
      echo "You must provide ALL THREE variables, when pass '/game_certificate.key' VOLUME."
      echo "Missing secrets: "
      [ -z "$GAME_KEYSTORE_PASSWORD" ] && echo "- /run/secrets/game_keystore_password"
      [ -z "$GAME_KEYSTORE_KEY_ALIAS" ] && echo "- /run/secrets/game_keystore_key_alias"
      [ -z "$GAME_KEYSTORE_KEY_PASSWORD" ] && echo "- /run/secrets/game_keystore_key_password"
      exit 1
    fi
  fi
}

resize_icon() {
  magick /icon.png -resize $1 $2 && oxipng -o 6 --strip safe $2
}

replace_icons() {
  resize_icon "36x36" "$APKTOOL_DECODED_PATH/res/drawable-ldpi/$ICON_BASENAME.png"
  resize_icon "48x48" "$APKTOOL_DECODED_PATH/res/drawable-mdpi/$ICON_BASENAME.png"
  resize_icon "72x72" "$APKTOOL_DECODED_PATH/res/drawable-hdpi/$ICON_BASENAME.png"
  resize_icon "96x96" "$APKTOOL_DECODED_PATH/res/drawable-xhdpi/$ICON_BASENAME.png"
  resize_icon "144x144" "$APKTOOL_DECODED_PATH/res/drawable-xxhdpi/$ICON_BASENAME.png"
  resize_icon "192x192" "$APKTOOL_DECODED_PATH/res/drawable-xxxhdpi/$ICON_BASENAME.png"
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

build_aligned_apk() {
  java -jar /apktool/apktool.jar b $APKTOOL_DECODED_PATH -o $TEMP_UNSIGNED_APK_FILE
  zipalign -v -p 4 $TEMP_UNSIGNED_APK_FILE $TEMP_ALIGNED_APK_FILE
}

build_unsigned_aab() {
  cp -r $APKTOOL_DECODED_PATH/res/ $TEMP_RESOURCES_AAB_PATH
  cd $TEMP_RESOURCES_AAB_PATH
  find . -type f -name '$*' | while read -r file; do
    # Get the directory name and the base filename
    dir=$(dirname "$file")
    base=$(basename "$file")

    # Remove the $ (first char) and add the prefix
    new_name="$RESOURCE_PREFIX""_${base#\$}"

    # Perform the move
    mv -v "$file" "$dir/$new_name"

    find . -type f -name '*.xml' -exec sed -i "s/"${base%.*}"/"${new_name%.*}"/g" {} +
  done
  cd /
  unzip $TEMP_UNSIGNED_APK_FILE -d /tmp/apk
  aapt2 compile --dir $TEMP_RESOURCES_AAB_PATH -o /tmp/res.zip
  aapt2 link --proto-format -o /tmp/_base.zip -I /opt/android.jar --manifest $APKTOOL_DECODED_PATH/AndroidManifest.xml --min-sdk-version 21 --target-sdk-version 36 --version-code "$GAME_VERSION_CODE" --version-name "$GAME_VERSION_NAME" -R /tmp/res.zip --auto-add-overlay
  unzip /tmp/_base.zip -d /tmp/base
  cp -r $APKTOOL_DECODED_PATH/assets/ $APKTOOL_DECODED_PATH/lib/ $APKTOOL_DECODED_PATH/unknown/ /tmp/base
  mkdir /tmp/base/manifest /tmp/base/dex
  mv /tmp/base/AndroidManifest.xml /tmp/base/manifest/AndroidManifest.xml
  mv /tmp/base/unknown /tmp/base/root
  mv /tmp/apk/*.dex /tmp/base/dex
  cd /tmp/base
  jar cMf /tmp/base.zip manifest dex res root lib assets resources.pb
  cd /
  java -jar /opt/bundletool.jar build-bundle --modules=/tmp/base.zip --output=$TEMP_UNSIGNED_AAB_FILE
  chmod 644 $TEMP_UNSIGNED_AAB_FILE
}

sign_apk_aab() {
  if [ -f "/game_certificate.key" ]; then
    java -jar /opt/signmyapp.jar -ks /game_certificate.key -ks-pass "$GAME_KEYSTORE_PASSWORD" -ks-key-alias "$GAME_KEYSTORE_KEY_ALIAS" -key-pass "$GAME_KEYSTORE_KEY_PASSWORD" -in $TEMP_ALIGNED_APK_FILE -out $OUTPUT_SIGNED_APK_FILE

    SIGALG=$(get_sigalg)
    jarsigner -verbose -sigalg $SIGALG -digestalg SHA-256 -signedjar $OUTPUT_SIGNED_AAB_FILE -keystore /game_certificate.key -storepass "$GAME_KEYSTORE_PASSWORD" $TEMP_UNSIGNED_AAB_FILE "$GAME_KEYSTORE_KEY_ALIAS"

    rm $TEMP_ALIGNED_APK_FILE $TEMP_UNSIGNED_AAB_FILE
  else
    mv $TEMP_ALIGNED_APK_FILE $OUTPUT_ALIGNED_APK_FILE
    mv $TEMP_UNSIGNED_AAB_FILE $OUTPUT_UNSIGNED_AAB_FILE
  fi
}

remove_temp_files() {
  rm -f $TEMP_UNSIGNED_APK_FILE
  rm -fr /tmp/apk /tmp/res.zip /tmp/_base.zip /tmp/base /tmp/base.zip $TEMP_RESOURCES_AAB_PATH
}
