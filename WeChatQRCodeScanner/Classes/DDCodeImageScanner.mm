//
//  DDCodeImageScanner.m
//  WeChatQRCodeScanner
//
//  Created by king on 2021/2/3.
//

#import "DDCodeImageScanner.h"
#import <opencv2/Mat.h>
#import <opencv2/WeChatQRCode.h>
#import <opencv2/core/hal/interface.h>

@interface DDCodeImageScanner ()

@property (nonatomic, strong) WeChatQRCode *wechatDetector;

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
    if (detector_prototxt_path && detector_caffe_model_path && super_resolution_prototxt_path && super_resolution_caffe_model_path) {
        _detector = cv::makePtr<cv::wechat_qrcode::WeChatQRCode>(detector_prototxt_path.UTF8String,
                                                                 detector_caffe_model_path.UTF8String,
                                                                 super_resolution_prototxt_path.UTF8String,
                                                                 super_resolution_caffe_model_path.UTF8String);
        _wechatDetector = [[WeChatQRCode alloc] initWithDetector_prototxt_path:detector_prototxt_path
                                                     detector_caffe_model_path:detector_caffe_model_path
                                                super_resolution_prototxt_path:super_resolution_prototxt_path
                                             super_resolution_caffe_model_path:super_resolution_caffe_model_path];
    }
    
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

void UIImageToMat(const UIImage* image, cv::Mat& m, bool alphaExist) {
    CGImageRef imageRef = image.CGImage;
    CGImageToMat(imageRef, m, alphaExist);
}

void CGImageToMat(const CGImageRef image, cv::Mat& m, bool alphaExist) {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image);
    CGFloat cols = CGImageGetWidth(image), rows = CGImageGetHeight(image);
    CGContextRef contextRef;
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
    if (CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelMonochrome)
    {
        m.create(rows, cols, CV_8UC1); // 8 bits per component, 1 channel
        bitmapInfo = kCGImageAlphaNone;
        if (!alphaExist)
            bitmapInfo = kCGImageAlphaNone;
        else
            m = cv::Scalar(0);
        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8,
                                           m.step[0], colorSpace,
                                           bitmapInfo);
    }
    else if (CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelIndexed)
    {
        // CGBitmapContextCreate() does not support indexed color spaces.
        colorSpace = CGColorSpaceCreateDeviceRGB();
        m.create(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
        if (!alphaExist)
            bitmapInfo = kCGImageAlphaNoneSkipLast |
                                kCGBitmapByteOrderDefault;
        else
            m = cv::Scalar(0);
        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8,
                                           m.step[0], colorSpace,
                                           bitmapInfo);
        CGColorSpaceRelease(colorSpace);
    }
    else
    {
        m.create(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
        if (!alphaExist)
            bitmapInfo = kCGImageAlphaNoneSkipLast |
                                kCGBitmapByteOrderDefault;
        else
            m = cv::Scalar(0);
        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8,
                                           m.step[0], colorSpace,
                                           bitmapInfo);
    }
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows),
                       image);
    CGContextRelease(contextRef);
}

- (NSArray<DDQRCodeResult *> *)scanForImage:(UIImage *)image {
    if (!image) {
        return nil;
    }
    cv::Mat cvMat;
    UIImageToMat(image, cvMat, false);
    NSMutableArray<DDQRCodeResult *> *results = [self scanForCvMat:cvMat];
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
    
    auto mat = cv::Mat(h, w, CV_8UC4, imgBufAddr, 0);
    
    cv::Mat transMat;
    cv::transpose(mat, transMat);
    
    cv::Mat flipMat;
    cv::flip(transMat, flipMat, 1);
    
    CVPixelBufferUnlockBaseAddress(imgBuf, 0);

    NSMutableArray<DDQRCodeResult *> *results = [self scanForCvMat:flipMat];
    transMat.release();
    flipMat.release();
    mat.release();
    
    return results;
}

- (NSArray<DDQRCodeResult *> *)scanForCvMat:(cv::Mat)cvMat{
    NSMutableArray<DDQRCodeResult *> *results = nil;
    try {
        if (cvMat.empty()) {
            throw std::runtime_error("cvMat is empty");
        }
        
        std::vector<cv::Mat> points;
        std::vector<std::string> res = self.detector->detectAndDecode(cvMat, points);
        
        if (!res.empty()) {
            results = [NSMutableArray<DDQRCodeResult *> arrayWithCapacity:res.size()];
            for (size_t i = 0; i < res.size(); i++) {
                NSString *content = [NSString stringWithCString:res[i].c_str() encoding:NSUTF8StringEncoding];
                auto &m = points[i];
                
                CGPoint topLeft = CGPointMake(m.at<float>(0, 0), m.at<float>(0, 1));
                CGPoint topRight = CGPointMake(m.at<float>(1, 0), m.at<float>(1, 1));
                CGPoint bottomLeft = CGPointMake(m.at<float>(2, 0), m.at<float>(2, 1));
                CGPoint bottomRight = CGPointMake(m.at<float>(3, 0), m.at<float>(3, 1));
                
                NSLog(@"%@, %@, %@, %@", NSStringFromCGPoint(topLeft), NSStringFromCGPoint(topRight), NSStringFromCGPoint(bottomLeft), NSStringFromCGPoint(bottomRight));
                
                CGRect rectOfImage = CGRectMake(topLeft.x, topLeft.y, topRight.x - topLeft.x, bottomLeft.y - topLeft.y);
                [results addObject:[[DDQRCodeResult alloc] initWithContent:content rectOfImage:rectOfImage]];
                
                // 释放资源
                m.release();
            }
        }
        // 清理资源
        points.clear();
        res.clear();
    } catch (const std::exception &e) {
        NSLog(@"Exception caught: %s", e.what());
    }
    return results;
}

- (NSArray<DDQRCodeResult *> *)scanForMat:(Mat *)mat{
    if (!mat) {
        return nil;
    }
    NSMutableArray *points = [NSMutableArray array];
    NSArray *datas = [_wechatDetector detectAndDecode:mat points:points];
    if (datas.count == 0) {
        return nil;
    }
    NSMutableArray<DDQRCodeResult *> *results = [NSMutableArray arrayWithCapacity:datas.count];
    for (int i = 0; i < datas.count; i++) {
        Mat *point = points[i];
        NSString *content = datas[i];
        CGPoint topLeft    = CGPointMake([[point get:0 col:0] firstObject].doubleValue, [[point get:0 col:1] firstObject].doubleValue);
        CGPoint topRight   = CGPointMake([[point get:1 col:0] firstObject].doubleValue, [[point get:1 col:1] firstObject].doubleValue);
        CGPoint bottomLeft = CGPointMake([[point get:2 col:0] firstObject].doubleValue, [[point get:2 col:1] firstObject].doubleValue);
        CGPoint bottomRight = CGPointMake([[point get:3 col:0] firstObject].doubleValue, [[point get:3 col:1] firstObject].doubleValue);
        NSLog(@"%@, %@, %@, %@", NSStringFromCGPoint(topLeft), NSStringFromCGPoint(topRight), NSStringFromCGPoint(bottomLeft), NSStringFromCGPoint(bottomRight));
        CGRect rectOfImage = (CGRect){topLeft, CGSizeMake(topRight.x - topLeft.x, bottomLeft.y - topLeft.y)};
        [results addObject:[[DDQRCodeResult alloc] initWithContent:content rectOfImage:rectOfImage]];
    }
    return results;
}

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
