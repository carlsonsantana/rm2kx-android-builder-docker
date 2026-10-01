#!/bin/sh

set -e

APP_BASENAME="rpgmaker2kx"
APKTOOL_DECODED_PATH="/easyrpg-android"
RESOURCE_PREFIX="rm2kx"
ICON_BASENAME="ic_launcher"

source "/script/common.sh"

init_keystore_variables
remove_previous_build_files
validate_secrets_filled
replace_icons

# Rename APK name and application ID
sed -i "s|EasyRPG Player|$GAME_NAME|g" /easyrpg-android/res/values/strings.xml
sed -i "s|\"aaaaa\.bbbbb\.ccccc\"|\"$GAME_APK_NAME\"|g" /easyrpg-android/AndroidManifest.xml
sed -i "s|https://easyrpg\.org/|$GAME_METADATA_SITE|g" /easyrpg-android/res/layout/browser_nav_header.xml
printf "version: 2.12.1\napkFileName: app-release.apk\nusesFramework:\n  ids:\n  - 1\nsdkInfo:\n  minSdkVersion: 21\n  targetSdkVersion: 36\npackageInfo:\n  forcedPackageId: 127\n  renameManifestPackage: "$GAME_APK_NAME"\nversionInfo:\n  versionCode: "$GAME_VERSION_CODE"\n  versionName: "$GAME_VERSION_NAME"\ndoNotCompress:\n- arsc\n- png\n- META-INF/androidx.activity_activity.version\n- META-INF/androidx.annotation_annotation-experimental.version\n- META-INF/androidx.appcompat_appcompat-resources.version\n- META-INF/androidx.appcompat_appcompat.version\n- META-INF/androidx.cardview_cardview.version\n- META-INF/androidx.constraintlayout_constraintlayout.version\n- META-INF/androidx.coordinatorlayout_coordinatorlayout.version\n- META-INF/androidx.core_core-ktx.version\n- META-INF/androidx.core_core-viewtree.version\n- META-INF/androidx.core_core.version\n- META-INF/androidx.cursoradapter_cursoradapter.version\n- META-INF/androidx.customview_customview-poolingcontainer.version\n- META-INF/androidx.customview_customview.version\n- META-INF/androidx.documentfile_documentfile.version\n- META-INF/androidx.drawerlayout_drawerlayout.version\n- META-INF/androidx.dynamicanimation_dynamicanimation.version\n- META-INF/androidx.emoji2_emoji2-views-helper.version\n- META-INF/androidx.emoji2_emoji2.version\n- META-INF/androidx.fragment_fragment.version\n- META-INF/androidx.interpolator_interpolator.version\n- META-INF/androidx.legacy_legacy-support-core-utils.version\n- META-INF/androidx.loader_loader.version\n- META-INF/androidx.localbroadcastmanager_localbroadcastmanager.version\n- META-INF/androidx.print_print.version\n- META-INF/androidx.profileinstaller_profileinstaller.version\n- META-INF/androidx.recyclerview_recyclerview.version\n- META-INF/androidx.savedstate_savedstate.version\n- META-INF/androidx.startup_startup-runtime.version\n- META-INF/androidx.tracing_tracing.version\n- META-INF/androidx.transition_transition.version\n- META-INF/androidx.vectordrawable_vectordrawable-animated.version\n- META-INF/androidx.vectordrawable_vectordrawable.version\n- META-INF/androidx.versionedparcelable_versionedparcelable.version\n- META-INF/androidx.viewpager2_viewpager2.version\n- META-INF/androidx.viewpager_viewpager.version\n- META-INF/com.google.android.material_material.version\n- META-INF/kotlinx_coroutines_android.version\n- META-INF/kotlinx_coroutines_core.version\n- assets/dexopt/baseline.prof\n- assets/dexopt/baseline.profm" > /easyrpg-android/apktool.yml

# Create game.zip asset
if [ "$GAME_OPTIMIZATION_MINIFY_IMAGES" == "true" ]; then
  cp -r /rpgmaker2kx_game /tmp/rpgmaker2kx_game
  oxipng -o 2 --strip safe --nb --np -r /tmp/rpgmaker2kx_game
  cd /tmp/rpgmaker2kx_game
else
  cd /rpgmaker2kx_game
fi
zip -Z deflate -x *.exe -x .gitkeep -x **/Thumbs.db -vr /easyrpg-android/assets/game.zip *

build_aligned_apk
build_unsigned_aab
sign_apk_aab
remove_temp_files
