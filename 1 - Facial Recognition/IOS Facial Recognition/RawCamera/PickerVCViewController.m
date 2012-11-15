//
//  PickerVCViewController.m
//  RawCamera
//
//  Created by Mikel Gonzalez on 11/15/12.
//
//

#import "DataService.h"
#import "PickerVCViewController.h"

@interface PickerVCViewController ()

@end

@implementation PickerVCViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated{
    if ([DataService sharedInstance].eyeImg) {
        self.eyeImgView.image = [DataService sharedInstance].eyeImg;
    }
    
    if ([DataService sharedInstance].mouthImg) {
        self.mouthImgView.image = [DataService sharedInstance].mouthImg;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)eyeBtnPush:(id)sender {
    self.eyePicker = [[UIImagePickerController alloc] init];
    [self.eyePicker setEditing:YES];
    [self.eyePicker setDelegate:self];
    [self presentViewController:self.eyePicker animated:YES completion:nil];
}
- (IBAction)mouthBtnPush:(id)sender {
    self.mouthPicker = [[UIImagePickerController alloc] init];
    [self.mouthPicker setEditing:YES];
    [self.mouthPicker setDelegate:self];
    [self presentViewController:self.mouthPicker animated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    
    if (picker == self.mouthPicker) {
        UIImage *img = [info objectForKey:UIImagePickerControllerOriginalImage];
        self.mouthImgView.image = img;
        [DataService sharedInstance].mouthImg = img;
        [picker dismissViewControllerAnimated:YES completion:nil];
    }else{
        UIImage *img = [info objectForKey:UIImagePickerControllerOriginalImage];
        self.eyeImgView.image = img;
        [DataService sharedInstance].eyeImg = img;
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}
@end
