//
//  ImageTools.mm
//  Recognizr
//
//  Created by Ryan on 11/03/2018.
//  Copyright © 2018 Ryan Webb. All rights reserved.
//

#import "CVImageTools.h"

using namespace cv;

@implementation CVImageTools : NSObject

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image rows:(CGFloat)rows cols:(CGFloat)cols
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    
    cv::Mat cvMat(rows, cols, CV_8UC4);
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,
                                                    cols,
                                                    rows,
                                                    8,
                                                    cvMat.step[0],
                                                    colorSpace,
                                                    kCGImageAlphaPremultipliedLast |
                                                    kCGBitmapByteOrderDefault);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,
                                        cvMat.rows,
                                        8,
                                        8 * cvMat.elemSize(),
                                        cvMat.step[0],
                                        colorSpace,
                                        kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault,
                                        provider,
                                        NULL,
                                        false,
                                        kCGRenderingIntentDefault);
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

+ (cv::Mat)warpCVMat:(cv::Mat)input src:(Point2f[])src_pts dst:(Point2f[])dst_pts
{
    cv::Mat output;
    cv::Mat lambda( 2, 4, CV_32FC1 );
    
    lambda = Mat::zeros( input.rows, input.cols, input.type() );
    lambda = getPerspectiveTransform( src_pts, dst_pts );
    
    warpPerspective(input, output, lambda, output.size(), NULL, BORDER_TRANSPARENT);
    
    return output;
}

@end
