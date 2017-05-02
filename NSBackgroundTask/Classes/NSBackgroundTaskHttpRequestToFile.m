
#import "NSBackgroundTask.h"
#import "AFNetworking.h"


@implementation NSBackgroundTaskHttpRequestToFile

@synthesize delegate;

-(id) initWithUrl:(NSString *) url toFile: (NSString *) toFile identifier: (NSString *) identifier{
    self = [super init];    
    _toFile = toFile;
    _url = url;
    _identifier = identifier;
    _httpHeaders = [NSMutableDictionary dictionary];
    _partBytesSize = 1024 * 1024 * 2; // 2MB
    _checkPartialDownload = false;
    return self;
}

-(void) addHeaderWithName:(NSString *)name andValue:(NSString *)value{
    [_httpHeaders setValue:value forKey:name];
}

-(void) setCheckPartialDownload: (BOOL) checkPartialDownload{
    _checkPartialDownload = checkPartialDownload;
}

-(void) setPartBytesSize: (int) partBytesSize {
    _partBytesSize = partBytesSize;
}

-(void) runTask{

    if(_checkPartialDownload){
        supportsPartialDownload = [self checkServerSupportPartialDownload: ^(BOOL acceptRanges){

            if(acceptRanges){
                NSLog(@"server accepts partial download");
            }else{
                NSLog(@"server does not accepts partial download");
            }

            [self onDownload: acceptRanges];
        }];
    } else {
        [self onDownload: false];        
    }

}

-(void) onDownload: (BOOL) supportsPartialDownload{


	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
	    
        @try {


            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
            AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSURL *url = [[NSURL alloc] initWithString: _url];
            
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            
            
            for (NSString *key in _httpHeaders) {
                [request addValue:[_httpHeaders objectForKey:key] forHTTPHeaderField:key];
            }

            NSString *destination = _toFile;
            NSString *filePartName = [NSString stringWithFormat: @"%@.%@", destination, ".part"];
            
            if(supportsPartialDownload){

                unsigned long long fileSize = 0;

                if([fileManager fileExistsAtPath: filePartName] == YES)
                    fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath: filePartName error:nil] fileSize];
                
                long rangeStart = fileSize;
                long rangeEnd = fileSize + _partBytesSize;                
                NSString *contentRange = [NSString stringWithFormat:@"bytes %@-%@/*", rangeStart, rangeEnd];                
                [request addValue:[_httpHeaders objectForKey:contentRange] forHTTPHeaderField:@"Content-Range"];

                
                NSLog(@"dowload file from %@", _url);

                [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
                  ^(NSData * _Nullable data,
                    NSURLResponse * _Nullable response,
                    NSError * _Nullable error) {

                        @try{

                            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;

                            if(error){
                                NSLog(@"dowload error %@", error);
                                [self.delegate onError: [NSString stringWithFormat:@"Download file error. Status Code: %ld, Message: %@", (long)[httpResponse statusCode], [NSString stringWithUTF8String:[data bytes]]]];
                            }else{
                              
                                NSLog(@"Data received: %@", [data length]);

                                NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath: filePartName];
                                [fileHandle seekToEndOfFile];
                                [fileHandle writeData: data];
                                [fileHandle closeFile]; 

                                if([data length] <= 0 || [data length] < _partBytesSize){

                                    NSError *error = nil;
                                    [[NSFileManager defaultManager] moveItemAtPath:filePartName toPath:_toFile error:&error];
                                    
                                    if(error){
                                        NSLog(@"error move file of %@ to %@", filePartName, _toFile);
                                        [self.delegate onError: [NSString stringWithFormat:@"error move file of %@ to %@", filePartName, _toFile]];
                                        return;
                                    }  

                                    [self.delegate onComplete: _identifier];
                                }else{
                                    [self onDownload: true];
                                }
                            }
                            
                        }@catch (NSException *exception) {
                            [self.delegate onError:[exception reason]];
                        }

                }] resume];                    

            }else{      

                NSLog(@"dowload file from %@", _url);

                if([fileManager fileExistsAtPath: destination ] == YES){
                    NSLog(@"deleting destination file %@ before download..", destination);
                    NSError *deleteError;
                    [fileManager removeItemAtPath: destination error:&deleteError];
                    
                    if(deleteError){
                        NSLog(@"error on delete file to %@ -> %@", destination, deleteError);
                        [self.delegate onError: [NSString stringWithFormat:@"error on delete file to %@ -> %@", destination, deleteError]];
                        return;
                    }                
                }

                NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                    
                    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
                    
                    NSString *url = [NSString stringWithFormat:@"%@", [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]]];
                    
                    NSLog(@"resolve url to save: %@ ", url);
                    
                    return [NSURL URLWithString:url];
                    
                } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                    
                    @try {
                        if(error){
                            NSLog(@"dowload error %@", error);
                            [self.delegate onError: [NSString stringWithFormat:@"error download file: %@", [error description]]];
                        }else{
                            NSLog(@"file download successful");
                            
                            NSError *moveError;
                            
                            NSLog(@"move file to %@", destination);
                            
                            [fileManager moveItemAtPath: filePath.path toPath: destination error: &moveError];
                            
                            if(moveError){
                                NSLog(@"error move dowload file %@ to %@ -> %@", filePath.path, destination, moveError);
                                [self.delegate onError: [NSString stringWithFormat:@"error move download file: %@", [moveError description]]];
                            }else{
                                NSLog(@"success dowload move %@ to %@", filePath.path, destination);
                                [self.delegate onComplete: _identifier];
                            }
                        }
                    } @catch (NSException *exception) {
                        [self.delegate onError:[exception reason]];
                    }
                }];
                
                [downloadTask resume];

            }
            

        } @catch (NSException *exception) {
            [self.delegate onError:[NSString stringWithFormat:@"error resume download task: %@", [exception reason]]];
        }


	});
}

-(BOOL) checkServerSupportPartialDownload:  (void (^)(BOOL acceptRanges))completionBlock {

    NSURL *url = [[NSURL alloc] initWithString: _url];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL: url];
    [request setHTTPMethod:@"HEAD"];
    
    for (NSString *key in _httpHeaders) {
        [request setValue:[_httpHeaders objectForKey:key] forHTTPHeaderField:key];
    }


    [[[NSURLSession sharedSession] dataTaskWithRequest: request completionHandler:
      ^(NSData * _Nullable data,
        NSURLResponse * _Nullable response,
        NSError * _Nullable error) {

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;

        if(error){
            NSLog(@"get HEAD error %s. Status Code: %ld, Message: %s", error, (long)[httpResponse statusCode], [NSString stringWithUTF8String:[data bytes]]);
            completionBlock(false);
        } else {

            if ([httpResponse respondsToSelector:@selector(allHeaderFields)]) {
                 NSDictionary *dictionary = [httpResponse allHeaderFields];

                 if([dictionary objectForKey:@"Accept-Ranges"]){

                    NSString *value = [dictionary objectForKey:@"Accept-Ranges"];
                    value = [value stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                    BOOL acceptRanges = [@"bytes" isEqualToString: value]  ;

                    completionBlock(acceptRanges);
                 }else{
                    completionBlock(false);
                 }
            }else{
                completionBlock(false);
            }  
        } 

    }] resume];

    
}

@end
