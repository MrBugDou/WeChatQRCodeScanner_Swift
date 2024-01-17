//
//  Mat+DDExtra.h
//  WeChatQRCodeScanner
//
//  Created by king on 2021/2/3.
//

#import <opencv2/Mat.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Mat (DDExtra)

@property(nonatomic, assign, readonly) CGRect rectOfImage;

- (NSArray<NSNumber *> *)valueAtRow:(NSInteger)row column:(NSInteger)col;

@end

NS_ASSUME_NONNULL_END

