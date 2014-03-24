#import <FacebookSDK/FacebookSDK.h>
#import "ShareViewController.h"
#import <Twitter/Twitter.h>
#import <Pinterest/Pinterest.h>
#import <Social/Social.h>

//Pinterest Globals
Pinterest*  _pinterest;
#define kMargin             20.0
#define kSampleImageWidth   320.0
#define kSampleImageHeight  200.0

#define kPinItButtonWidth   72.0
#define kPinItButtonHeight  32.0
//End Pinterest Globals

@interface ShareViewController ()
@property (strong, nonatomic) IBOutlet UIButton *ShareLinkWithShareDialogButton;
@property (strong, nonatomic) IBOutlet UIButton *ShareLinkWithAPICallsButton;
@property (strong, nonatomic) IBOutlet UIButton *SharePhotoWithShareDialogButton;
@property (strong, nonatomic) IBOutlet UIButton *StatusUpdateWithShareDialogButton;
@property (strong, nonatomic) IBOutlet UIButton *StatusUpdateWithAPICallsButton;

@end

@implementation ShareViewController


//------------------Login implementation starts here------------------

// Implement the loginViewShowingLoggedInUser: delegate method to modify your app's UI for a logged-in user experience
- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
  // If the user is logged in, they can post to Facebook using API calls, so we show the buttons
  [_ShareLinkWithAPICallsButton setHidden:NO];
  [_StatusUpdateWithAPICallsButton setHidden:NO];
}

// Implement the loginViewShowingLoggedOutUser: delegate method to modify your app's UI for a logged-out user experience
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
  // If the user is NOT logged in, they can't post to Facebook using API calls, so we show the buttons
  [_ShareLinkWithAPICallsButton setHidden:YES];
  [_StatusUpdateWithAPICallsButton setHidden:YES];
}

// You need to override loginView:handleError in order to handle possible errors that can occur during login
- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error {
  NSString *alertMessage, *alertTitle;
  
  // If the user should perform an action outside of you app to recover,
  // the SDK will provide a message for the user, you just need to surface it.
  // This conveniently handles cases like Facebook password change or unverified Facebook accounts.
  if ([FBErrorUtility shouldNotifyUserForError:error]) {
    alertTitle = @"Facebook error";
    alertMessage = [FBErrorUtility userMessageForError:error];
    
    // This code will handle session closures since that happen outside of the app.
    // You can take a look at our error handling guide to know more about it
    // https://developers.facebook.com/docs/ios/errors
  } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession) {
    alertTitle = @"Session Error";
    alertMessage = @"Your current session is no longer valid. Please log in again.";
    
    // This code cancels user sessions
  } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
    NSLog(@"user cancelled login");
    
  } else {
    alertTitle  = @"Something went wrong";
    alertMessage = @"Please try again later.";
    NSLog(@"Unexpected error:%@", error);
  }
  
  if (alertMessage) {
    [[[UIAlertView alloc] initWithTitle:alertTitle
                                message:alertMessage
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
  }
}


//------------------------------------

//------------------Sharing a link using the share dialog------------------
- (IBAction)shareLinkWithShareDialog:(id)sender
{
 
  // Check if the Facebook app is installed and we can present the share dialog
  FBShareDialogParams *params = [[FBShareDialogParams alloc] init];
  params.link = [NSURL URLWithString:@"https://developers.facebook.com/docs/ios/share/"];
  params.name = @"http://i.imgur.com/hJsrBb7.png";
  params.caption = @"http://i.imgur.com/hJsrBb7.png";
  params.picture = [NSURL URLWithString:@"http://i.imgur.com/g3Qc1HN.png"];
  params.description = @"Allow your users to share stories on Facebook from your app using the iOS SDK.";


  // If the Facebook app is installed and we can present the share dialog
  if ([FBDialogs canPresentShareDialogWithParams:params]) {
    
    // Present share dialog
    [FBDialogs presentShareDialogWithLink:params.link
                                     name:params.name
                                  caption:params.caption
                              description:params.description
                                  picture:params.picture
                              clientState:nil
                                  handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                    if(error) {
                                      // An error occurred, we need to handle the error
                                      // See: https://developers.facebook.com/docs/ios/errors
                                      NSLog(@"Error publishing story: %@", error.description);
                                    } else {
                                        // Success
                                        NSLog(@"result %@", results);
                                    }
                                  }];
    
  // If the Facebook app is NOT installed and we can't present the share dialog
  } else {
    // FALLBACK: publish just a link using the Feed dialog
    
    // Put together the dialog parameters
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"Demo", @"name",
                                   @"Outward.", @"caption",
                                   @"Outward.", @"description",
                                   @"https://developers.facebook.com/docs/ios/share/", @"link",
                                   @"http://i.imgur.com/g3Qc1HN.png", @"picture",
                                   nil];
    
    // Show the feed dialog
    [FBWebDialogs presentFeedDialogModallyWithSession:nil
                                           parameters:params
                                              handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                                                if (error) {
                                                  // An error occurred, we need to handle the error
                                                  // See: https://developers.facebook.com/docs/ios/errors
                                                  NSLog(@"Error publishing story: %@", error.description);
                                                } else {
                                                  if (result == FBWebDialogResultDialogNotCompleted) {
                                                    // User canceled.
                                                    NSLog(@"User cancelled.");
                                                  } else {
                                                    // Handle the publish feed callback
                                                    NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                                                    
                                                    if (![urlParams valueForKey:@"post_id"]) {
                                                      // User canceled.
                                                      NSLog(@"User cancelled.");
                                                      
                                                    } else {
                                                      // User clicked the Share button
                                                      NSString *result = [NSString stringWithFormat: @"Posted story, id: %@", [urlParams valueForKey:@"post_id"]];
                                                      NSLog(@"result %@", result);
                                                    }
                                                  }
                                                }
                                              }];
  }
}

