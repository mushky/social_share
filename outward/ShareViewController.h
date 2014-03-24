#import <UIKit/UIKit.h>

@interface ShareViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
- (IBAction)TweetShare:(id)sender;

- (IBAction)pinIt:(id)sender;

- (IBAction)moreOptions:(id)sender;

@end
