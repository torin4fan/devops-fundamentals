#!/bin/bash
BUILD_FOLDER="./dist"
ZIP_NAME="client-app.zip"

npm install

if [ -d $BUILD_FOLDER ]
then 
    rm -R $BUILD_FOLDER
    echo "dist folder was removed"
fi

npm run build --configuration=$$ENV_CONFIGURATION
zip -r $ZIP_NAME $BUILD_FOLDER
mv $ZIP_NAME $BUILD_FOLDER
