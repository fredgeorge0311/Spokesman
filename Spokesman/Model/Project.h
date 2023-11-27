//
//  Project.h
//  Spokesman
//
//  Created by chaitanya venneti on 04/04/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Project : NSObject<NSCoding>

@property int projectId;
@property (nonatomic, strong) NSString *projectName;

@property (nonatomic, strong) NSMutableArray *assets;

@property (nonatomic, strong) NSMutableArray *people;

@property (nonatomic, strong) NSMutableArray *products;

@property (nonatomic, strong) NSMutableArray *transitions;

//@property (nonatomic, strong) NSMutableArray *audiotransitions;

@property (nonatomic, strong) NSMutableArray *sounds;

@end
