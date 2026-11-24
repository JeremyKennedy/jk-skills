# Emulator setup

A device is better: real rendering, real timing, and no SDK download. Check
`adb devices` first, and use the device if it is there.

Without one, this gets a headless emulator up in about fifteen minutes, most of
it download. Everything below stays outside the Nix store and outside a project
checkout, under a scratch directory such as `/tmp/<name>/androidsdk`.

## SDK

```bash
D=/tmp/android/androidsdk
mkdir -p "$D/cmdline-tools"
curl -sSL -o "$D/cmdline.zip" https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip -q "$D/cmdline.zip" -d "$D/cmdline-tools"
mv "$D/cmdline-tools/cmdline-tools" "$D/cmdline-tools/latest"

export ANDROID_HOME=$D ANDROID_SDK_ROOT=$D
export JAVA_HOME=<a JDK 17 or newer>
export PATH=$JAVA_HOME/bin:$D/cmdline-tools/latest/bin:$D/platform-tools:$D/emulator:$PATH

yes | sdkmanager --sdk_root=$D --licenses
sdkmanager --sdk_root=$D --list | grep -E 'platforms;android-|build-tools;|system-images;|emulator|platform-tools'
```

Install the platform and build-tools the project asks for (its
`variables.gradle` or `build.gradle` names `compileSdkVersion`), plus the
emulator and one system image:

```bash
sdkmanager --sdk_root=$D "platform-tools" "platforms;android-37.0" \
  "build-tools;37.0.0" "emulator" "system-images;android-35;google_apis;x86_64"
```

Two mismatches bite here:

- The SDK may name a platform `android-37.0` while Gradle looks for
  `android-37`. Symlink when the build fails on a missing platform:
  `ln -s $D/platforms/android-37.0 $D/platforms/android-37`.
- A system image does not have to match `compileSdkVersion`. The emulator only
  needs a bootable image; `android-35` running an app compiled against 37 is
  normal.

Expect about 5 GB.

## AVD and boot

```bash
export ANDROID_AVD_HOME=/tmp/android/avd
mkdir -p "$ANDROID_AVD_HOME"
echo no | avdmanager create avd -n app -k "system-images;android-35;google_apis;x86_64" -d pixel_7 --force

setsid emulator -avd app -no-window -no-audio -no-snapshot -no-boot-anim \
  -gpu swiftshader_indirect -memory 3072 > /tmp/android/emulator.log 2>&1 &

for i in $(seq 1 30); do
  [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] && break
  sleep 5
done
adb devices
```

`/dev/kvm` makes it usable; without it expect a boot measured in minutes and
timing that ruins recordings. `-no-window` is what makes `screenrecord` truncate
(see `recording.md`), so plan on the WebView recording path.

The emulator reaches the host as `10.0.2.2`, which is how an app pairs back to a
server running on the machine. `adb reverse tcp:PORT tcp:PORT` is the other way
round if the app expects `localhost`.

## Install and drive

```bash
adb install -r path/to/app-debug.apk
adb shell monkey -p <package> -c android.intent.category.LAUNCHER 1
adb shell pm list packages | grep <package>
```

Reinstalling restarts the app. Anything holding a DevTools forward or a socket
to the old process is now stale; recreate it.

`uiautomator` gives the native window geometry, which is useful for mapping page
coordinates to device pixels and for checking which window has focus:

```bash
adb shell uiautomator dump /sdcard/ui.xml >/dev/null
adb shell cat /sdcard/ui.xml | tr '>' '\n' | grep -o 'class="android.webkit.WebView"[^/]*bounds="[^"]*"'
adb shell wm size
```
