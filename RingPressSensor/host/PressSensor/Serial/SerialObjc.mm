//
//  SerialObjc.m
//  PressSensor
//
//  Created by Tomo Kikuchi on 2022/12/05.
//
#import <stdio.h>

#import "SerialObjc.h"
#import "Serial.hpp"
#import "DigitalSignalProcessing.hpp"

#define S_WAITING       0
#define S_RECV_PREFIX0  1
#define S_RECV_PREFIX1  2
#define S_RECV_ADDR_DST 3
#define S_RECV_ADDR_SRC 4
#define S_RECV_FUNC_CMD 5
#define S_RECV_SIZE     6
#define S_RECV_DATA     7
#define S_RECV_CRC16_1  8
#define S_RECV_CRC16_2  9

@implementation SerialController : NSObject{
    Serial serial;
    DSP::Butrerworth *filters;
    BOOL   isStarted;
    int    state;
    int    recv_count;
    int    recved_count;
    int    count;
    uint8_t func;
    uint16_t crc16;
    uint8_t* buf;
    BOOL  isParsed;
    BOOL  endLoop;
    
    FILE*   fp;
    BOOL    isRecordFloat;
    BOOL    isRecording;
    BOOL    willStopRecording;
    Float32 recordingDurTime;
    NSDate *startRecordingTime;
    NSDate *currentRecordingTime;
}

@synthesize recvData;
@synthesize thread;
@synthesize delegate;

static SerialController* sharedInstance_;

+ (SerialController*) sharedInstance{
    @synchronized (self) {
        if(!sharedInstance_){
            [[self alloc] init];
        }
    }
    
    return sharedInstance_;
}

