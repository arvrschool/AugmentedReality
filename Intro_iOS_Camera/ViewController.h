//
//  ViewController.h
//  openCViOSFaceTrackingTutorial
//
//  Created by Evangelos Georgiou on 16/03/2013.
//  Copyright (c) 2013 Evangelos Georgiou. All rights reserved.
//

#import <UIKit/UIKit.h>

#include <opencv2/opencv.hpp> 
#include <opencv2/highgui/cap_ios.h>
#include <opencv2/objdetect/objdetect.hpp>
#include <opencv2/imgproc/imgproc_c.h>

using namespace cv;

@interface ViewController : UIViewController<CvVideoCameraDelegate>
{
    IBOutlet UIImageView* imageView;
    
    CvVideoCamera* videoCamera;
    CascadeClassifier faceCascade;
}

@property (nonatomic, retain) CvVideoCamera* videoCamera;

- (IBAction)startCamera:(id)sender;
- (IBAction)stopCamera:(id)sender;

@end
