//
//  DDBarCodeImageScanner.m
//  Pods
//
//  Created by king on 2021/2/26.
//

#import "DDBarCodeImageScanner.h"
#import "DDQRCodeScannerResult.h"
#include <iostream>
#import <opencv2/Mat.h>
#import <opencv2/barcode.hpp>
#import <opencv2/imgproc.hpp>
#import <opencv2/CVObjcUtil.h>

#import <opencv2/WeChatQRCode.h>
#import <opencv2/core/hal/interface.h>

@interface DDBarCodeImageScanner ()

@property (nonatomic, assign) cv::Ptr<cv::barcode::BarcodeDetector> barDetector;

@property (nonatomic, assign) cv::Ptr<cv::wechat_qrcode::WeChatQRCode> wechatDetector;

@end

@implementation DDBarCodeImageScanner

- (instancetype)init {
	if (self == [super init]) {
		[self commonInit];
	}
	return self;
}

#pragma mark - Initial Methods
- (void)commonInit {
    NSBundle *mainBundle                        = [NSBundle bundleForClass:self.class];
    NSBundle *bundle                            = [NSBundle bundleWithPath:[mainBundle pathForResource:@"WeChatQRCodeScanner" ofType:@"bundle"]];
    NSString *detector_prototxt_path            = [bundle pathForResource:@"detect" ofType:@"prototxt"];
    NSString *detector_caffe_model_path         = [bundle pathForResource:@"detect" ofType:@"caffemodel"];
    NSString *super_resolution_prototxt_path    = [bundle pathForResource:@"sr" ofType:@"prototxt"];
    NSString *super_resolution_caffe_model_path = [bundle pathForResource:@"sr" ofType:@"caffemodel"];

    _barDetector = cv::makePtr<cv::barcode::BarcodeDetector>(super_resolution_prototxt_path.UTF8String,
                                                          super_resolution_caffe_model_path.UTF8String);
    
    _wechatDetector = cv::makePtr<cv::wechat_qrcode::WeChatQRCode>(detector_prototxt_path.UTF8String,
                                                             detector_caffe_model_path.UTF8String,
                                                             super_resolution_prototxt_path.UTF8String,
                                                             super_resolution_caffe_model_path.UTF8String);
}

- (NSArray<DDQRCodeScannerResult *> *)scannerForImage:(UIImage *)image{
    cv::Mat cvMat = [DDBarCodeImageScanner cvMatFromImage:image];
    NSMutableArray *result = [NSMutableArray array];
    NSArray *barCodes = [self barScannerForImage:cvMat];
    if (barCodes.count) {
        [result addObjectsFromArray:barCodes];
    }
    NSArray *qrCodes = [self qrCodeScannerForImage:cvMat];
    if (qrCodes.count) {
        [result addObjectsFromArray:qrCodes];
    }
    return [result copy];
}

- (NSArray<DDQRCodeScannerResult *> *)barScannerForImage:(cv::Mat)cvMat {
    std::vector<cv::Point2f> corners;
    std::vector<cv::String> decode_info;
    std::vector<cv::barcode::BarcodeType> decoded_type;
    
//    bool result_detection =  self.barDetector->detect(cvMat, corners);
//    CV_UNUSED(result_detection);
    
    bool result_detection =  self.barDetector->detectAndDecode(cvMat, decode_info, decoded_type, corners);
    CV_UNUSED(result_detection);
    
    NSMutableArray<DDQRCodeScannerResult *> *results = nil;
    if (!corners.empty())
    {
        size_t size = corners.size();
        results = [NSMutableArray<DDQRCodeScannerResult *> arrayWithCapacity:(size/4)];
        for (size_t i = 0; i < size; i += 4)
        {
            size_t bar_idx = i / 4;
            std::vector<cv::Point2f> barcode_contour(corners.begin() + i, corners.begin() + i + 4);
            cv::Point2d bottomLeft = barcode_contour[0];
            cv::Point2d topLeft = barcode_contour[1];
            cv::Point2d topRight = barcode_contour[2];
            cv::Point2d bottomRight = barcode_contour[3];
//            cv::Rect2d rect(topLeft.x, topLeft.y, (topRight.x - topLeft.x), (bottomLeft.y - topLeft.y));
//            UIImage *image1 = [DDBarCodeImageScanner imageFromCVMat:cvMat(rect)];
            CGRect rectOfImage = CGRectMake(topLeft.x, topLeft.y, (topRight.x - topLeft.x), (bottomLeft.y - topLeft.y));
            NSString *content;
            if (decode_info.size() > bar_idx)
            {
                cv::String info = decode_info[bar_idx];
                if (!info.empty())
                {
                    NSString *type = [self stringFrom:decoded_type[bar_idx]];
                    content = [NSString stringWithCString:info.c_str() encoding:NSUTF8StringEncoding];
                    NSLog(@"TYPE: %@ INFO: %@, rectOfImage: %@",type,content,NSStringFromCGRect(rectOfImage));
                }
                else
                {
                    NSLog(@"can't decode 1D barcode");
                }
            }
            else
            {
                NSLog(@"decode information is not available (disabled)");
            }
            DDQRCodeScannerResult *ret = [[DDQRCodeScannerResult alloc] initWithContent:content rectOfImage:rectOfImage rectOfView:(CGRectZero)];
            [results addObject:ret];
        }
    }
    else
    {
        NSLog(@"Barcode is not detected");
    }

	return [results copy];
}

