//
//  ViewController.m
//  openCViOSFaceTrackingTutorial
//
//  Created by Evangelos Georgiou on 16/03/2013.
//  Copyright (c) 2013 Evangelos Georgiou. All rights reserved.
//

#include <opencv2/opencv.hpp>
#include <opencv2/nonfree/features2d.hpp>

#define CHESSBOARD_WIDTH 6
#define CHESSBOARD_HEIGHT 5

#include "ViewController.h"

#define COLORS_C 9
#define LABEL_TOTAL 7
#define PER_LABEL 5

int colors[COLORS_C][3] = {{255,255,255}, {0,0,255}, {0,255,0}, {255,0,0}, {0,128,255}, {0,255,255}, {255,0,255}, {255,255,0}, {0,0,0}};
std::string flagname[LABEL_TOTAL] = {"kosovo", "france", "brazil", "china", "germany", "usa", "albania"};

int color_index(Point3_<uchar>* p){
    double distance = DBL_MAX;
    int min_idx = 0;
    for(int i=0; i<COLORS_C; i++){
        int b = p->x;
        int g = p->y;
        int r = p->z;
        
        double dist = std::sqrt(std::pow(0.114*(colors[i][0] - b),2) + std::pow(0.587*(colors[i][1] - g),2) + std::pow((colors[i][2] - r)*0.299,2));
        if(dist < distance){
            distance = dist;
            min_idx = i;
        }
    }
    return min_idx;
}

@interface ViewController (){
    Mat display[2];
    vector<cv::Point2f> src[2];			// Source Points basically the 4 end co-ordinates of the overlay image
    vector<cv::Point2f> dst;			// Destination Points to transform overlay image
    Mat lastImg;
    
    Mat imgs[3];
    cv::Mat siftDescriptors[3];
    std::vector<cv::KeyPoint> keypoints[3];
    
    cv::BriefDescriptorExtractor extractor;
    int flag;
    
    CvSVM SVM;
}
@end

@implementation ViewController

@synthesize videoCamera;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height)];
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:imageView];
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = NO;
    self.videoCamera.delegate = self;
    
    UIImage *image = [UIImage imageNamed:@"newborn.jpg"];
    display[0] = [self cvMatFromUIImage:image];
    
    UIImage *image1 = [UIImage imageNamed:@"chinese.jpg"];
    display[1] = [self cvMatFromUIImage:image1];
    
    for(int i=0; i<2;i++){
        src[i].push_back(cv::Point2f(0,0));
        src[i].push_back(cv::Point2f(display[i].cols,0));
        src[i].push_back(cv::Point2f(display[i].cols, display[i].rows));
        src[i].push_back(cv::Point2f(0, display[i].rows));
    }
    
    UIImage *img0 = [UIImage imageNamed:@"kosovo.png"];
    imgs[0] = [self cvMatFromUIImage:img0];
    cvtColor(imgs[0], imgs[0], CV_BGR2GRAY);
    
    UIImage *img1 = [UIImage imageNamed:@"china.png"];
    imgs[1] = [self cvMatFromUIImage:img1];
    cvtColor(imgs[1], imgs[1], CV_BGR2GRAY);

    
    for(int i=0; i<2;i++){
        cv::FAST(imgs[i], keypoints[i], 9);
    }
    
    
    std::cout << "SIFTS" << std::endl;
    for(int i=0; i<2; i++){
        extractor.compute(imgs[i], keypoints[i], siftDescriptors[i]);
        std::cout << siftDescriptors[i].size() << std::endl;
        cv::KeyPointsFilter::retainBest(keypoints[i], 120);
        std::cout << keypoints[i].size() << std::endl;
    }
    flag = -1;
    
    SVM.load("trainedSVM");
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Protocol CvVideoCameraDelegate

