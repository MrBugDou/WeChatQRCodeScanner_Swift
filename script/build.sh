#!/bin/bash

set -ex

echo "OpenCV Version: $1"

CUR_DIR=$PWD
WORK_DIR=$PWD/work_dir
mkdir -p $WORK_DIR

OPENCV_SOURCE_DIR=$WORK_DIR/opencv_$1
OPENCV_SOURCE_CONTRIB_DIR=$WORK_DIR/opencv_contrib_$1

if [[ ! -d "$OPENCV_SOURCE_DIR" ]]; then
    echo "下载OpenCV 源码 ...."
    git clone --single-branch --depth 1 -b $1 https://github.com/opencv/opencv.git $OPENCV_SOURCE_DIR
fi

if [[ ! -d "$OPENCV_SOURCE_CONTRIB_DIR" ]]; then
    echo "下载 wechat_qrcode 源码 ...."
    git clone --single-branch --depth 1 -b $1 https://github.com/opencv/opencv_contrib $OPENCV_SOURCE_CONTRIB_DIR
    cd $CUR_DIR
fi

WECHAT_QR_CODE_SOURCE_DIR=$WORK_DIR/opencv_contrib_wechat_qrcode

mkdir -p $WECHAT_QR_CODE_SOURCE_DIR/modules

OUT_DIR=$WORK_DIR/ios

if [[ ! -d "$OUT_DIR/opencv2.framework" ]]; then
    echo "开始编译 ...."
    cp -rf $OPENCV_SOURCE_CONTRIB_DIR/modules/wechat_qrcode $WECHAT_QR_CODE_SOURCE_DIR/modules
    # cp -rf $OPENCV_SOURCE_CONTRIB_DIR/modules/barcode $WECHAT_QR_CODE_SOURCE_DIR/modules
    cd $WORK_DIR
    python $OPENCV_SOURCE_DIR/platforms/ios/build_framework.py \
    --opencv $OPENCV_SOURCE_DIR \
    --contrib $WECHAT_QR_CODE_SOURCE_DIR \
    --without stitching \
    --without world \
    --without highgui \
    --without gapi \
    --without photo \
    --without ml \
    --without java \
    --without python \
    --without js \
    --without ts \
    --without video \
    --without videoio \
    --iphoneos_archs arm64 \
    --build_only_specified_archs \
    --disable-bitcode \
    --disable-swift \
    $OUT_DIR
fi

POD_DIR=$CUR_DIR/WeChatQRCodeScanner

mkdir -p $POD_DIR/Frameworks $POD_DIR/Models

if [[ ! -d "$POD_DIR/Frameworks/opencv2.framework" ]]; then
    cp -rf $OUT_DIR/build/build-arm64-iphoneos/downloads/wechat_qrcode $POD_DIR/Models/
    # cp -rf $OUT_DIR/build/build-arm64-iphoneos/downloads/barcode $POD_DIR/Models/
    cp -rf $OUT_DIR/opencv2.framework $POD_DIR/Frameworks
fi

cd $CUR_DIR

# exit -1
