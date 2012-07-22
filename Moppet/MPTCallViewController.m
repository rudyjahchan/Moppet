#import "MPTCallViewController.h"

@interface MPTCallViewController ()

@property (nonatomic, strong) CIDetector* dectector;
@property (nonatomic, strong) NSOperationQueue* detectionQueue;
@property (nonatomic, strong) UIView* subscriberView;
@property (nonatomic, strong) UIView* realImageView;
@property (nonatomic, strong) UIButton* callButton;
@property (nonatomic, strong) UIButton* hangupButton;
@property (nonatomic, strong) UILabel* callLabel;
@property (nonatomic, strong) OTSession* session;
@property (nonatomic, strong) OTPublisher* publisher;
@property (nonatomic, strong) OTSubscriber* subscriber;
@property (nonatomic, strong) OTStream* callingStream;

- (void) connect;
- (void) disconnect;
- (void) callOut;

@end

@implementation MPTCallViewController

static NSString* const kApiKey = @"16747402";
static NSString* const kToken = @"devtoken";
static NSString* const kSessionId = @"2_MX4xNjc0NzQwMn5-MjAxMi0wNy0yMiAxOTozMTo0NS4xMTI5MjArMDA6MDB-MC4yNjg2NTIzNzg2MTJ-";

@synthesize dectector;
@synthesize subscriberView;
@synthesize detectionQueue;
@synthesize realImageView;
@synthesize callButton;
@synthesize hangupButton;
@synthesize callLabel;
@synthesize session;
@synthesize publisher;
@synthesize subscriber;
@synthesize callingStream;

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];

  CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
  self.callButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  callButton.frame = CGRectMake(20, applicationFrame.size.height - 92, applicationFrame.size.width - 40, 32);
  [callButton setTitle:@"Call" forState:UIControlStateNormal];
  [callButton addTarget:self
                     action:@selector(callButtonTapped:)
           forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:callButton];    
  
  self.hangupButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  hangupButton.frame = CGRectMake(20, applicationFrame.size.height - 52, applicationFrame.size.width - 40, 32);
  [hangupButton setTitle:@"Hangup" forState:UIControlStateNormal];
  [hangupButton addTarget:self
                       action:@selector(hangupButtonTapped:)
             forControlEvents:UIControlEventTouchUpInside];
  hangupButton.hidden = YES;
  [self.view addSubview:hangupButton];
  
  self.callLabel = [[UILabel alloc] init];
  callLabel.frame = CGRectMake(20, applicationFrame.size.height - 120, 240, 24);
  callLabel.backgroundColor = [UIColor clearColor];
  callLabel.textColor = [UIColor lightGrayColor];
  [self.view addSubview:callLabel];
}

- (void)callButtonTapped:(UIButton*)button
{
  callButton.enabled = NO;
  [self callOut];
}

- (void)hangupButtonTapped:(UIButton*)button
{
  hangupButton.enabled = NO;
  hangupButton.hidden = YES;
  if(subscriber) {
    [subscriber close];
  }
  if (publisher) {
    [session unpublish:publisher];
  }
  self.subscriber = nil;
  self.publisher = nil;
}

- (void)viewDidUnload
{
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self connect];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
  [self disconnect];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return interfaceOrientation == UIInterfaceOrientationPortrait;
}

#pragma mark - OpenTok methods

- (void)connect 
{
  self.session = [[OTSession alloc] initWithSessionId:kSessionId
                                         delegate:self];
  [session connectWithApiKey:kApiKey token:kToken];
}

- (void)disconnect 
{
  [self stopFindingFaces];
  [session disconnect];
  self.session = nil;
}

- (void) callOut
{
  self.publisher = [[OTPublisher alloc] initWithDelegate:self name:@"Rudy calling ..."];
  publisher.publishAudio = YES;
  publisher.publishVideo = YES;
  [session publish:publisher];
}

#pragma mark - OTSessionDelegate methods

- (void)sessionDidConnect:(OTSession*)session
{
  callButton.enabled = YES;
  callButton.hidden = NO;
  hangupButton.enabled = NO;
  hangupButton.hidden = YES;
}

- (void)sessionDidDisconnect:(OTSession*)session 
{
  [self stopFindingFaces];
  callButton.enabled = NO;
  hangupButton.hidden = YES;
}

