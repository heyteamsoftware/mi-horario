#!/bin/bash
# Capturas REALES de Mi Horario en un emulador Android (para la ficha de Google Play).
set -x
PKG=com.heyteamsoftware.relojdeclases
OUT=play/capturas-reales; mkdir -p $OUT
APK=$(ls apk/*.apk | head -1)

ui()     { adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1; adb pull /sdcard/ui.xml /tmp/ui.xml >/dev/null 2>&1; python3 ui.py /tmp/ui.xml "$1"; }
busca()  { for i in $(seq 1 ${2:-1}); do c=$(ui "$1"); [ -n "$c" ] && { echo "$c"; return 0; }; adb shell input swipe 540 1400 540 900 500; sleep 1; done; return 1; }
toca()   { c=$(busca "$1" ${2:-1}) && { adb shell input tap $c; sleep 2; return 0; }; return 1; }
arriba() { c=$(busca "$1" 15) || return 1; y=${c#* }; d=$((y-$2)); [ $d -gt 0 ] && adb shell input swipe 540 1500 540 $((1500-d)) 1500; sleep 2; }
fecha()  { adb shell date 1116$1$2"2026.00"; sleep 4; adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm $1$2; }
foto()   { sleep 3; adb exec-out screencap -p > $OUT/$1.png; }
inicio() { adb shell am force-stop $PKG; adb shell am start -n $PKG/.MainActivity; sleep 4; for i in 1 2 3 4 5 6; do adb shell input swipe 540 500 540 1700 150; done; sleep 2; }

# Español, hora de Canarias y lunes 16-11-2026
adb root; sleep 5; adb wait-for-device
adb shell "setprop persist.sys.locale es-ES; setprop persist.sys.timezone Atlantic/Canary"
adb shell "stop; start"; sleep 10; adb wait-for-device
until [ "$(adb shell getprop sys.boot_completed | tr -d '\r')" = 1 ]; do sleep 3; done; sleep 25
adb shell settings put global auto_time 0
adb shell settings put system screen_off_timeout 1800000
adb shell locksettings set-disabled false
adb shell wm dismiss-keyguard; adb shell input keyevent 82; sleep 2
adb shell settings put global sysui_demo_allowed 1
adb shell am broadcast -a com.android.systemui.demo -e command enter
adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false
adb shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4
adb shell am broadcast -a com.android.systemui.demo -e command notifications -e visible true
fecha 11 02

# Instalar y cargar el horario de ejemplo
adb install -r -g "$APK"
adb shell pm grant $PKG android.permission.POST_NOTIFICATIONS
adb shell appops set $PKG SCHEDULE_EXACT_ALARM allow
inicio
toca "Cargar un horario de ejemplo" 25
toca "^s[ií]$"
sleep 3

# 1 · Widget en el escritorio
inicio
toca "Añadir el widget" 5
sleep 3; toca "autom" || toca "^añadir$|^add$"
sleep 2; adb shell input keyevent KEYCODE_HOME; sleep 3
fecha 11 02; adb shell input keyevent KEYCODE_HOME; foto 1_escritorio

# 2 · Pantalla de bloqueo
fecha 11 04
adb shell input keyevent KEYCODE_SLEEP; sleep 3; adb shell input keyevent KEYCODE_WAKEUP; sleep 4
foto 2_bloqueo
adb shell wm dismiss-keyguard; adb shell input keyevent 82; sleep 3

# 3 · Notificación desplegada
fecha 11 03
adb shell cmd statusbar expand-notifications; sleep 3; foto 3_notificacion
adb shell cmd statusbar collapse; sleep 2

# 4, 5, 6 · Pantallas de la app
fecha 11 02
inicio; foto 4_app
arriba "^Importar horario$" 150; foto 5_importar
inicio; arriba "^Clases$" 150; foto 6_clases
ls -la $OUT