//------------------------------------

//------------------Posting a status update using the share dialog------------------
- (IBAction)postStatusUpdateWithShareDialog:(id)sender
{
  
  // Check if the Facebook app is installed and we can present the share dialog
  
  FBShareDialogParams *params = [[FBShareDialogParams alloc] init];
  params.link = [NSURL URLWithString:@"https://developers.facebook.com/docs/ios/share/"];
  
  // If the Facebook app is installed and we can present the share dialog
  if ([FBDialogs canPresentShareDialogWithParams:params]) {
    
    // Present share dialog
    [FBDialogs presentShareDialogWithLink:nil
                                  handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                    if(error) {
                                      // An error occurred, we need to handle the error
                                      // See: https://developers.facebook.com/docs/ios/errors
                                      NSLog(@"Error publishing story: %@", error.description);
                                    } else {
                                      // Success
                                      NSLog(@"result %@", results);
                                    }
                                  }];
    
    // If the Facebook app is NOT installed and we can't present the share dialog
  } else {
    // FALLBACK: publish just a link using the Feed dialog
    // Show the feed dialog
    [FBWebDialogs presentFeedDialogModallyWithSession:nil
                                           parameters:nil
                                              handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                                                if (error) {
                                                  // An error occurred, we need to handle the error
                                                  // See: https://developers.facebook.com/docs/ios/errors
                                                  NSLog(@"Error publishing story: %@", error.description);
                                                } else {
                                                  if (result == FBWebDialogResultDialogNotCompleted) {
                                                    // User cancelled.
                                                    NSLog(@"User cancelled.");
                                                  } else {
                                                    // Handle the publish feed callback
                                                    NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                                                    
                                                    if (![urlParams valueForKey:@"post_id"]) {
                                                      // User cancelled.
                                                      NSLog(@"User cancelled.");
                                                      
                                                    } else {
                                                      // User clicked the Share button
                                                      NSString *result = [NSString stringWithFormat: @"Posted story, id: %@", [urlParams valueForKey:@"post_id"]];
                                                      NSLog(@"result %@", result);
                                                    }
                                                  }
                                                }
                                              }];
  }
}


