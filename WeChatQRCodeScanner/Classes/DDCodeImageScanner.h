//
//  DDCodeImageScanner.h
//  WeChatQRCodeScanner
//
//  Created by king on 2021/2/3.
//

#import <opencv2/Mat.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DDQRCodeResult : NSObject

@property (nonatomic, strong) NSString *content;
@property (nonatomic) CGRect rectOfImage;

- (instancetype)initWithContent:(NSString *)content rectOfImage:(CGRect)rectOfImage;

@end

@interface DDCodeImageScanner: NSObject

+ (instancetype)shared;

- (NSArray<DDQRCodeResult *> *)scanForImage:(UIImage *)image;

- (NSArray<DDQRCodeResult *> *)scanForImageBuf:(CVImageBufferRef)imgBuf;

@end

NS_ASSUME_NONNULL_END

