#!/bin/bash

set -ex

CUR_DIR=$PWD
DOWNLOAD_DIR=$CUR_DIR/download_dir
ZIP_FILE=$DOWNLOAD_DIR/$1.zip
LIB_UNZIP_DIR=$DOWNLOAD_DIR/lib

mkdir -p $DOWNLOAD_DIR

wget https://github.com/0x1306a94/WeChatQRCodeScanner/releases/download/$1/$1.zip -O $ZIP_FILE

unzip -o $ZIP_FILE -d $DOWNLOAD_DIR

POD_DIR=$CUR_DIR/WeChatQRCodeScanner

mkdir -p $POD_DIR/Frameworks/opencv2.xcframework $POD_DIR/Models

cp -rf $LIB_UNZIP_DIR/opencv2.xcframework/ios-arm64 $POD_DIR/Frameworks/opencv2.xcframework
cp -rf $LIB_UNZIP_DIR/wechat_qrcode $POD_DIR/Models

rm -rf $DOWNLOAD_DIR
