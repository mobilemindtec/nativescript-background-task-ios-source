//
//  NSBackgroundTaskTests.m
//  NSBackgroundTaskTests
//
//  Created by Ricardo Bocchi on 03/11/2017.
//  Copyright (c) 2017 Ricardo Bocchi. All rights reserved.
//

// https://github.com/Specta/Specta




@implementation NSCallback
    
    -(void) onComplete:(NSObject *) result{
        NSLog(@"*** result %@", result);
    }
    
    -(void) onError:(NSString *) message{
        NSLog(@"*** error %@", message);
    }
    
    
    @end

SpecBegin(InitialSpecs)


describe(@"these will fail", ^{
    
    /*
    it(@"load video", ^{
        
        NSSplitFileTask *task = [[NSSplitFileTask alloc] init];
        NSSplitFile *splitFile = [[NSSplitFile alloc] init];
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"big_buck_bunny" ofType:@"mp4"];
        
        NSString *tmpDirectory = NSTemporaryDirectory();
        
        NSLog(@"** video path %@", path);
        NSLog(@"** temp path %@", tmpDirectory);
        
        splitFile.fileSrc = path;
        splitFile.filePartPath = tmpDirectory;
        splitFile.filePartName = @"video";
        splitFile.filePartSufix = @"part";
        splitFile.filePartMaxSize = 1; // 2MB
        
        task.delegate = [[NSCallback alloc] init];
        [task addSplitFile: splitFile];
        
        
        //XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
        
        //[task runTask];
        
        //[self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        //    NSLog(@"error: %@", error);
        //}];
        
    });
    
    it(@"save image", ^{
        
        NSString *tmpDirectory = NSTemporaryDirectory();
        
        NSLargeFilePersisterTask *task = [[NSLargeFilePersisterTask alloc] init];
        
        NSLargeFile *largeFile1 = [[NSLargeFile alloc] init];
        largeFile1.fileSrc = [[NSBundle mainBundle] pathForResource:@"mobilemind" ofType:@"png"];
        largeFile1.fileDst = [NSString stringWithFormat:@"%@%@", tmpDirectory, @"newfile.png"];

        NSLargeFile *largeFile2 = [[NSLargeFile alloc] init];
        largeFile2.image = [UIImage imageNamed: @"mobilemind.png"];
        largeFile2.fileDst = [NSString stringWithFormat:@"%@%@", tmpDirectory, @"newfile2.png"];
        
        task.delegate = [[NSCallback alloc] init];
        
        [task addLargeFile: largeFile1];
        [task addLargeFile: largeFile2];
        //[task runTask];
        
    });
    
    it(@"post file", ^{
        
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"big_buck_bunny" ofType:@"mp4"];
        
        NSHttpPostFile *postFile = [[NSHttpPostFile alloc] initWithFileSrc: path jsonKey: @"video"];
        
        [postFile addJsonKey: @"name" value: @"jonh"];
        
        NSHttpPostFileTask *task = [[NSHttpPostFileTask alloc] initWithUrl: @"http://10.0.0.106:3000/post-form-data"];
        
        task.delegate = [[NSCallback alloc] init];
        
        [task addHeaderWithName: @"Content-Type" andValue: @"application/json"];
        [task addHeaderWithName: @"X-Auth-Token" andValue: @"token"];
        [task addPostFile: postFile];
        
        //without gzip 7813242 - with gzip 6855242
        [task setUseGzip: true];
        [task setUseFormData: false];
        [task runTask];
        
        [NSThread sleepForTimeInterval:15];
        
    });
     */
    
    it(@"get larg file", ^{
        
        NSString *tmpDirectory = NSTemporaryDirectory();
        NSString *path = [NSString stringWithFormat:@"%@%@", tmpDirectory, @"newlargefile.pdf"];
        
        NSBackgroundTaskHttpRequestToFile *task = [[NSBackgroundTaskHttpRequestToFile alloc] initWithUrl: @"http://10.0.0.102:3000/partial-download" toFile: path identifier:@"nada"];
        
        task.delegate = [[NSCallback alloc] init];
        
        [task setCheckPartialDownload: true];
        
        [task runTask];
        
        [NSThread sleepForTimeInterval: 15];
        
    });
});

SpecEnd

