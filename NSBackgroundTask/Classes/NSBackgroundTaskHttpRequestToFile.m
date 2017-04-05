
#import "NSBackgroundTask.h"
#import "AFNetworking.h"


@implementation NSBackgroundTaskHttpRequestToFile

@synthesize delegate;

-(void) addHeaderWithName:(NSString *)name andValue:(NSString *)value{
    [_httpHeaders setValue:value forKey:name];
}

-(void) runTask{
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
            
            //NSArray *listItems = [destination componentsSeparatedByString:@", "];
            
            //NSString *fileName = (NSString *)[listItems lastObject];
            //NSString *destinationFile = [destination stringByAppendingPathComponent: fileName];
            
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
            
            NSLog(@"dowload file from %@", _url);
            
            
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
        } @catch (NSException *exception) {
            [self.delegate onError:[NSString stringWithFormat:@"error resume download task: %@", [exception reason]]];
        }


	});
}


-(id) initWithUrl:(NSString *) url toFile: (NSString *) toFile identifier: (NSString *) identifier{
	self = [super init];	
	_toFile = toFile;
	_url = url;
    _identifier = identifier;
	return self;
}

@end
