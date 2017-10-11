
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
    if(partBytesSize > 0)
        _partBytesSize = partBytesSize;
}

-(void) setDebug: (BOOL) debug{
    _debug = debug;
}

-(void) runTask{

    if(_checkPartialDownload){
        [self checkServerSupportPartialDownload: ^(BOOL acceptRanges){
            
            if(_debug){
                if(acceptRanges){
                    NSLog(@"server accepts partial download");
                }else{
                    NSLog(@"server does not accepts partial download");
                }
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
            NSString *filePartName = [NSString stringWithFormat: @"%@.%@", destination, @".part"];
            
            if(supportsPartialDownload){

                unsigned long long fileSize = 0;

                if([fileManager fileExistsAtPath: filePartName] == YES){
                    fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath: filePartName error:nil] fileSize];
                    if(_debug)
                       NSLog(@"file part %@ does  exists. size: %llu", filePartName, fileSize);
                }else{
                    if(_debug)
                        NSLog(@"file part %@ does not exists", filePartName);
                }
                
                long rangeStart = (long)fileSize;
                long rangeEnd = (long)(fileSize + _partBytesSize);
                
                NSString *contentRange = [NSString stringWithFormat:@"bytes %ld-%ld/*", rangeStart, rangeEnd];
                [request addValue:contentRange forHTTPHeaderField:@"Content-Range"];

                if(_debug)
                    NSLog(@"dowload file from %@", _url);

                [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
                  ^(NSData * _Nullable data,
                    NSURLResponse * _Nullable response,
                    NSError * _Nullable error) {

                        @try{

                            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;

                            if(error){
                                
                                NSString *errorMessage = [NSString stringWithFormat:@"Download file error. Status Code: %ld, Message: %@", (long)[httpResponse statusCode], [NSString stringWithUTF8String:[data bytes]]];
                                
                                [self.delegate onError: errorMessage];
                                NSLog(@"%@", errorMessage);
                                
                            }else if ([httpResponse statusCode] != 200){
                                
                                NSString *errorMessage = [NSString stringWithFormat:@"Download file error. Status Code: %ld, Message: %@", (long)[httpResponse statusCode], [NSString stringWithUTF8String:[data bytes]]];
                                [self.delegate onError: errorMessage];
                                NSLog(@"%@", errorMessage);
                                
                            }else{
                                
                                if(_debug)
                                    NSLog(@"Data received: %u", [data length]);

                                if (![[NSFileManager defaultManager] fileExistsAtPath: filePartName]) {
                                    [[NSFileManager defaultManager] createFileAtPath: filePartName contents:nil attributes:nil];
                                }
                                
                                NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath: filePartName];
                                [fileHandle seekToEndOfFile];
                                [fileHandle writeData: data];
                                [fileHandle closeFile]; 

                                if([data length] <= 0 || [data length] < _partBytesSize){

                                    if(![self fileRemove: destination]){
                                        return;
                                    }
                                    
                                    if([self fileMove: filePartName to: _toFile]){
                                        [self.delegate onComplete: _identifier];
                                    }
                                    
                                }else{
                                    [self onDownload: true];
                                }
                            }
                            
                        }@catch (NSException *exception) {
                            [self.delegate onError:[exception reason]];
                        }

                }] resume];                    

            }else{      
                
                if(_debug)
                    NSLog(@"dowload file from %@", _url);
                
                if(![self fileRemove: destination]){
                    return;
                }

                NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                    
                    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
                    
                    NSString *url = [NSString stringWithFormat:@"%@", [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]]];
                    
                    if(_debug)
                        NSLog(@"resolve url to save: %@ ", url);
                    
                    return [NSURL URLWithString:url];
                    
                } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                    
                    @try {
                        if(error){
                            NSLog(@"dowload error %@", error);
                            [self.delegate onError: [NSString stringWithFormat:@"error download file: %@", [error description]]];
                        }else{
                            
                            if(_debug)
                                NSLog(@"file download successful");
                            
                            if(![self fileRemove: destination]){
                                return;
                            }
                            
                            if(_debug)
                                NSLog(@"move file to %@", destination);
                            
                            
                            if([self fileMove: filePath.path to: destination]){
                                if(_debug)
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

-(void) checkServerSupportPartialDownload:  (void (^)(BOOL acceptRanges))completionBlock {

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
            if(_debug){
                NSLog(@"get HEAD error %@. Status Code: %ld, Message: %@", error, (long)[httpResponse statusCode], [NSString stringWithUTF8String:[data bytes]]);
            }
            completionBlock(false);
        
        }else if ([httpResponse statusCode] != 200){
            
            if(_debug){
                NSString *errorMessage = [NSString stringWithFormat:@"Execute HEAD error. Status Code: %ld, Message: %@", (long)[httpResponse statusCode], [NSString stringWithUTF8String:[data bytes]]];
                NSLog(@"%@", errorMessage);
            }
            
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

-(bool) fileRemove:(NSString*) fileToRemove {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if([fileManager fileExistsAtPath: fileToRemove ] == YES){
        
        if(_debug)
            NSLog(@"try delete file %@ ", fileToRemove);
        
        NSError *deleteError;
        [fileManager removeItemAtPath: fileToRemove error:&deleteError];
        
        if(deleteError){
            NSLog(@"error on delete file to %@ -> %@", fileToRemove, deleteError);
            [self.delegate onError: [NSString stringWithFormat:@"error on delete file to %@ -> %@", fileToRemove, deleteError]];
            return false;
        } else {
            if(_debug)
                NSLog(@"file delete success: %@ ", fileToRemove);
        }
    } else {
        if(_debug)
            NSLog(@"file to remove not found: %@ ", fileToRemove);
    }
    return true;

}

-(bool) fileMove: (NSString*) origin to:(NSString*) destination{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *moveError;
    
    [fileManager moveItemAtPath: origin toPath: destination error: &moveError];
    
    
    if(moveError){
        NSLog(@"error move file %@ to %@ -> %@", origin, destination, moveError);
        [self.delegate onError: [NSString stringWithFormat:@"error move download file: %@", [moveError description]]];
        return false;
    }
    
    return true;

}

@end
