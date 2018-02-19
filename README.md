# Recognizr
Quadrilateral recognition using the OpenCV C++ Library. Uses perspective warping to map an image to the detected shape.

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