+ (id) allocWithZone:(struct _NSZone *)zone{
    @synchronized (self) {
        if(sharedInstance_ == nil){
            sharedInstance_ = [super allocWithZone:zone];
            return sharedInstance_;
        }
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (unsigned long) retainCount {
    return (unsigned long) UINT_MAX;
}

- (oneway void)release {
}

- (id) autorelease{
    return self;
}

- (id) init{
    if(self = [super init]){
        // Initilize
        serial.init(2048); // Serial Buffer Size = 2048
        isStarted = false;
        isParsed  = false;
        state = S_WAITING;
        endLoop = false;
        count = 0;
        isRecording = false;
        willStopRecording = false;
        isRecordFloat = false;
        recordingDurTime = -1.0;
        startRecordingTime = [NSDate date];
        currentRecordingTime = [NSDate date];
        filters = new DSP::Butrerworth[20];
        recv_count = 0;
        buf = (uint8_t*) malloc(sizeof(uint8_t) * 256);
    }
    
    return self;
}

- (void) setCutoff: (double) fc{
    for(int i=0; i<20; i++){
        filters[i].setCutoff(fc);
    }
}

- (NSMutableArray*) getSensorLastestDatas{
    return nil;
}

- (NSMutableArray*) popSensorData{
    return nil;
}

- (void) __parsePacket:(unsigned char)data{
    if(state == S_RECV_PREFIX0){
        if(data == __PREFIX0_HEX){
//            printf("[0]prefix 0\n");
            state = S_RECV_PREFIX1;
        }
    }else if(state == S_RECV_PREFIX1){
        if(data == __PREFIX1_HEX){
//            printf("[1]prefix 1\n");
            state = S_RECV_ADDR_DST;
        }
    }else if(state == S_RECV_ADDR_DST){
        if(data == 0x01){ // me : 0x01
//            printf("[2]dst addr 0\n");
            state = S_RECV_ADDR_SRC;
        }
    }else if(state == S_RECV_ADDR_SRC){
        if(data == 0x02){ // sensor
//            printf("[3]src addr 0\n");
            state = S_RECV_FUNC_CMD;
        }
    }else if(state == S_RECV_FUNC_CMD){
        if(data == 0x03 || data == 0x04){
//            printf("[4]func %02X\n", data);
            state = S_RECV_SIZE;
            func = data;
        }
    }else if(state == S_RECV_SIZE){
        recv_count = data & 0x00FF;
        state = S_RECV_DATA;
//        printf("[5]data length %d %02X\n", recv_count, data);
    }else if(state == S_RECV_DATA){
        
        buf[count] = data & 0x00FF;
        
//#define DEBUG_O
#ifdef DEBUG_O
        if(count == 4 || count == 5){
            printf("%02X\n", data);
        }
#endif
        
        if(++count >= recv_count){
            recved_count = recv_count;
            recv_count = 0;
            count = 0;
            state = S_RECV_CRC16_1;
            // printf("[6]data recved\n");
        }
    }else if(state == S_RECV_CRC16_1){
        crc16 = 0;
        crc16 = data;
        state = S_RECV_CRC16_2;
//        printf("[7]crc16 1\n");
    }else if(state == S_RECV_CRC16_2){
        crc16 |= data << 8;
//        printf("[8]crc16 2\n");
       
        int sc = 0;
        int ss = 6;
        for(int i=0; i<recved_count/6; i++){
            UInt32 time = 0;
            time |= (buf[i*ss+0] << 24) & 0xFF000000;
            time |= (buf[i*ss+1] << 16) & 0x00FF0000;
            time |= (buf[i*ss+2] <<  8) & 0x0000FF00;
            time |= (buf[i*ss+3] <<  0) & 0x000000FF;
            
            UInt16 raw = 0;
            raw |= (buf[i*ss+4] << 8) & 0xFF00;
            raw |= (buf[i*ss+5] << 0) & 0x00FF;
            
            // 6バイト => 7データ * 2 => 0 ~ 13
            UInt32 sensor = (func - 0x03) * 7 + i;
            
            if (true) {
                double din = (double(raw)/1023.0);
                double proced = filters[sensor].process(din);
                [delegate onRecvDataWithId:sensor time:time raw:raw proced:proced];
                                
                // 最後のデータ(14個目=13)の時
                if(sensor == 13 && willStopRecording){
                    willStopRecording = false;
                    isRecording = false;
                    printf("close fp\n");
                    fclose(fp);
                }
                
                if(isRecording){
                    if(recordingDurTime != -1.0){
                        currentRecordingTime = [NSDate date];
                        Float32 diffTime = [currentRecordingTime timeIntervalSinceDate:startRecordingTime];
                        if(recordingDurTime < diffTime){
                            printf("%f %d\n", diffTime, isRecording);
                            if([self.delegate respondsToSelector:@selector(onWillStopByTimer)]){
                                [delegate onWillStopByTimer];
                                willStopRecording = false;
                                isRecording = false;
                                fclose(fp);
                            }
                        }
                    }
                    
                    if(isRecordFloat){
                        double time_f = double(time) / 1000.0;
                        double raw_f  = double(raw)  / 1024.0; // ADC 10bit => 2^10 = 1024 が最大値
                        
                        fprintf(fp, "%f,%u,%f\n", time_f, (unsigned int)sensor, raw_f);
                    }else{
                        fprintf(fp, "%lu,%u,%d\n", (unsigned long)time, (unsigned int)sensor, raw);
                    }
                }
            }
        }
       
        
        state = S_RECV_PREFIX0;
        
    }
}

- (void) __threadLoop:(id)userInfo{
    while(true){
        serial.receive(false);
        while(1){
            int  recv = serial.get_recv_size();
            if(recv <= 0) break;
            
            unsigned char byte = serial.pop_recv_data();
//            NSLog(@"%02X ", byte);
            [self __parsePacket:byte];
        }
        
        if(endLoop) break;
    }
}

- (void) setSerialPortName:(const char*)portName{
    serial.set_port(portName);
}

- (void) startSerial{
    NSLog(@"startSerial %d", isStarted);
    if(isStarted == false){
        isStarted = true;
        
       
        serial.set_timeout(0, 1000);
        serial.begin(BAUD_RATE);
        
        state = S_RECV_PREFIX0;
        
        thread = [[[NSThread alloc] initWithTarget:self selector:@selector(__threadLoop:) object:nil] autorelease];                        
             
        [thread start];
    }
}

- (void) endSerial{
    if(isStarted == true){
        isStarted = false;
        endLoop = true;
        serial.end();        
    }
}

- (void) startRecording:(const char*) fpath isFloat:(BOOL)isFloat{
    if(!isRecording){
        fp = fopen(fpath, "w");
        if(fp == NULL){
            printf("NULL!\n");
            return;
        }
        
        startRecordingTime = [NSDate date];
        isRecordFloat = isFloat;
        isRecording = true;
    }
}

- (void) endRecording{
    if(isRecording){
        willStopRecording = true;
    }
}

- (void) setRecordingTime:(float) time{
    recordingDurTime = time;
}

@end
