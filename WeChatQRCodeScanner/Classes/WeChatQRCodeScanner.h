//
//  WeChatQRCodeScanner.h
//  WeChatQRCodeScanner
//
//  Created by DouDou on 2022/5/10.
//

#import <Foundation/Foundation.h>

//! Project version number for WeChatQRCodeScanner.
FOUNDATION_EXPORT double WeChatQRCodeScannerVersionNumber;

//! Project version string for WeChatQRCodeScanner.
FOUNDATION_EXPORT const unsigned char WeChatQRCodeScannerVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <WeChatQRCodeScanner/PublicHeader.h>

#if __has_include(<WeChatQRCodeScanner_Swift/UIImage+CVMat.h>)

#import <WeChatQRCodeScanner_Swift/UIImage+CVMat.h>

#elif __has_include("UIImage+CVMat.h")

#import "UIImage+CVMat.h"

#endif

#if __has_include(<WeChatQRCodeScanner_Swift/DDBarCodeImageScanner.h>)

#import <WeChatQRCodeScanner_Swift/DDBarCodeImageScanner.h>

#elif __has_include("DDBarCodeImageScanner.h")

#import "DDBarCodeImageScanner.h"

#endif
