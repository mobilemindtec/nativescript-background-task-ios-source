//
//  NSSplitFile.m
//  Pods
//
//  Created by Ricardo Bocchi on 11/03/17.
//
//

#import "NSBackgroundTask.h"

@implementation NSSplitFile

    @synthesize fileSrc, filePathPath, filePartMaxSize, filePartName, filePartSufix, filePartCount, fileParts;
    
    -(id) init{
        
        self = [super init];
        
        self.filePartMaxSize = 5;
        self.fileParts = [NSMutableArray array];
        
        return self;
    }

@end
