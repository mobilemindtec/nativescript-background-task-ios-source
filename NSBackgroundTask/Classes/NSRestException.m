//
//  RestException.m
//  Pods
//
//  Created by Ricardo Bocchi on 13/03/17.
//
//

#import "NSBackgroundTask.h"

@implementation NSRestException

@synthesize content, statusCode, message;

-(id) initWithName:(NSExceptionName)aName reason:(NSString *)aReason userInfo:(NSDictionary *)aUserInfo{
    self = [super initWithName:aName reason:aReason userInfo:aUserInfo];
    return self;
}

@end
