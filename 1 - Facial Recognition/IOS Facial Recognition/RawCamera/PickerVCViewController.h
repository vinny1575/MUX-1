//
//  PickerVCViewController.h
//  RawCamera
//
//  Created by Mikel Gonzalez on 11/15/12.
//
//

#import <UIKit/UIKit.h>

@interface PickerVCViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
- (IBAction)eyeBtnPush:(id)sender;
@property (weak, nonatomic) IBOutlet UIImageView *eyeImgView;
- (IBAction)mouthBtnPush:(id)sender;
@property (weak, nonatomic) IBOutlet UIImageView *mouthImgView;

@property (nonatomic, strong) UIImagePickerController *eyePicker;
@property (nonatomic, strong) UIImagePickerController *mouthPicker;

@end