- (void)session:(OTSession*)session didFailWithError:(OTError*)error
{
  [self stopFindingFaces];
  callButton.hidden = NO;
  callButton.enabled = YES;
  hangupButton.hidden = YES;
  hangupButton.enabled = YES;  
}

- (void)session:(OTSession*)mySession didReceiveStream:(OTStream*)stream
{
  if (![stream.connection.connectionId isEqualToString: session.connection.connectionId]) {
    if (!subscriber) {
      self.subscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
      subscriber.subscribeToAudio = YES;
      subscriber.subscribeToVideo = YES;
    }
  }
}

- (void)session:(OTSession*)session didDropStream:(OTStream*)stream
{
  if (subscriber && [subscriber.stream.streamId isEqualToString: stream.streamId]) {
    [self stopFindingFaces];
    self.subscriber = nil;
    callButton.enabled = YES;
    callButton.hidden = NO;
    hangupButton.hidden = YES;
    hangupButton.enabled = NO;
  }
}

#pragma mark - OTPublisherDelegate methods

- (void)publisher:(OTPublisher*)publisher didFailWithError:(OTError*) error
{
  callButton.hidden = NO;
  callButton.enabled = YES;
  hangupButton.enabled = NO;
  hangupButton.hidden = YES;
}

- (void)publisherDidStartStreaming:(OTPublisher *)staringPublisher
{
  [self.view addSubview:staringPublisher.view];
  CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
  staringPublisher.view.frame = CGRectMake(0, 0, applicationFrame.size.width, applicationFrame.size.height - 150);
  callButton.hidden = YES;
  callButton.enabled = NO;
  hangupButton.enabled = YES;
  hangupButton.hidden = NO;
}

-(void)publisherDidStopStreaming:(OTPublisher*)publisher
{
  callButton.hidden = NO;
  callButton.enabled = YES;
  hangupButton.enabled = NO;
  hangupButton.hidden = YES;
}

#pragma mark - OTSubscriberDelegate methods

- (void)subscriberDidConnectToStream:(OTSubscriber*)connectingSubscriber
{
  self.dectector = nil;
  [self.realImageView removeFromSuperview];
  self.realImageView = nil;
  [self.subscriberView removeFromSuperview];
  self.subscriberView = nil;
  [connectingSubscriber.view setFrame:CGRectMake(0, 0, 320, 200)];
  [self.view addSubview:connectingSubscriber.view];
  self.subscriberView = connectingSubscriber.view;
  CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
  self.realImageView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, applicationFrame.size.width, applicationFrame.size.height - 150)];
  realImageView.backgroundColor = [UIColor blackColor];
  [self.view insertSubview:realImageView aboveSubview:subscriberView];
  realImageView.layer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMakeScale(1.0, -1.0));
  realImageView.layer.contentsGravity = kCAGravityResizeAspectFill;
}

- (void)subscriberVideoDataReceived:(OTSubscriber*)subscriber {
  hangupButton.hidden = NO;
  hangupButton.enabled = YES;
  [self startFindingFaces];
}

- (void)subscriber:(OTSubscriber *)subscriber didFailWithError:(OTError *)error
{
  [self stopFindingFaces];
}

- (void)startFindingFaces {
  NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
	self.dectector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
  self.detectionQueue = [[NSOperationQueue alloc] init];
  NSInvocationOperation* detectionOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(findFaces) object:nil];
  [detectionQueue addOperation:detectionOperation];
}

- (void)stopFindingFaces {
  [detectionQueue cancelAllOperations];
}

