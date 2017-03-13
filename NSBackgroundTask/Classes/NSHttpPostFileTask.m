
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
        
        @try {
            
            _index = 0;
            
            NSOperation *postOperation = [NSBlockOperation blockOperationWithBlock:^{
            
                if(index >= [_postFiles     count]){
                    [self.delegate onComplete:_postFiles];
                    return;
                }
                
                _index += 1;
                
                NSHttpPostFile *postFile = [_postFiles objectAtIndex:index];
                
                if(![fileManager fileExistsAtPath: postFile.fileSrc  ]){
                    NSLog(@"file %@ not found to post", postFile.fileSrc);
                    [self.delegate onError: [NSString stringWithFormat:@"file %@ not found to post", postFile.fileSrc]];
                    return;
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
                
                NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
                
                
                [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *r, NSError *error) {
                    
                    
                    @try {
                        NSString *requestReply = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                        
                        NSHTTPURLResponse *response = (NSHTTPURLResponse *) r;
                        
                        NSLog(@"request status: %d, result: %@", response.statusCode, requestReply);
                        
                        if(error){
                            [self.delegate onError:[NSString stringWithFormat:@" request error: %@", error]];
                            return;
                        }
                        
                        for(NSString *name in response.allHeaderFields){
                            [postFile.responseHeaders setObject:name forKey:[response.allHeaderFields objectForKey: name]];
                        }
                        
                        postFile.result = requestReply;
                        
                        
                        if(response.statusCode != 200){
                            
                            NSString *reason = [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode];
                            NSRestException *rest = [[NSRestException alloc] initWithName:@"NSRestException" reason:reason userInfo:nil];
                            rest.statusCode = response.statusCode;
                            rest.content = requestReply;
                            rest.message = reason;
                            
                            [self.delegate onError: rest];
                        }
                        
                        [postOperation start];

                    } @catch (NSException *exception) {
                        [self.delegate onError: [exception reason]];
                    }
                    
                    
                }] resume];
                
                [postFile.json removeObjectForKey:postFile.jsonKey];
            
                
            }];
            
            [postOperation start];
            
            
        } @catch (NSException *exception) {
            [self.delegate onError: [exception reason]];

        }        
    });
}

@end
