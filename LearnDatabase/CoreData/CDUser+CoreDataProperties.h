//
//  CDUser+CoreDataProperties.h
//  
//
//  Created by loyinglin on 2019/7/5.
//
//

#import "CDUser+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface CDUser (CoreDataProperties)

+ (NSFetchRequest<CDUser *> *)fetchRequest;

@property (nonatomic) int16_t gender;
@property (nullable, nonatomic, copy) NSString *name;

@end

NS_ASSUME_NONNULL_END
