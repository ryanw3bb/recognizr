//
//  SquareDetector.m
//  Recognizr
//
//  Created by Ryan on 11/03/2018.
//  Copyright © 2018 Ryan Webb. All rights reserved.
//

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif

#import "SquareDetector.h"

using namespace cv;

@interface SquareDetector()

@property (nonatomic) CGFloat scale;
@property (nonatomic) vector<vector<cv::Point>> squares;
@property (nonatomic) cv::Mat origImage;
@property (nonatomic) cv::Mat warpedImage;
@property (nonatomic) CGFloat screenArea;
@property (nonatomic) CGFloat rows;
@property (nonatomic) CGFloat cols;

@end

@implementation SquareDetector

- (instancetype)initWithCameraView:(UIImageView *)view scale:(CGFloat)scale image:(UIImage*)image
{
    self = [super init];
    
    if (self) {
        self.videoCamera = [[CvVideoCamera alloc] initWithParentView:view];
        self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
        self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
        self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
        self.videoCamera.defaultFPS = 30;
        self.videoCamera.grayscaleMode = YES;
        self.videoCamera.rotateVideo = NO;
        self.videoCamera.delegate = self;
        self.scale = scale;
    }
    
    _screenArea = ([UIScreen mainScreen].bounds.size.width - 50) * ([UIScreen mainScreen].bounds.size.width - 50);
    _rows = view.bounds.size.height;
    _cols = view.bounds.size.width;
    
    _origImage = [CVImageTools cvMatFromUIImage:image rows:_rows cols:_cols];
    
    return self;
}

- (void)startCapture
{
    [self.videoCamera start];
}

- (void)stopCapture;
{
    [self.videoCamera stop];
}

// called every frame through CvVideoCameraDelegate
- (void)processImage:(cv::Mat&)image
{
    [self findSquaresInImage:image scale:_scale];
}

