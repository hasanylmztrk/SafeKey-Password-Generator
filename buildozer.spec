[app]
title = SafeKey
package.name = safekey
package.domain = org.safekey
source.dir = .
source.include_exts = py,png,jpg,kv,atlas
source.exclude_exts = spec
version = 0.1
requirements = python3,kivy @ https://github.com/kivy/kivy/archive/master.zip
orientation = portrait
fullscreen = 0
android.permissions = INTERNET
android.api = 33
android.minapi = 24
android.ndk = 25b
android.archs = arm64-v8a
android.accept_sdk_license = True
android.build_tools = 33.0.0
p4a.branch = master

[buildozer]
log_level = 2
warn_on_root = 1