- (void) findFaces {
  NSLog(@"Finding faces");
  CGContextRef    context = NULL;
  CGColorSpaceRef colorSpace;
  size_t bitmapByteCount;
  size_t bitmapBytesPerRow;
  
  size_t pixelsHigh = (int)subscriberView.layer.bounds.size.height;
  size_t pixelsWide = (int)subscriberView.layer.bounds.size.width;
  
  bitmapBytesPerRow   = (pixelsWide * 4);
  bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
  
  colorSpace = CGColorSpaceCreateDeviceRGB();
  
  context = CGBitmapContextCreate (NULL,
                                   pixelsWide,
                                   pixelsHigh,
                                   8,
                                   bitmapBytesPerRow,
                                   colorSpace,kCGBitmapByteOrder32Little | 
                                   kCGImageAlphaPremultipliedLast);
  if (context== NULL)
    {
    NSLog(@"Failed to create context.");
    return;
    }
  
  [subscriberView.layer renderInContext:context];
  
  CGImageRef img = CGBitmapContextCreateImage(context);
  
  CIImage *image = [CIImage imageWithCGImage:img];
  CFRelease(img);
  CGColorSpaceRelease( colorSpace );
  
  
  NSDictionary* imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:4] forKey:CIDetectorImageOrientation];
  
  NSArray* features = [dectector featuresInImage:image options:imageOptions];
  for(CIFaceFeature* faceFeature in features) {
    NSLog(@"Faces found");
    if(faceFeature.hasLeftEyePosition && faceFeature.hasRightEyePosition) {
      NSLog(@"Found eyes %f, %f and %f, %f)", faceFeature.leftEyePosition.x, faceFeature.leftEyePosition.y,
            faceFeature.rightEyePosition.x, faceFeature.rightEyePosition.y);
      CGFloat width = faceFeature.leftEyePosition.x - faceFeature.rightEyePosition.x;
      if (width < 0) {
        width *= -1.0;
      }
      
      CGFloat height = faceFeature.leftEyePosition.y - faceFeature.rightEyePosition.y;
      if (height < 0) {
        height *= -1.0 ;
      }
      
      CGFloat distance = sqrt(pow(width, 2.0) + pow(height, 2.0))/2.0;
      [self renderEyeOn:context at:faceFeature.leftEyePosition radius:distance];
      [self renderEyeOn:context at:faceFeature.rightEyePosition radius:distance];
    }
  }
  
  // Create a Quartz image from the pixel data in the bitmap graphics context
  CGImageRef quartzImage = CGBitmapContextCreateImage(context); 
  
  // Free up the context and color space
  CGContextRelease(context); 
  
  id renderedImage = CFBridgingRelease(quartzImage);
  
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    [CATransaction setDisableActions:YES];
    [CATransaction begin];
		realImageView.layer.contents = renderedImage;
    [CATransaction commit];
    NSInvocationOperation* detectionOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(findFaces) object:nil];
    [detectionQueue addOperation:detectionOperation];
	});
}

- (void) renderEyeOn:(CGContextRef)context at:(CGPoint) point radius:(CGFloat)radius{
  CGContextSetRGBFillColor(context, 1, 1, 1, 1);
  CGContextBeginPath(context);
  CGContextMoveToPoint(context, point.x, point.y - radius);
  CGContextAddArcToPoint(context, point.x + radius, point.y - radius, 
                         point.x + radius, point.y, radius);
  CGContextAddArcToPoint(context, point.x + radius, point.y + radius, 
                         point.x, point.y + radius, radius);
  CGContextAddArcToPoint(context, point.x - radius, point.y + radius, 
                         point.x - radius, point.y, radius);
  CGContextAddArcToPoint(context, point.x - radius, point.y - radius, 
                         point.x, point.y - radius, radius);
  CGContextClosePath(context);
  CGContextDrawPath(context, kCGPathFill);
  
  CGFloat pupilRadius = radius / 2.0;
  
  CGContextSetRGBFillColor(context, 0, 0, 0, 1);
  CGContextBeginPath(context);
  CGContextMoveToPoint(context, point.x, point.y - pupilRadius);
  CGContextAddArcToPoint(context, point.x + pupilRadius, point.y - pupilRadius, 
                         point.x + pupilRadius, point.y, pupilRadius);
  CGContextAddArcToPoint(context, point.x + pupilRadius, point.y + pupilRadius, 
                         point.x, point.y + pupilRadius, pupilRadius);
  CGContextAddArcToPoint(context, point.x - pupilRadius, point.y + pupilRadius, 
                         point.x - pupilRadius, point.y, pupilRadius);
  CGContextAddArcToPoint(context, point.x - pupilRadius, point.y - pupilRadius, 
                         point.x, point.y - pupilRadius, pupilRadius);
  CGContextClosePath(context);
  CGContextDrawPath(context, kCGPathFill);
}

@end
