//
//  DDQRCodeScannerView.h
//  WeChatQRCodeScanner
//
//  Created by king on 2021/2/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DDQRCodeScannerViewDelegate;
@class DDQRCodeScannerResult;

@interface DDQRCodeScannerView : UIView
@property (nonatomic, weak) id<DDQRCodeScannerViewDelegate> delegate;

- (void)startScanner:(NSError **)error;

- (void)stopScanner;
@end

@protocol DDQRCodeScannerViewDelegate <NSObject>

@required
- (BOOL)qrcodeScannerView:(DDQRCodeScannerView *)scannerView didScanner:(NSArray<DDQRCodeScannerResult *> *)results elapsedTime:(NSTimeInterval)elapsedTime;
@end
NS_ASSUME_NONNULL_END

