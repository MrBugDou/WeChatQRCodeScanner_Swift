//
//  DDQRCodeScannerResult.m
//  WeChatQRCodeScanner
//
//  Created by king on 2021/2/3.
//

#import "DDQRCodeScannerResult.h"

@interface DDQRCodeScannerResult ()
/// 识别的内容
@property (nonatomic, copy) NSString *content;
/// 二维码区域 基于原始图像坐标区域
@property (nonatomic, assign) CGRect rectOfImage;
/// 二维码区域 基于当前扫描容器View坐标系区域
@property (nonatomic, assign) CGRect rectOfView;
@end

@implementation DDQRCodeScannerResult

- (instancetype)initWithContent:(NSString *)content rectOfImage:(CGRect)rectOfImage rectOfView:(CGRect)rectOfView {
	if (self == [super init]) {
		_content     = content;
		_rectOfImage = rectOfImage;
		_rectOfView  = rectOfView;
	}
	return self;
}

- (NSString *)description{
    return [NSString stringWithFormat:@"content = %@, rectOfImage = %@, rectOfView = %@",_content,NSStringFromCGRect(_rectOfImage),NSStringFromCGRect(_rectOfView)];
}

@end