//------------------------------------

// A function for parsing URL parameters returned by the Feed Dialog.
- (NSDictionary*)parseURLParams:(NSString *)query {
  NSArray *pairs = [query componentsSeparatedByString:@"&"];
  NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
  for (NSString *pair in pairs) {
    NSArray *kv = [pair componentsSeparatedByString:@"="];
    NSString *val =
    [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    params[kv[0]] = val;
  }
  return params;
}

//------------------------------------


//------------------Sharing a photo using the Share Dialog ------------------

- (IBAction)SharePhotoWithShareDialog:(id)sender {
  
  // If the Facebook app is installed and we can present the share dialog
  if([FBDialogs canPresentShareDialogWithPhotos]) {
      NSLog(@"canPresent");
      // Retrieve a picture from the device's photo library
      /*
       NOTE: SDK Image size limits are 480x480px minimum resolution to 12MB maximum file size.
       In this app we're not making sure that our image is within those limits but you should.
       Error code for images that go below or above the size limits is 102.
       */
      UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
      [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
      [imagePicker setDelegate:self];
      [self presentViewController:imagePicker animated:YES completion:nil];
    
  } else {
      //The user doesn't have the Facebook for iOS app installed, so we can't present the Share Dialog
      /*Fallback: You have two options
        1. Share the photo as a Custom Story using a "share a photo" Open Graph action, and publish it using API calls.
           See our Custom Stories tutorial: https://developers.facebook.com/docs/ios/open-graph
        2. Upload the photo making a requestForUploadPhoto
           See the reference: https://developers.facebook.com/docs/reference/ios/current/class/FBRequest/#requestForUploadPhoto:
       */
  }

  
}

// When the user is done picking the image
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  UIImage *img = [info objectForKey:UIImagePickerControllerOriginalImage];
  
  FBShareDialogPhotoParams *params = [[FBShareDialogPhotoParams alloc] init];
  params.photos = @[img];
  
  [FBDialogs presentShareDialogWithPhotoParams:params
                                   clientState:nil
                                       handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                         if (error) {
                                           NSLog(@"Error: %@", error.description);
                                         } else {
                                           NSLog(@"Success!");
                                         }
                                    }];
  
}

//------------------------------------


//------------------Sharing a link using API calls------------------

- (IBAction)ShareLinkWithAPICalls:(id)sender {
  // We will post on behalf of the user, these are the permissions we need:
  NSArray *permissionsNeeded = @[@"publish_actions"];

  // Request the permissions the user currently has
  [FBRequestConnection startWithGraphPath:@"/me/permissions"
                        completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                          if (!error){
                            NSDictionary *currentPermissions= [(NSArray *)[result data] objectAtIndex:0];
                            NSMutableArray *requestPermissions = [[NSMutableArray alloc] initWithArray:@[]];
                            
                            // Check if all the permissions we need are present in the user's current permissions
                            // If they are not present add them to the permissions to be requested
                            for (NSString *permission in permissionsNeeded){
                              if (![currentPermissions objectForKey:permission]){
                                [requestPermissions addObject:permission];
                              }
                            }
                            
                            // If we have permissions to request
                            if ([requestPermissions count] > 0){
                              // Ask for the missing permissions
                              [FBSession.activeSession requestNewPublishPermissions:requestPermissions
                                                                    defaultAudience:FBSessionDefaultAudienceFriends
                                                                  completionHandler:^(FBSession *session, NSError *error) {
                                                                    if (!error) {
                                                                      // Permission granted, we can request the user information
                                                                      [self makeRequestToShareLink];
                                                                    } else {
                                                                      // An error occurred, handle the error
                                                                      // See our Handling Errors guide: https://developers.facebook.com/docs/ios/errors/
                                                                      NSLog(@"%@", error.description);
                                                                    }
                                                                  }];
                            } else {
                              // Permissions are present, we can request the user information
                              [self makeRequestToShareLink];
                            }
                            
                          } else {
                            // There was an error requesting the permission information
                            // See our Handling Errors guide: https://developers.facebook.com/docs/ios/errors/
                            NSLog(@"%@", error.description);
                          }
                        }];
}

