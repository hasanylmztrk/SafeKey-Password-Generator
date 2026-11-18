[app]
title = SafeKey
package.name = safekey
package.domain = org.safekey
source.dir = .
source.include_exts = py,png,jpg,kv,atlas
version = 0.1
requirements = python3,kivy
orientation = portrait
fullscreen = 0
android.permissions = INTERNET
android.api = 33
android.minapi = 24
android.ndk = 25b
android.archs = arm64-v8a, armeabi-v7a
android.accept_sdk_license = True
android.build_tools = 33.0.0

[buildozer]
log_level = 2
warn_on_root = 1