- (NSArray<DDQRCodeScannerResult *> *)qrCodeScannerForImage:(cv::Mat)cvMat {
    std::vector<cv::Mat> points;
    std::vector<std::string> res = self.wechatDetector->detectAndDecode(cvMat, points);
    
    NSMutableArray<DDQRCodeScannerResult *> *results = nil;
    if (res.size() > 0) {

        size_t size = res.size();

        results = [NSMutableArray<DDQRCodeScannerResult *> arrayWithCapacity:size];

        for (size_t i = 0; i < size; i++) {
            NSString *content = [NSString stringWithCString:res[i].c_str() encoding:NSUTF8StringEncoding];
            cv::Mat &m        = points[i];

            CGPoint topLeft    = CGPointMake(m.at<float>(0, 0), m.at<float>(0, 1));
            CGPoint topRight   = CGPointMake(m.at<float>(1, 0), m.at<float>(1, 1));
            CGPoint bottomLeft = CGPointMake(m.at<float>(2, 0), m.at<float>(2, 1));
            CGRect rectOfImage = (CGRect){topLeft, CGSizeMake(topRight.x - topLeft.x, bottomLeft.y - topLeft.y)};

            DDQRCodeScannerResult *r = [[DDQRCodeScannerResult alloc] initWithContent:content rectOfImage:rectOfImage rectOfView:CGRectZero];
            [results addObject:r];
        }
    }

    return [results copy];
}

- (NSString *)stringFrom:(cv::barcode::BarcodeType)barcode_type{
    switch (barcode_type)
    {
        case cv::barcode::BarcodeType::EAN_8:
            return @"EAN_8";
        case cv::barcode::BarcodeType::EAN_13:
            return @"EAN_13";
        case cv::barcode::BarcodeType::UPC_E:
            return @"UPC_E";
        case cv::barcode::BarcodeType::UPC_A:
            return @"UPC_A";
        case cv::barcode::BarcodeType::UPC_EAN_EXTENSION:
            return @"UPC_EAN_EXTENSION";
        default:
            return @"NONE";
    }
}

+ (Mat *)matFromImage:(UIImage *)image{
    cv::Mat cvMat = [self cvMatFromImage:image];
    return [Mat fromNative:cvMat];
}

+ (cv::Mat)cvMatFromImage:(UIImage *)image{
  CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
  CGFloat cols = image.size.width;
  CGFloat rows = image.size.height;
  cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
  CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                 cols,                       // Width of bitmap
                                                 rows,                       // Height of bitmap
                                                 8,                          // Bits per component
                                                 cvMat.step[0],              // Bytes per row
                                                 colorSpace,                 // Colorspace
                                                 kCGImageAlphaNoneSkipLast |
                                                 kCGBitmapByteOrderDefault); // Bitmap info flags
  CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
  CGContextRelease(contextRef);
  return cvMat;
}

+ (Mat *)matGrayFromImage:(UIImage *)image{
    cv::Mat cvMat = [self cvMatGrayFromImage:image];
    return [Mat fromNative:cvMat];
}

+ (cv::Mat)cvMatGrayFromImage:(UIImage *)image{
  CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
  CGFloat cols = image.size.width;
  CGFloat rows = image.size.height;
  cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
  CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                 cols,                       // Width of bitmap
                                                 rows,                       // Height of bitmap
                                                 8,                          // Bits per component
                                                 cvMat.step[0],              // Bytes per row
                                                 colorSpace,                 // Colorspace
                                                 kCGImageAlphaNoneSkipLast |
                                                 kCGBitmapByteOrderDefault); // Bitmap info flags
  CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
  CGContextRelease(contextRef);
  return cvMat;
 }

+ (UIImage *)imageFromMat:(Mat *)mat{
    return [self imageFromCVMat:mat.nativeRef];
}

+ (UIImage *)imageFromCVMat:(cv::Mat)cvMat{
  NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
  CGColorSpaceRef colorSpace;
  if (cvMat.elemSize() == 1) {
      colorSpace = CGColorSpaceCreateDeviceGray();
  } else {
      colorSpace = CGColorSpaceCreateDeviceRGB();
  }
  CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
  // Creating CGImage from cv::Mat
  CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                     cvMat.rows,                                 //height
                                     8 * cvMat.elemSize1(),                     //bits per component
                                     8 * cvMat.elemSize(),                       //bits per pixel
                                     cvMat.step[0],                            //bytesPerRow
                                     colorSpace,                                 //colorspace
                                     kCGImageAlphaNoneSkipLast|kCGBitmapByteOrderDefault,// bitmap info
                                     provider,                                   //CGDataProviderRef
                                     NULL,                                       //decode
                                     false,                                      //should interpolate
                                     kCGRenderingIntentDefault                   //intent
                                     );
  // Getting UIImage from CGImage
  UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
  CGImageRelease(imageRef);
  CGDataProviderRelease(provider);
  CGColorSpaceRelease(colorSpace);
  return finalImage;
 }

@end

