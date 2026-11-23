#!/bin/zsh
# Gera dist/wallpaper4fun-<versão>.dmg: compila o app em Release e monta a imagem com o app e um
# atalho para a pasta Aplicativos (arrastar para instalar).
#   ./tools/make-dmg.sh
# Sem conta Apple Developer, o app sai com assinatura local (ad-hoc) e sem notarização: na primeira
# vez o macOS bloqueia e é preciso liberar em Ajustes do Sistema > Privacidade e Segurança.
set -e
cd "$(dirname "$0")/.."
export DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}

TMP=$(mktemp -d)
trap 'rm -rf $TMP' EXIT
xcodebuild -project wallpaper4fun.xcodeproj -scheme wallpaper4fun -configuration Release \
  -destination 'generic/platform=macOS' -derivedDataPath $TMP/build \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= -quiet build
APP=$TMP/build/Build/Products/Release/wallpaper4fun.app
VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' $APP/Contents/Info.plist)

mkdir $TMP/dmg
cp -R $APP $TMP/dmg/
ln -s /Applications $TMP/dmg/Aplicativos
mkdir -p dist
OUT=dist/wallpaper4fun-$VERSION.dmg
rm -f $OUT
hdiutil create -volname wallpaper4fun -srcfolder $TMP/dmg -format UDZO -fs APFS $OUT -quiet
echo "pronto: $OUT"
