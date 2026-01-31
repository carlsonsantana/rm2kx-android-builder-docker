FROM archlinux:base-devel as android-sdk-builder

# Build arguments
ARG APKTOOL_VERSION="2.12.1"

# Install dependencies
RUN pacman -Syu --noconfirm --disable-download-timeout && \
  pacman -S unzip jdk17-openjdk make git wget imagemagick autoconf automake libtool cmake perl patch pkgconf gcc meson oxipng --noconfirm --disable-download-timeout && \
  rm -R /var/cache/pacman/pkg/*
RUN mkdir /apktool && \
  curl -L "https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_""$APKTOOL_VERSION"".jar" --output /apktool/apktool.jar

# Copy Easy RPG buildscripts repository
COPY easyrpg_buildscripts /easyrpg_buildscripts
COPY easyrpg_player /easyrpg_buildscripts/android/Player
RUN rm /easyrpg_buildscripts/android/Player/.git && mkdir /easyrpg_buildscripts/android/Player/.git

# Create source builder
WORKDIR /easyrpg_buildscripts/android
RUN keytool -genkey -noprompt -v \
    -keystore /easyrpg_buildscripts/android/game_certificate.jks \
    -storepass 123456 \
    -keypass 123456 \
    -alias game_cert \
    -keyalg RSA \
    -dname "CN=gamename.mycompany.com, OU=O, O=O, L=O, S=O, C=US" && \
  sed -i "s|^KEYSTORE_PATH=$|KEYSTORE_PATH=/easyrpg_buildscripts/android/game_certificate.jks|g" /easyrpg_buildscripts/android/4_build_android_port.sh && \
  sed -i "s|^KEY_ALIAS=$|KEY_ALIAS=game_cert|g" /easyrpg_buildscripts/android/4_build_android_port.sh && \
  sed -i "s|^KEY_PASSWORD=$|KEY_PASSWORD=123456|g" /easyrpg_buildscripts/android/4_build_android_port.sh && \
  sed -i "s|applicationId \"org\.easyrpg\.player\"|applicationId \"aaaaa.bbbbb.ccccc\"|g" /easyrpg_buildscripts/android/Player/builds/android/app/build.gradle && \
  export BUILD_LIBLCF=1 && \
  ./0_build_everything.sh && \
  java -jar /apktool/apktool.jar d /easyrpg_buildscripts/android/Player/builds/android/app/build/outputs/apk/release/app-release.apk -o /easyrpg-android && \
  oxipng -r -o 2 --strip safe /easyrpg-android/res && \
  rm -r ~/.gradle ~/.android ~/.local && \
  rm -r android-sdk/ arm64-v8a-toolchain/ armeabi-v7a-toolchain/ x86-toolchain/ x86_64-toolchain/ && \
  rm -r /easyrpg_buildscripts/android/Player/builds/android/app/build /easyrpg_buildscripts/android/Player/builds/android/app/.cxx && \
  rm /easyrpg_buildscripts/android/game_certificate.jks && \
  unset BUILD_LIBLCF


# Another image with only used resources
FROM eclipse-temurin:17.0.17_10-jdk-alpine-3.23

# Install dependencies
RUN apk --update --no-cache add curl imagemagick oxipng zip abseil-cpp-hash gtest libprotobuf fmt && \
  apk --update --no-cache add android-build-tools --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/
RUN curl -L "https://github.com/carlsonsantana/signmyapp/releases/download/1.1.0/signmyapp.jar" --output /opt/signmyapp.jar && \
  curl -L "https://github.com/google/bundletool/releases/download/1.18.3/bundletool-all-1.18.3.jar" --output /opt/bundletool.jar && \
  curl -L "https://github.com/Sable/android-platforms/raw/f2ca864c44f277bbc09afda0ba36437ce22105f0/android-36/android.jar" --output /opt/android.jar

# Copy files from previous build
RUN mkdir /apktool
COPY --from=android-sdk-builder /apktool/apktool.jar /apktool/apktool.jar
COPY --from=android-sdk-builder /easyrpg-android /easyrpg-android

# Volumes
RUN mkdir /output
VOLUME /rpgmaker2kx_game
VOLUME /icon.png
VOLUME /output
VOLUME /game_certificate.key

# Environment variables
ENV GAME_APK_NAME "com.mycompany.gamename"
ENV GAME_NAME "Game Name"
ENV GAME_VERSION_CODE "100"
ENV GAME_VERSION_NAME "1.0.0"
ENV GAME_KEYSTORE_PASSWORD ""
ENV GAME_KEYSTORE_KEY_ALIAS ""
ENV GAME_KEYSTORE_KEY_PASSWORD ""
ENV GAME_METADATA_SITE "http://example.com/"
ENV GAME_OPTIMIZATION_MINIFY_IMAGES "false"

# Run build
WORKDIR /
COPY run.sh /
CMD ["sh", "/run.sh"]
