//
//  Puzzle15AppDelegate.h
//  Puzzle15
//
//  Created by 相沢 伸一 on 10/08/19.
//  Copyright TRC 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Puzzle15ViewController;

@interface Puzzle15AppDelegate : NSObject <UIApplicationDelegate> {
}

@property (nonatomic) IBOutlet UIWindow *window;
@property (nonatomic) IBOutlet Puzzle15ViewController *viewController;

@end

