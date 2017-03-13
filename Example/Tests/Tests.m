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
    
    it(@"load video", ^{
        
        NSSplitFileTask *task = [[NSSplitFileTask alloc] init];
        NSSplitFile *splitFile = [[NSSplitFile alloc] init];
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"big_buck_bunny" ofType:@"mp4"];
        
        NSString *tmpDirectory = NSTemporaryDirectory();
        
        NSLog(@"** video path %@", path);
        NSLog(@"** temp path %@", tmpDirectory);
        
        splitFile.fileSrc = path;
        splitFile.filePathPath = tmpDirectory;
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
        [task runTask];
        
    });
    
    /*
    it(@"can do maths", ^{
        expect(1).to.equal(2);
    });

    it(@"can read", ^{
        expect(@"number").to.equal(@"string");
    });
    
    it(@"will wait for 10 seconds and fail", ^{
        waitUntil(^(DoneCallback done) {
        
        });
    });
     */
});

describe(@"these will pass", ^{
    
    it(@"can do maths", ^{
        expect(1).beLessThan(23);
    });
    
    it(@"can read", ^{
        expect(@"team").toNot.contain(@"I");
    });
    
    it(@"will wait and succeed", ^{
        waitUntil(^(DoneCallback done) {
            done();
        });
    });
});

SpecEnd

