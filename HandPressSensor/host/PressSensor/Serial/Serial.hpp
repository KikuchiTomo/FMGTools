//
//  Serial.hpp
//  PressSensor
//
//  Created by Tomo Kikuchi on 2022/12/05.
//

#ifndef Serial_hpp
#define Serial_hpp

#include <stdio.h>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>
#include <time.h>
#include <string.h>
#include <pthread.h>

#include "RingDeque.hpp"

#define SERIAL_CS8    (0b0000000000000001)
#define SERIAL_CS7    (0b0000000000000010)
#define SERIAL_CS6    (0b0000000000000100)
#define SERIAL_CS5    (0b0000000000001000)
#define SERIAL_PARN   (0b0000000000010000)
#define SERIAL_PARO   (0b0000000000100000)
#define SERIAL_PARE   (0b0000000001000000)
#define SERIAL_STOPB1 (0b0000000010000000)
#define SERIAL_STOPB2 (0b0000000100000000)

#define SERIAL_8N2 (SERIAL_CS8 | SERIAL_PARN | SERIAL_STOPB2)
#define SERIAL_8N1 (SERIAL_CS8 | SERIAL_PARN | SERIAL_STOPB1)
#define SERIAL_8O2 (SERIAL_CS8 | SERIAL_PARO | SERIAL_STOPB2)
#define SERIAL_8O1 (SERIAL_CS8 | SERIAL_PARO | SERIAL_STOPB1)
#define SERIAL_8E2 (SERIAL_CS8 | SERIAL_PARE | SERIAL_STOPB2)
#define SERIAL_8E1 (SERIAL_CS8 | SERIAL_PARE | SERIAL_STOPB1)

#define SERIAL_7N2 (SERIAL_CS7 | SERIAL_PARN | SERIAL_STOPB2)
#define SERIAL_7N1 (SERIAL_CS7 | SERIAL_PARN | SERIAL_STOPB1)
#define SERIAL_7O2 (SERIAL_CS7 | SERIAL_PARO | SERIAL_STOPB2)
#define SERIAL_7O1 (SERIAL_CS7 | SERIAL_PARO | SERIAL_STOPB1)
#define SERIAL_7E2 (SERIAL_CS7 | SERIAL_PARE | SERIAL_STOPB2)
#define SERIAL_7E1 (SERIAL_CS7 | SERIAL_PARE | SERIAL_STOPB1)

#define SERIAL_6N2 (SERIAL_CS6 | SERIAL_PARN | SERIAL_STOPB2)
#define SERIAL_6N1 (SERIAL_CS6 | SERIAL_PARN | SERIAL_STOPB1)
#define SERIAL_6O2 (SERIAL_CS6 | SERIAL_PARO | SERIAL_STOPB2)
#define SERIAL_6O1 (SERIAL_CS6 | SERIAL_PARO | SERIAL_STOPB1)
#define SERIAL_6E2 (SERIAL_CS6 | SERIAL_PARE | SERIAL_STOPB2)
#define SERIAL_6E1 (SERIAL_CS6 | SERIAL_PARE | SERIAL_STOPB1)

#define SERIAL_5N2 (SERIAL_CS5 | SERIAL_PARN | SERIAL_STOPB2)
#define SERIAL_5N1 (SERIAL_CS5 | SERIAL_PARN | SERIAL_STOPB1)
#define SERIAL_5O2 (SERIAL_CS5 | SERIAL_PARO | SERIAL_STOPB2)
#define SERIAL_5O1 (SERIAL_CS5 | SERIAL_PARO | SERIAL_STOPB1)
#define SERIAL_5E2 (SERIAL_CS5 | SERIAL_PARE | SERIAL_STOPB2)
#define SERIAL_5E1 (SERIAL_CS5 | SERIAL_PARE | SERIAL_STOPB1)

#define SERIAL_DEFAULT_BUFFER_SIZE (1024)

class Serial{
private:
    int baud_rate_;
    
    char config_;
    char port_name_[256];
    
    int fd_;
    int rv_;
    
    RingDeque<unsigned char> *rb_; // 受信バッファ
    RingDeque<unsigned char> *sb_; // 送信バッファ
    
    char tmp_rb_[2048];
    char tmp_sb_[2048];
    
    long long int wait_time_sec_ = 0;
    long long int wait_time_u_   = 0;
    
    fd_set set_;
    
    struct timeval timeout_ = {0, 0};
    
    speed_t __dec2baudrate(int baud_rate);
    
    pthread_mutex_t m_ = PTHREAD_MUTEX_INITIALIZER;
public:
    /**
     * @param[in] buffer_size 送受信バッファのサイズ
     */
    Serial();
    ~Serial();
    
    void init(int buffer_size = SERIAL_DEFAULT_BUFFER_SIZE);
    
    /**
     * ポートを指定する
     * @praram[in] port_name ポート名
     */
    void set_port(const char *port_name);

    /**
     * タイムアウトを設定する(sec + usec)
     * @param[in] sec 秒
     * @param[in] usec マイクロ秒
     */
    void set_timeout(long long int sec, long long int usec);
    
    /**
     * シリアル通信を開始する
     * @param[in] baud_rate ボーレート
     */
    void begin(int baud_rate, unsigned char config = SERIAL_8N1);

    /**
     * シリアル通信の終了
     */
    void end();
    
    /**
     * データの読み取り
     * @return 受信したデータ(1byte)
     */
    unsigned char pop_recv_data();

     /**
     * データの読み取り
     * @return 受信したデータ(1byte)
     */
    unsigned char read_recv_data(int offset = 0);
    

    int get_recv_size();
    /**
     * データの送信
     * @param[in] data 送信するデータ(1byte)
     */
    void push_send_data(unsigned char data);

    /**
     * 受信バッファのクリア
     */
    void reset_recv_buf();

    /**
     * 送信バッファのクリア
     */
    void reset_send_buf();
    
    /**
     * データを読み取って受信バッファに詰める
     */
    void receive(bool is_brocking = true);

    /**
     * 送信バッファにあるデータを全て送信する
     */
    void send(bool is_brocking = true);
};

#endif /* Serial_hpp */
