//
//  Mat+DDExtra.m
//  WeChatQRCodeScanner
//
//  Created by king on 2021/2/3.
//

#import "Mat+DDExtra.h"

@implementation Mat (DDExtra)

- (NSArray<NSNumber *> *)valueAtRow:(NSInteger)row column:(NSInteger)col{
    NSMutableArray *data = [NSMutableArray array];
    [self get:row col:col data:data];
    if (data.count == 0) {
        [data addObject:@(0)];
    }
    return data;
}

- (CGRect)rectOfImage{
    cv::Mat m = self.nativeRef;
    CGPoint topLeft    = CGPointMake(m.at<float>(0, 0), m.at<float>(0, 1));
    CGPoint topRight   = CGPointMake(m.at<float>(1, 0), m.at<float>(1, 1));
    CGPoint bottomLeft = CGPointMake(m.at<float>(2, 0), m.at<float>(2, 1));
    //            CGPoint bottomRight = CGPointMake(m.at<float>(3, 0), m.at<float>(3, 1));
    CGRect rectOfImage = (CGRect){topLeft, CGSizeMake(topRight.x - topLeft.x, bottomLeft.y - topLeft.y)};
    return rectOfImage;
}

@end