- (void)makeRequestToShareLink {
  
  // NOTE: pre-filling fields associated with Facebook posts,
  // unless the user manually generated the content earlier in the workflow of your app,
  // can be against the Platform policies: https://developers.facebook.com/policy

  // Put together the dialog parameters
  NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 @"Demo", @"name",
                                 @"Outward", @"caption",
                                 @"Outward Demo.", @"description",
                                 @"https://developers.facebook.com/docs/ios/share/", @"link",
                                 @"http://i.imgur.com/g3Qc1HN.png", @"picture",
                                 nil];

  // Make the request
  [FBRequestConnection startWithGraphPath:@"/me/feed"
                               parameters:params
                               HTTPMethod:@"POST"
                        completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                          if (!error) {
                            // Link posted successfully to Facebook
                            NSLog(@"result: %@", result);
                          } else {
                            // An error occurred, we need to handle the error
                            // See: https://developers.facebook.com/docs/ios/errors
                            NSLog(@"%@", error.description);
                          }
                        }];
}

//------------------------------------

//------------------Posting a status update using API calls------------------

- (IBAction)StatusUpdateWithAPICalls:(id)sender {
  // We will post on behalf of the user, these are the permissions we need:
  NSArray *permissionsNeeded = @[@"publish_actions"];
  
  // Request the permissions the user currently has
  [FBRequestConnection startWithGraphPath:@"/me/permissions"
                        completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                          if (!error){
                            NSDictionary *currentPermissions= [(NSArray *)[result data] objectAtIndex:0];
                            NSMutableArray *requestPermissions = [[NSMutableArray alloc] initWithArray:@[]];
                            
                            // Check if all the permissions we need are present in the user's current permissions
                            // If they are not present add them to the permissions to be requested
                            for (NSString *permission in permissionsNeeded){
                              if (![currentPermissions objectForKey:permission]){
                                [requestPermissions addObject:permission];
                              }
                            }
                            
                            // If we have permissions to request
                            if ([requestPermissions count] > 0){
                              // Ask for the missing permissions
                              [FBSession.activeSession requestNewPublishPermissions:requestPermissions
                                                                    defaultAudience:FBSessionDefaultAudienceFriends
                                                                  completionHandler:^(FBSession *session, NSError *error) {
                                                                    if (!error) {
                                                                      // Permission granted, we can request the user information
                                                                      [self makeRequestToUpdateStatus];
                                                                    } else {
                                                                      // An error occurred, handle the error
                                                                      // See our Handling Errors guide: https://developers.facebook.com/docs/ios/errors/
                                                                      NSLog(@"%@", error.description);
                                                                    }
                                                                  }];
                            } else {
                              // Permissions are present, we can request the user information
                              [self makeRequestToUpdateStatus];
                            }
                            
                          } else {
                            // There was an error requesting the permission information
                            // See our Handling Errors guide: https://developers.facebook.com/docs/ios/errors/
                            NSLog(@"%@", error.description);
                          }
                        }];
}

- (void)makeRequestToUpdateStatus {
  
  // NOTE: pre-filling fields associated with Facebook posts,
  // unless the user manually generated the content earlier in the workflow of your app,
  // can be against the Platform policies: https://developers.facebook.com/policy

  [FBRequestConnection startForPostStatusUpdate:@"User-generated status update."
                              completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                          if (!error) {
                            // Status update posted successfully to Facebook
                            NSLog(@"result: %@", result);
                          } else {
                            // An error occurred, we need to handle the error
                            // See: https://developers.facebook.com/docs/ios/errors
                            NSLog(@"%@", error.description);
                          }
                        }];
}