#ifdef __cplusplus
- (void)processImage:(Mat&)img;
{
    cv::Size board_size(CHESSBOARD_WIDTH-1, CHESSBOARD_HEIGHT-1);

    vector<cv::Point2f> corners;
    
    Mat cpy_img(img.rows, img.cols, img.type());
    Mat neg_img(img.rows, img.cols, img.type());
    Mat gray;
    Mat blurred;
    
    cvtColor(img, gray, CV_BGR2GRAY);
    
    bool found = false;
    
    
    
    if(dst.size() == 0){
//        cv::resize(gray, blurred, cv::Size(0,0), 0.3, 0.5);
        cv::bilateralFilter(gray, blurred, 5, 20, 20);
        int lowThreshold = 50;
        int ratio = 3;
        cv::Canny( blurred, blurred, lowThreshold, lowThreshold*ratio, 3 );
//        
//        std::vector<cv::Vec4i> lines;
//        std::map<std::pair<int,int>, int> frequency;
//        
//        HoughLinesP(blurred, lines, 1, CV_PI/180, 70, 30, 10);
//        for (int i = 0; i < lines.size(); i++)
//        {
//            for (int j = i+1; j < lines.size(); j++)
//            {
//                cv::Point2f pt = computeIntersect(lines[i], lines[j]);
//                if (pt.x >= 0 && pt.y >= 0){
//                    corners.push_back(pt);
//                    auto pair = std::make_pair(pt.x, pt.y);
//                    if(frequency)
//                    frequency.insert(std::make_pair()
//                }
//            }
//        }
//        
//        for(int i=0; i< corners.size(); i++){
//            circle(img, corners[i], 5, cv::Scalar(0,255,0));
//        }
//
        
        
        // Find contours
        std::vector<std::vector<cv::Point> > contours;
        cv::findContours(blurred, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
        
        std::vector<cv::Point> approx;
        
        
        for (int i = 0; i < contours.size(); i++)
        {
            // Approximate contour with accuracy proportional
            // to the contour perimeter
            cv::approxPolyDP(cv::Mat(contours[i]), approx, cv::arcLength(cv::Mat(contours[i]), true)*0.02, true);
            
            // Skip small or non-convex objects
            if (std::fabs(cv::contourArea(contours[i])) < 8000 || !cv::isContourConvex(approx))
                continue;
            

            if(approx.size() == 4){
                convexHull( Mat(approx), approx, true );
                for(int j=0;j<4;j++){
                    cv::circle(img, approx[j], 5, Scalar(255,0,0));
                    dst.push_back(cv::Point2f(approx[j].x,approx[j].y));
                }
                
                float color_per_img[COLORS_C] = {0};
                for(int r=0; r<img.rows; r++){
                    for(int c=0;c<img.cols; c++){
                        Point3_<uchar>* p = img.ptr<Point3_<uchar> >(r,c);
                        int ind = color_index(p);
                        color_per_img[ind]++;
                    }
                }
                for(int r=0;r<COLORS_C;r++){
                    color_per_img[r] /= img.rows*img.cols;
                    color_per_img[r] *=100;
                    std::cout << color_per_img[r] << std::endl;
                }
                
                Mat test(COLORS_C, 1, CV_32FC1, color_per_img);
                int nation = (int)SVM.predict(test);
                Mat sbImg = gray(cv::boundingRect(contours[i]));
                
                cv::SiftFeatureDetector detector = cv::SiftFeatureDetector(40);
                std::vector<cv::KeyPoint> keypoint;
                cv::Mat siftDescriptor;
                
                cv::FAST(sbImg, keypoint,9);
                extractor.compute(sbImg, keypoint, siftDescriptor);
                std::cout << siftDescriptor.size() << std::endl;
                
                cv::BFMatcher matcher(cv::NORM_L2, true);
                unsigned long maxMatches = 0;
                std::cout << "Matches " << maxMatches << std::endl;
                
                //iterate only once (leaving the code so that one can easily change it to iterate to other values)
                for(int k=nation; k<nation+1;k++){
                    std::vector< cv::DMatch > matches;
                    matcher.match(siftDescriptor, siftDescriptors[k], matches );
                    
                    if(matches.size() > (keypoints[k].size() < 70 ? (keypoints[k].size()*0.45) : keypoints[k].size()*0.4)){
                        std::cout << "Matches " << matches.size() << std::endl;
                        maxMatches = matches.size();
                        found = true;
                        flag = k;
                        break;
                    }
                }
                std::cout << "Matches Final " << maxMatches << std::endl;
                if(!found){
                    dst.clear();
                }
            }
        }
    }else{
        vector<uchar> status;
        Mat error;
        cv::calcOpticalFlowPyrLK(lastImg, gray, dst, corners, status, error);
        dst.clear();
        
        found = true;
        
        for(int i=0; i<status.size();i++){
            if(status[i] == 0){
                found = false;
                break;
            }
        }
        
        if(found){
            dst = corners;
        }
    }
    
    if(found){
        
        
        // Compute the transformation matrix,
        // i.e., transformation required to overlay the display image from 'src' points to 'dst' points on the image
        
        std::cout << "FLAG " << flag << std::endl;
        Mat blank(display[flag].rows, display[flag].cols, display[flag].type());
        
        Mat warp_matrix = getPerspectiveTransform(src[flag], dst);
        
        blank = cv::Scalar(0);
        neg_img = cv::Scalar(0);								// Image is white when pixel values are zero
        cpy_img = cv::Scalar(0);								// Image is white when pixel values are zero
        
        bitwise_not(blank,blank);
        
        warpPerspective(display[flag], neg_img, warp_matrix, cv::Size(neg_img.cols, neg_img.rows));	// Transform overlay Image to the position	- [ITEM1]
        warpPerspective(blank, cpy_img, warp_matrix, cv::Size(cpy_img.cols, neg_img.rows));		// Transform a blank overlay image to position
        bitwise_not(cpy_img, cpy_img);							// Invert the copy paper image from white to black
        bitwise_and(cpy_img, img, cpy_img);						// Create a "hole" in the Image to create a "clipping" mask - [ITEM2]
        bitwise_or(cpy_img, neg_img, img);						// Finally merge both items [ITEM1 & ITEM2]
    }

    lastImg = gray;
//    img = blurred;
    
}
#endif

double angle(cv::Point pt1, cv::Point pt2, cv::Point pt0)
{
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

cv::Point2f computeIntersect(cv::Vec4i a, cv::Vec4i b)
{
    int x1 = a[0], y1 = a[1], x2 = a[2], y2 = a[3];
    int x3 = b[0], y3 = b[1], x4 = b[2], y4 = b[3];
    
    if (float d = ((float)(x1-x2) * (y3-y4)) - ((y1-y2) * (x3-x4)))
    {
        cv::Point2f pt;
        pt.x = ((x1*y2 - y1*x2) * (x3-x4) - (x1-x2) * (x3*y4 - y3*x4)) / d;
        pt.y = ((x1*y2 - y1*x2) * (y3-y4) - (y1-y2) * (x3*y4 - y3*x4)) / d;
        return pt;
    }
    else
        return cv::Point2f(-1, -1);
}

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

#pragma mark - UI Actions

- (IBAction)startCamera:(id)sender
{
    [self.videoCamera start];
}

- (IBAction)stopCamera:(id)sender
{
    [self.videoCamera stop];
}

@end
