//
//  NSLargeFilePersisterTask.m
//  Pods
//
//  Created by Ricardo Bocchi on 11/03/17.
//
//

#import "NSBackgroundTask.h"

@implementation NSLargeFilePersisterTask

@synthesize delegate;

-(id) init{
    
    self = [super init];
    
    _largeFiles = [NSMutableArray array];
    
    return self;
}

-(void) addLargeFile:(NSLargeFile *)largeFile{
    [_largeFiles addObject:largeFile];
}

-(void) runTask{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL error = false;
       
        for (NSLargeFile *largeFile in _largeFiles) {
            
            
            if(!largeFile.fileSrc && !largeFile.image){
                [self.delegate onError: @"set fileSrc or image to large file"];
                error = true;
                break;
            }
            
            if([fileManager fileExistsAtPath:largeFile.fileDst]){
                NSError *deleteError;
                [fileManager removeItemAtPath:largeFile.fileDst error:&deleteError];
                
                if(deleteError){
                    NSLog(@"error on delete file %@ -> %@", largeFile.fileDst, deleteError);
                    [self.delegate onError: [deleteError description]];
                    error = true;
                    break;
                }
            }
            
            if([largeFile image]){
                
                NSString *name = [largeFile.fileDst lowercaseString];
                
                if([name hasSuffix:@"png"]){
                    [UIImagePNGRepresentation(largeFile.image) writeToFile:largeFile.fileDst atomically:YES];
                    
                    NSLog(@"save PNG to path %@", largeFile.fileDst);
                    
                } else if([name hasSuffix:@"jpg"] || [name hasSuffix:@"jpeg"]){
                    
                    if(largeFile.quality == 0){
                        largeFile.quality = 1;
                    }
                    
                    [UIImageJPEGRepresentation(largeFile.image, largeFile.quality) writeToFile:largeFile.fileDst atomically:YES];
                    
                    NSLog(@"save JPEG to path %@", largeFile.fileDst);
                }                                                
                
            }else{
                
                if(![fileManager fileExistsAtPath:largeFile.fileSrc]){
                    [self.delegate onError: [NSString stringWithFormat:@"file %@ not found to copy", largeFile.fileSrc]];
                    error = true;
                    break;
                }
                
                NSError *copyError;
                
                [fileManager copyItemAtPath: largeFile.fileSrc toPath: largeFile.fileDst error: &copyError];
                
                if(copyError)
                    [self.delegate onError: [copyError description]];
                
                NSLog(@"copy file to path %@", largeFile.fileDst);
            }
        }
        
        if(!error)
            [self.delegate onComplete: nil];
        
    });
}


@end
