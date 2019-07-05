//
//  CDUser+CoreDataProperties.m
//  
//
//  Created by loyinglin on 2019/7/5.
//
//

#import "CDUser+CoreDataProperties.h"

@implementation CDUser (CoreDataProperties)

+ (NSFetchRequest<CDUser *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"CDUser"];
}

@dynamic gender;
@dynamic name;

@end
