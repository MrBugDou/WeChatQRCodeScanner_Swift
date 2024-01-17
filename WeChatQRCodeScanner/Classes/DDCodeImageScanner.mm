//
//  DDCodeImageScanner.m
//  WeChatQRCodeScanner
//
//  Created by king on 2021/2/3.
//

#import "DDCodeImageScanner.h"
#import <opencv2/Mat.h>
#import <opencv2/WeChatQRCode.h>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/MatConverters.h>
#import <opencv2/core/hal/interface.h>

@interface DDCodeImageScanner ()

@property (nonatomic, assign) WeChatQRCode *wechatDetector;

@property (nonatomic, assign) cv::Ptr<cv::wechat_qrcode::WeChatQRCode> detector;
@end

@implementation DDCodeImageScanner

+ (instancetype)shared{
    static DDCodeImageScanner *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)dealloc{
    _detector.release();
}

#pragma mark - Initial Methods
- (void)commonInit {
    NSBundle *mainBundle                        = [NSBundle bundleForClass:self.class];
    NSBundle *bundle                            = [NSBundle bundleWithPath:[mainBundle pathForResource:@"WeChatQRCodeScanner" ofType:@"bundle"]];
    NSString *detector_prototxt_path            = [bundle pathForResource:@"detect" ofType:@"prototxt"];
    NSString *detector_caffe_model_path         = [bundle pathForResource:@"detect" ofType:@"caffemodel"];
    NSString *super_resolution_prototxt_path    = [bundle pathForResource:@"sr" ofType:@"prototxt"];
    NSString *super_resolution_caffe_model_path = [bundle pathForResource:@"sr" ofType:@"caffemodel"];
    _detector = cv::makePtr<cv::wechat_qrcode::WeChatQRCode>(detector_prototxt_path.UTF8String,
                                                             detector_caffe_model_path.UTF8String,
                                                             super_resolution_prototxt_path.UTF8String,
                                                             super_resolution_caffe_model_path.UTF8String);
//    _wechatDetector = [[WeChatQRCode alloc] initWithDetector_prototxt_path:detector_prototxt_path
//                                                 detector_caffe_model_path:detector_caffe_model_path
//                                            super_resolution_prototxt_path:super_resolution_prototxt_path
//                                         super_resolution_caffe_model_path:super_resolution_caffe_model_path];
    
}

- (UIImage *)checkImageConfig:(UIImage *)image {
    if (image.CGImage) {
        CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(image.CGImage);
        if (alphaInfo == kCGImageAlphaNoneSkipLast || alphaInfo == kCGImageAlphaNoneSkipFirst || alphaInfo == kCGImageAlphaPremultipliedLast || alphaInfo == kCGImageAlphaPremultipliedFirst) {
            return image;
        }
    }
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawAtPoint:CGPointZero];
    UIImage *copy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return copy;
}

- (NSArray<DDQRCodeResult *> *)scanForImage:(UIImage *)image {
    if (!image) {
        return nil;
    }
    
    // 获取UIImage的CGImage
    CGImageRef cgImage = [self checkImageConfig:image].CGImage;
    
    // 获取UIImage的大小
    CGSize imageSize = CGSizeMake(CGImageGetWidth(cgImage), CGImageGetHeight(cgImage));
    
    cv::Mat cvMat(imageSize.height, imageSize.width, CV_8UC4);  // 8 bits per component, 4 channels (RGBA)
    
    // 创建颜色空间
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(cgImage);
    
    // 创建上下文
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,     // Pointer to  data
                                                    imageSize.width, // Width of bitmap
                                                    imageSize.height, // Height of bitmap
                                                    8,              // Bits per component
                                                    cvMat.step[0],  // Bytes per row
                                                    colorSpace,     // Colorspace
                                                    kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);  // Bitmap info flags
    // 绘制UIImage到上下文
    CGContextDrawImage(contextRef, CGRectMake(0, 0, imageSize.width, imageSize.height), cgImage);
    
    // 释放上下文
    CGContextRelease(contextRef);
    NSMutableArray<DDQRCodeResult *> *results = [self scanForCvMat:cvMat];
    cvMat.release();
    return [results copy];
}

