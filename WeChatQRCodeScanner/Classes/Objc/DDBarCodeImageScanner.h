//
//  BarCodeImageScanner.h
//  Pods
//
//  Created by king on 2021/2/26.
//

#import <opencv2/Mat.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class DDQRCodeScannerResult;
@class UIImage;

@interface DDBarCodeImageScanner : NSObject

- (NSArray<DDQRCodeScannerResult *> *)scannerForImage:(UIImage *)image;

+ (Mat *)matFromImage:(UIImage *)image;
+ (Mat *)matGrayFromImage:(UIImage *)image;
+ (UIImage *)imageFromMat:(Mat *)mat;

@end

NS_ASSUME_NONNULL_END