// calculate the angle between 2 points (used in square detection)
double angle(cv::Point pt1, cv::Point pt2, cv::Point pt0)
{
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

- (NSArray *)detectedSquares
{
    // function called from MainViewController.m, returns an Array
    NSMutableArray * squareRect = [NSMutableArray array];
    float largestRectArea = 0;

    for(int i = 0; i < _squares.size(); i++)
    {
        cv::Rect rect = boundingRect(cv::Mat(_squares[i]));
        float size = rect.width * rect.height;
        if(size < _screenArea && size > largestRectArea)
        {
            if([squareRect count] != 0)
            {
                [squareRect removeAllObjects];
            }
            
            largestRectArea = rect.width * rect.height;
            
            for(int j = 0; j < 4; j++)
            {
                CGPoint p = CGPointMake(_squares[i][j].x/180.0, _squares[i][j].y/320.0);
                [squareRect addObject:[NSValue valueWithCGPoint:p]];
            }
        }
    }
    
    if(squareRect != nil && squareRect.count >= 4)
    {
        CGPoint centrePoint = CGPointMake(([squareRect[0] CGPointValue].x + [squareRect[1] CGPointValue].x + [squareRect[2] CGPointValue].x + [squareRect[3] CGPointValue].x) / 4.0, ([squareRect[0] CGPointValue].y + [squareRect[1] CGPointValue].y + [squareRect[2] CGPointValue].y + [squareRect[3] CGPointValue].y) / 4.0);
        
        NSMutableArray * orderedSquareRect = [NSMutableArray array];
        for(int i = 0; i < 4; i++)
        {
            [orderedSquareRect addObject:[NSValue valueWithCGPoint:CGPointMake(0, 0)]];
        }
        
        for(int j = 0; j < 4; j++)
        {
            if([squareRect[j] CGPointValue].x < centrePoint.x && [squareRect[j] CGPointValue].y < centrePoint.y)
            {
                orderedSquareRect[0] = squareRect[j];
            }
            else if([squareRect[j] CGPointValue].x > centrePoint.x && [squareRect[j] CGPointValue].y < centrePoint.y)
            {
                 orderedSquareRect[1] = squareRect[j];
            }
            else if([squareRect[j] CGPointValue].x > centrePoint.x && [squareRect[j] CGPointValue].y > centrePoint.y)
            {
                 orderedSquareRect[2] = squareRect[j];
            }
            else if([squareRect[j] CGPointValue].x < centrePoint.x && [squareRect[j] CGPointValue].y > centrePoint.y)
            {
                 orderedSquareRect[3] = squareRect[j];
            }
        }
        
        Point2f pts_src[4];
        Point2f pts_dst[4];
        
        // The 4 points that select quadilateral on the input , from top-left in clockwise order
        // These four pts are the sides of the rect box used as input
        pts_dst[0] = Point2f([orderedSquareRect[0] CGPointValue].x * _cols, [orderedSquareRect[0]  CGPointValue].y * _rows);
        pts_dst[1] = Point2f([orderedSquareRect[1] CGPointValue].x * _cols, [orderedSquareRect[1]  CGPointValue].y * _rows);
        pts_dst[2] = Point2f([orderedSquareRect[2] CGPointValue].x * _cols, [orderedSquareRect[2]  CGPointValue].y * _rows);
        pts_dst[3] = Point2f([orderedSquareRect[3] CGPointValue].x * _cols, [orderedSquareRect[3]  CGPointValue].y * _rows);
        
        pts_src[0] = Point2f(0,0);
        pts_src[1] = Point2f(_origImage.cols-1,0);
        pts_src[2] = Point2f(_origImage.cols-1,_origImage.rows-1);
        pts_src[3] = Point2f(0,_origImage.rows-1 );
        
        _warpedImage = [CVImageTools warpCVMat:_origImage src:pts_src dst:pts_dst];
        self.finalImage = [CVImageTools UIImageFromCVMat:_warpedImage];
        
        return orderedSquareRect;
    }
    
    return squareRect;
}

- (void)findSquaresInImage:(Mat&)img scale:(double)scale
{
    std::vector<std::vector<cv::Point>> sqrs;
    
    // resize img using pyrDown - used twice here so will be sampling at 360x180 (capture session is at 1280x720)
    cv::Mat half, quarter;
    pyrDown(img, half, cv::Size(img.cols/2, img.rows/2));
    pyrDown(half, quarter, cv::Size(half.cols/2, half.rows/2));
    
    // blur - dilate - erode, get some nice averaging going
    cv::Mat blurred(quarter);
    medianBlur(quarter, blurred, 9);
    dilate(blurred, blurred, Mat(), cv::Point(-1,-1));
    erode(blurred, blurred, Mat(), cv::Point(-1,-1));
    
    // Filter the image to black/white (CV_THRESH_BINARY), threshold computed by the Otsu algorithm (CV_THRESH_OTSU)
    threshold(blurred, blurred, 0, 255, CV_THRESH_BINARY | CV_THRESH_OTSU);
    
    // Use Canny edge detector to output edges only
    Canny(blurred, blurred, 10, 20, 3);
    
    // dilate again to help remove holes between edge segments
    dilate(blurred, quarter, Mat(), cv::Point(-1,-1));
        
    // Find contours
    vector<vector<cv::Point>> contours;
    findContours(quarter, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
    
    // Test contours
    vector<cv::Point> approx;
    for(size_t i = 0; i < contours.size(); i++)
    {
        // approximate contour with accuracy proportional to the contour perimeter
        approxPolyDP(Mat(contours[i]), approx, arcLength(Mat(contours[i]), true)*0.02, true);
        
        // Absolute value of an area is used because area may be positive or
        // negative - in accordance with the contour orientation
        if(approx.size() == 4 &&
            fabs(contourArea(Mat(approx))) > 1000 &&
            isContourConvex(Mat(approx)))
        {
            double maxCosine = 0;
            
            for (int j = 2; j < 5; j++)
            {
                double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                maxCosine = MAX(maxCosine, cosine);
            }
            
            if (maxCosine < 0.3)
            {
                sqrs.push_back(approx);
            }
        }
    }
    
    @synchronized(self) {
        self->_squares = sqrs;
    }
}

@end
