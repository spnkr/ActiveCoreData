cd ~/ActiveCoreData;
xcodebuild docbuild -scheme ActiveCoreData -derivedDataPath docc -destination 'generic/platform=iOS';

cd ~/Desktop/;
git clone git@github.com:spnkr/ActiveCoreData.git;
cd ActiveCoreData;
git checkout docs;
rm -rf docs;

cd ~/ActiveCoreData;

$(xcrun --find docc) process-archive transform-for-static-hosting docc/Build/Products/Debug-iphoneos/ActiveCoreData.doccarchive --hosting-base-path ActiveCoreData --output-path ~/Desktop/ActiveCoreData/docs;

rm -rf docc;

cd ~/Desktop/ActiveCoreData;
echo "<script>window.location.href += \"/documentation/activecoredata\"</script>" > docs/index.html;

#git add .;
#git commit -m 'Documentation update';
#git push origin docs;
