//
//  DataService.h
//  RawCamera
//
//  Created by Mikel Gonzalez on 11/15/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//	File created using Singleton XCode Template by Mugunth Kumar (http://blog.mugunthkumar.com)
//  More information about this template on the post http://mk.sg/89
//  Permission granted to do anything, commercial/non-commercial with this file apart from removing the line/URL above

#import <Foundation/Foundation.h>

@interface DataService : NSObject
+ (DataService*) sharedInstance;
@property(nonatomic, strong)UIImage *eyeImg;
@property(nonatomic, strong)UIImage *mouthImg;
@end
