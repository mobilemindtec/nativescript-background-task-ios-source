//
//  NSQuery.m
//  Pods
//
//  Created by Ricardo Bocchi on 13/03/17.
//
//

#import "NSBackgroundTask.h"


@implementation NSQuery

@synthesize query, insertQuery, updateQuery, params, tableName, updateKey, updateKeyValue, updateKeyDataType;

-(id) init{
    self = [super init];
    self.params = [NSMutableArray array];
    return self;
}

@end
