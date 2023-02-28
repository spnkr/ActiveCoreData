xcodebuild docbuild -scheme CoreDataPlus -derivedDataPath docc -destination 'generic/platform=iOS';

cd ~/Desktop/;
git clone git@github.com:spnkr/CoreDataPlus.git;
cd CoreDataPlus;
git checkout docs;
rm -rf docs;

cd ~/CoreDataPlus;

$(xcrun --find docc) process-archive transform-for-static-hosting docc/Build/Products/Debug-iphoneos/CoreDataPlus.doccarchive --hosting-base-path CoreDataPlus --output-path ~/Desktop/CoreDataPlus/docs;

rm -rf docc;

cd ~/Desktop/CoreDataPlus;
echo "<script>window.location.href += \"/documentation/coredataplus\"</script>" > docs/index.html;

#git add .;
#git commit -m 'Documentation update';
#git push origin docs;
