//
//  AppDelegate.h
//  Spokesman
//
//  Created by chaitanya venneti on 23/01/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MainWindowController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (nonatomic,strong) MainWindowController *mainWindowController;

@end

