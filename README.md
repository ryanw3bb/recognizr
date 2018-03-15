# Recognizr

Quadrilateral recognition on iOS devices using the OpenCV C++ Library. Uses perspective warping to map an image to the detected shape.

![img](http://ryanwebb.com/images/recognizrr.jpg)

## Setup
First make sure you have CocoaPods installed then add OpenCV to your Podfile:
```
target ‘MyApp’ do
  pod 'OpenCV', '~> 2.4'
end
```
Then simply run the following to install:
```
pod install
```

## CV Method
* Resize CvVideoCameraDelegate output image to quarter size using pyrDown
* Blur, dilate and then erode to average and remove noise
* Filter to binary black/white (CV_THRESH_BINARY), compute threshold using Otsu algorithm (CV_THRESH_OTSU)
* Use Canny edge detector to output edges only
* Find contours
* Construct quads from contours using minimum angle threshold

Dog image from Unsplash.
https://unsplash.com/photos/pgUbpDLJh3E