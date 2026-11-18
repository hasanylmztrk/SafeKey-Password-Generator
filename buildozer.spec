[app]
title = SafeKey
package.name = safekey
package.domain = org.safekey
source.dir = .
source.include_exts = py,png,jpg,kv,atlas
source.exclude_exts = spec
version = 0.1
requirements = python3,kivy==2.3.0
orientation = portrait
fullscreen = 0
android.permissions = INTERNET
android.api = 33
android.minapi = 21
android.ndk = 25b
android.archs = arm64-v8a, armeabi-v7a
android.accept_sdk_license = True
android.build_tools = 33.0.2
p4a.bootstrap = sdl2

[buildozer]
log_level = 2
warn_on_root = 1