- (IBAction)TweetShare:(id)sender {
    {
        //  Create an instance of the Tweet Sheet
        SLComposeViewController *tweetSheet = [SLComposeViewController
                                               composeViewControllerForServiceType:
                                               SLServiceTypeTwitter];
        
        // Sets the completion handler.  Note that we don't know which thread the
        // block will be called on, so we need to ensure that any required UI
        // updates occur on the main queue
        tweetSheet.completionHandler = ^(SLComposeViewControllerResult result) {
            switch(result) {
                    //  This means the user cancelled without sending the Tweet
                case SLComposeViewControllerResultCancelled:
                    break;
                    //  This means the user hit 'Send'
                case SLComposeViewControllerResultDone:
                    break;
            }
        };
        
        //  Set the initial body of the Tweet
        [tweetSheet setInitialText:@"http://i.imgur.com/hJsrBb7.png"];
        
        if (![tweetSheet addImage:[UIImage imageNamed:@"http://i.imgur.com/hJsrBb7.png"]]) {
            NSLog(@"Unable to add the image!");
        }
        
        //  Add an URL to the Tweet.  You can add multiple URLs.
        if (![tweetSheet addURL:[NSURL URLWithString:@"http://twitter.com/"]]){
            NSLog(@"Unable to add the URL!");
        }
        
        //  Presents the Tweet Sheet to the user
        [self presentViewController:tweetSheet animated:NO completion:^{
            NSLog(@"Tweet sheet has been presented.");
        }];
    }
}

- (IBAction)pinIt:(id)sender {
    {
        [super viewDidLoad];
        [self.view setBackgroundColor:[UIColor whiteColor]];
        
        // Initialize a Pinterest instance with our client_id
        _pinterest = [[Pinterest alloc] initWithClientId:@"1234" urlSchemeSuffix:@"prod"];
        
        // Setup Title Label
        UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        CGFloat centerX = CGRectGetMidX(self.view.frame);
        [titleLabel setText:@""];
        [titleLabel setBackgroundColor:[UIColor clearColor]];
        [titleLabel sizeToFit];
        [titleLabel setFrame:CGRectMake(centerX - CGRectGetWidth(titleLabel.frame)/2,
                                        kMargin,
                                        CGRectGetWidth(titleLabel.frame),
                                        CGRectGetHeight(titleLabel.frame))];
        [self.view addSubview:titleLabel];
        
        // Setup a sample imageview for the image we want to pin
        NSURL* aURL = [NSURL URLWithString:@""];
        NSData* data = [[NSData alloc] initWithContentsOfURL:aURL];
        UIImage* sampleImage = [UIImage imageWithData:data];
        UIImageView* sampleImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [sampleImageView setImage:sampleImage];
        [sampleImageView setFrame:CGRectMake(centerX - kSampleImageWidth/2,
                                             CGRectGetMaxY(titleLabel.frame) + kMargin,
                                             kSampleImageWidth,
                                             kSampleImageHeight)];
        [self.view addSubview:sampleImageView];
        
        // Setup PinIt Button
        UIButton* pinItButton = [Pinterest pinItButton];
        [pinItButton setFrame:CGRectMake(centerX - kPinItButtonWidth/2,
                                         CGRectGetMaxY(sampleImageView.frame) + kMargin,
                                         kPinItButtonWidth,
                                         kPinItButtonHeight)];
        [pinItButton addTarget:self
                        action:@selector(pinIt:)
              forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:pinItButton];
    }
    
#pragma mark -
#pragma mark PinIt Method
    
    {
        [_pinterest createPinWithImageURL:[NSURL URLWithString:@"http://i.imgur.com/hJsrBb7.png"]
                                sourceURL:[NSURL URLWithString:@"http://i.imgur.com/hJsrBb7.png"]
                              description:@""];
    }

}

- (IBAction)moreOptions:(id)sender{
    NSString *shareText = @"http://www.outwardinc.com/home/";
    NSArray *itemsToShare = @[shareText];
    UIActivityViewController * activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
    activityVC.excludedActivityTypes = @[];
    [self presentViewController: activityVC animated:YES completion:nil];
}

//------------------------------------


@end
