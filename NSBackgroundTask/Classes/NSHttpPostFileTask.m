
#import "NSBackgroundTask.h"
#import "AFNetworking.h"
#import "GZIP.h"


@implementation NSHttpPostFileTask

@synthesize delegate;

-(id) initWithUrl: (NSString *) url{
    self = [super init];
    _url = url;
    _httpHeaders = [NSMutableDictionary dictionary];
    _postFiles = [NSMutableArray array];
    return self;
}

-(void) setUseGzip:(BOOL) useGzip{
    _userGzip = useGzip;
}

-(void) setUseFormData:(BOOL) useFormData{
    _useFormData = useFormData;
}

-(void) addPostFile: (NSHttpPostFile *) postFile{
    [_postFiles addObject: postFile];
}

-(void) addHeaderWithName: (NSString *) name andValue: (NSString *) value{
    [_httpHeaders setValue:name forKey:value];
}

-(void) runTask{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *url = [[NSURL alloc] initWithString: _url];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        
        NSLog(@"post data url %@", _url);
        BOOL error = false;
        
        for (NSHttpPostFile *postFile in _postFiles) {
            
            if(![fileManager fileExistsAtPath: postFile.fileSrc  ]){
                NSLog(@"file %@ not found to post", postFile.fileSrc);
                [self.delegate onError: [NSString stringWithFormat:@"file %@ not found to post", postFile.fileSrc]];
                error = true;
                break;
            }
            
            NSData *data = [NSData dataWithContentsOfFile:postFile.fileSrc];
            
            if(_userGzip){
                data = [data gzippedData];
            }
            
            NSString *base64Encoded = [data base64EncodedStringWithOptions:0];
            
            [postFile.json setObject:postFile.jsonKey forKey:base64Encoded];
            
            NSString *post = @"";
            
            if(_useFormData){
                for(NSString *key in postFile.json){
                    post = [NSString stringWithFormat:@"%@=%@&", key, [postFile.json objectForKey:key]];
                }
            }else{
                for(NSString *key in postFile.json){
                    post = [NSString stringWithFormat:@"%@: %@, ", key, [postFile.json objectForKey:key]];
                }
                
                post = [post substringWithRange:NSMakeRange(0, [post length] - 2)];
                post = [NSString stringWithFormat:@"{%@}", post];
            }
            
            
            NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
            NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            [request setURL:[NSURL URLWithString:url]];
            [request setHTTPMethod:@"POST"];
            [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
            
            for (NSString *key in _httpHeaders) {
                [request setValue:key forHTTPHeaderField:[_httpHeaders objectForKey:key]];
            }
            
            [request setHTTPBody:postData];
                        
            [postFile.json removeObjectForKey:postFile.jsonKey];
        }
        
        
        if(!error)
            [self.delegate onComplete:_postFiles];
        
        
        
    });
}

@end
