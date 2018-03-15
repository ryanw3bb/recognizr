//
//  ImageTools.h
//  Recognizr
//
//  Created by Ryan on 11/03/2018.
//  Copyright © 2018 Ryan Webb. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <UIKit/UIKit.h>

@interface CVImageTools : NSObject

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image rows:(CGFloat)rows cols:(CGFloat)cols;
+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat;
+ (cv::Mat)warpCVMat:(cv::Mat)input src:(cv::Point2f[])src_pts dst:(cv::Point2f[])dst_pts;

@end
