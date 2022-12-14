set -e
rm -rf build
mkdir -p releases

echo ${OCTOBLAST_VERSION:-1.0.0} >OctoBlast/version.txt
cat OctoBlast/version.txt
sed -i .bak 's/CURRENT_PROJECT_VERSION.*;/CURRENT_PROJECT_VERSION = '${OCTOBLAST_VERSION:-1.0.0}';/g' OctoBlast.xcodeproj/project.pbxproj
sed -i .bak 's/MARKETING_VERSION.*;/MARKETING_VERSION = '${OCTOBLAST_VERSION:-1.0.0}';/g' OctoBlast.xcodeproj/project.pbxproj
xcodebuild clean
xcodebuild clean archive -scheme OctoBlast -configuration Release -archivePath build/OctoBlast.xcarchive
xcodebuild -exportArchive -archivePath build/OctoBlast.xcarchive -exportPath build/OctoBlast -exportOptionsPlist OctoBlast/Info.plist

cd build/OctoBlast/
zip -r ../../releases/archives/OctoBlast-${OCTOBLAST_VERSION:-1.0.0}.zip OctoBlast.app
