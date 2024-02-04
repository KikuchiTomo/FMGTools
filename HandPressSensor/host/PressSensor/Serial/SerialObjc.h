//
//  SerialObjc.h
//  PressSensor
//
//  Created by Tomo Kikuchi on 2022/12/05.
//

#ifndef SerialObjc_h
#define SerialObjc_h

#import <Foundation/Foundation.h>

#define BAUD_RATE (115200)

#define __PREFIX0_HEX (0xAA)
#define __PREFIX1_HEX (0x55)

@protocol SerialObjcDelegate
@optional
- (void)onRecvDataWithId:(uint32_t)id time:(uint32_t)time raw:(uint16_t)raw proced:(double)proced;
- (void)onWillStopByTimer;
@end

@interface SerialController: NSObject{
    NSMutableArray *recvData;
    NSThread *thread;
}

@property (atomic, assign) id <SerialObjcDelegate> delegate;
@property (atomic, assign) NSMutableArray* recvData;
@property (atomic, assign) NSThread *thread;

+ (SerialController*) sharedInstance;

- (NSMutableArray*) getSensorLastestDatas;
- (NSMutableArray*) popSensorData;

- (void) setCutoff: (double) fc;
- (void) setSerialPortName:(const char*)portName;
- (void) startSerial;
- (void) endSerial;
- (void) startRecording:(const char*) fpath isFloat:(BOOL)isFloat;
- (void) endRecording;
- (void) setRecordingTime:(float) time;
@end



#endif /* SerialObjc_h */