- (NSArray<DDQRCodeResult *> *)scanForImageBuf:(CVImageBufferRef)imgBuf {
    if (imgBuf == NULL) {
        return nil;
    }
    CVPixelBufferLockBaseAddress(imgBuf, 0);
    
    void *imgBufAddr = CVPixelBufferGetBaseAddressOfPlane(imgBuf, 0);
    
    int w = (int)CVPixelBufferGetWidth(imgBuf);
    int h = (int)CVPixelBufferGetHeight(imgBuf);
    
    cv::Mat mat(h, w, CV_8UC4, imgBufAddr, 0);
    
    cv::Mat transMat;
    cv::transpose(mat, transMat);
    
    cv::Mat flipMat;
    cv::flip(transMat, flipMat, 1);
    
    CVPixelBufferUnlockBaseAddress(imgBuf, 0);

    NSMutableArray<DDQRCodeResult *> *results = [self scanForCvMat:flipMat];
    transMat.release();
    flipMat.release();
    return results;
}

- (NSArray<DDQRCodeResult *> *)scanForCvMat:(cv::Mat)cvMat{
    if (cvMat.empty()) {
        cvMat.release();
        return nil;
    }
    std::vector<cv::Mat> points;
    std::vector<std::string> res = self.detector->detectAndDecode(cvMat, points);
    NSMutableArray<DDQRCodeResult *> *results = nil;
    if (res.size() > 0) {
        size_t size = res.size();
        results = [NSMutableArray<DDQRCodeResult *> arrayWithCapacity:size];
        for (size_t i = 0; i < size; i++) {
            NSString *content = [NSString stringWithCString:res[i].c_str() encoding:NSUTF8StringEncoding];
            cv::Mat &m        = points[i];
            CGPoint topLeft    = CGPointMake(m.at<float>(0, 0), m.at<float>(0, 1));
            CGPoint topRight   = CGPointMake(m.at<float>(1, 0), m.at<float>(1, 1));
            CGPoint bottomLeft = CGPointMake(m.at<float>(2, 0), m.at<float>(2, 1));
            CGPoint bottomRight = CGPointMake(m.at<float>(3, 0), m.at<float>(3, 1));
            NSLog(@"%@, %@, %@, %@",NSStringFromCGPoint(topLeft),NSStringFromCGPoint(topRight),NSStringFromCGPoint(bottomLeft),NSStringFromCGPoint(bottomRight));
            CGRect rectOfImage = (CGRect){topLeft, CGSizeMake(topRight.x - topLeft.x, bottomLeft.y - topLeft.y)};
            [results addObject:[[DDQRCodeResult alloc] initWithContent:content rectOfImage:rectOfImage]];
            m.release();
        }
    }
    cvMat.release();
    return results;
}

//- (NSArray<DDQRCodeResult *> *)scanForMat:(Mat *)mat{
//    if (!mat) {
//        return nil;
//    }
//    NSMutableArray *points = [NSMutableArray array];
//    NSArray *datas = [_wechatDetector detectAndDecode:mat points:points];
//    if (datas.count == 0) {
//        return nil;
//    }
//    NSMutableArray<DDQRCodeResult *> *results = [NSMutableArray arrayWithCapacity:datas.count];
//    for (int i = 0; i < datas.count; i++) {
//        Mat *point = points[i];
//        cv::Mat &m = mat.nativeRef;
//        NSString *content = datas[i];
//        CGPoint topLeft    = CGPointMake(m.at<float>(0, 0), m.at<float>(0, 1));
//        CGPoint topRight   = CGPointMake(m.at<float>(1, 0), m.at<float>(1, 1));
//        CGPoint bottomLeft = CGPointMake(m.at<float>(2, 0), m.at<float>(2, 1));
//        // CGPoint bottomRight = CGPointMake(m.at<float>(3, 0), m.at<float>(3, 1));
//        CGRect rectOfImage = (CGRect){topLeft, CGSizeMake(topRight.x - topLeft.x, bottomLeft.y - topLeft.y)};
//        [results addObject:[[DDQRCodeResult alloc] initWithContent:content rectOfImage:rectOfImage]];
//        m.release();
//    }
//    return results;
//}

@end

@implementation DDQRCodeResult

- (instancetype)initWithContent:(NSString *)content rectOfImage:(CGRect)rectOfImage {
    self = [super init];
    if (self) {
        _content = content;
        _rectOfImage = rectOfImage;
    }
    return self;
}

@end
