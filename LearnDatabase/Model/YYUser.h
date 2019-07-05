//
//  YYUser.h
//  LearnDatabase
//
//  Created by loyinglin on 2019/7/5.
//  Copyright © 2019 Loying. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YYModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface YYUser : NSObject <YYModel>

@property (nonatomic, assign) NSInteger gender;
@property (nonatomic, strong) NSString *userName;

@end

NS_ASSUME_NONNULL_END
