

#import "NSBackgroundTask.h"


@implementation NSHttpPostFile

  @synthesize identifier, fileSrc, jsonKey, result, json, responseHeaders;


-(id) initWithFileSrc:(NSString*) fileSrc jsonKey:(NSString *) jsonKey{
    self = [super init];
    self.fileSrc = fileSrc;
    self.jsonKey = jsonKey;

    self.json = [NSMutableDictionary dictionary];
    self.responseHeaders = [NSMutableDictionary dictionary];

    return self;
}

-(void) addJsonKey:(NSString*) key value:(NSString *) value{
    [self.json setObject:value forKey:key];
}

-(NSMutableArray *) getHeadersNames{
    return [self.responseHeaders allKeys];
}

-(NSString *) getHeaderValue:(NSString *) name{
    return [self.responseHeaders objectForKey:name];
}

-(NSDictionary *) getHeaders{
    return self.responseHeaders;
}


@end
