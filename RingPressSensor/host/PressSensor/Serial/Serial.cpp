//
//  SerialController.cpp
//  PressSensor
//
//  Created by Tomo Kikuchi on 2022/12/05.
//

#include <errno.h>
#include "Serial.hpp"
//#define DEBUG_OUT
//#define DEBUG_OUT_ON_RECV
/* private functions */
speed_t Serial::__dec2baudrate(int baud_rate){
    switch(baud_rate){
        case    9600: return    B9600; break;
        case   19200: return   B19200; break;
        case   38400: return   B38400; break;
        case   57600: return   B57600; break;
        case  115200: return  B115200; break;
        case  230400: return  B230400; break;
        default:
            exit(-1);
            break;
    }
}

/* public functions */

Serial::Serial(){
    
}

void Serial::init(int buffer_size){
    rb_ = new RingDeque<unsigned char>((long long int)buffer_size);
    sb_ = new RingDeque<unsigned char>((long long int)buffer_size);
}

Serial::~Serial(){
    delete rb_;
    delete sb_;
}


void Serial::set_port(const char *port_name){
    strcpy(port_name_, port_name);
}

void Serial::begin(int baud_rate, unsigned char config){
    fd_ = open(port_name_, O_RDWR|O_NONBLOCK);
    struct termios tio;
    
    if (fd_ < 0) {
#ifdef DEBUG_OUT
        fprintf(stderr, "[ERR] Serial : Cannot open device (%s) %d\n", port_name_, errno);
#endif
        exit(-1);
    }
    
    if(tcgetattr(fd_, &tio) < 0) {
#ifdef DEBUG_OUT
        fprintf(stderr, "[ERR] Serial : Cannot get terminal attributes \n");
#endif
        return ;
    }
    
    cfsetspeed(&tio, __dec2baudrate(baud_rate));
    
    
    tio.c_cflag &= ~CSIZE;
    if(     config & SERIAL_CS5) tio.c_cflag |= CS5;
    else if(config & SERIAL_CS6) tio.c_cflag |= CS6;
    else if(config & SERIAL_CS7) tio.c_cflag |= CS7;
    else                         tio.c_cflag |= CS8;
    
    
    if(     config & SERIAL_PARN) { tio.c_cflag &= ~PARENB; }
    else if(config & SERIAL_PARO) { tio.c_cflag |=  PARENB; tio.c_cflag |=  PARODD;}
    else                          { tio.c_cflag |=  PARENB; tio.c_cflag &= ~PARODD;}
    
    if(     config & SERIAL_STOPB1) tio.c_cflag &= ~CSTOPB;
    else                            tio.c_cflag |=  CSTOPB;
    
    
    tio.c_cflag &= ~CRTSCTS;
    tio.c_cflag |= CREAD | CLOCAL;
    tio.c_iflag &= ~(IXON | IXOFF | IXANY);
    
    tio.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
    tio.c_oflag &= ~OPOST;
    tio.c_cc[VMIN] = 0;
    tio.c_cc[VTIME] = 0;
    
    
    tcsetattr( fd_, TCSANOW, &tio );
    
    if( tcsetattr(fd_, TCSAFLUSH, &tio) < 0) {
#ifdef DEBUG_OUT
        fprintf(stderr, "[ERR] Serial : \x1b[31m Cannot set terminal attributes \x1b[39m\n");
#endif
        return ;
    }
    
    sleep(1);
    
#ifdef DEBUG_OUT
    fprintf(stderr, "[INF] Serial : \x1b[32m Opened serial port. \x1b[0m(\x1b[1m%s\x1b[0m) \x1b[39m\n", port_name_);
#endif
}

unsigned char Serial::pop_recv_data(){
    return rb_->pop_left();
}

unsigned char Serial::read_recv_data(int offset){
    return rb_->read_left(offset);
}

int Serial::get_recv_size(){
    return rb_->get_length();
}

void Serial::push_send_data(unsigned char data){
    sb_->push(data);
}

void Serial::set_timeout(long long sec, long long usec){
    wait_time_sec_ = sec;
    wait_time_u_   = usec;
}

void Serial::reset_recv_buf(){
    rb_->reset();
}

void Serial::reset_send_buf(){
    sb_->reset();
}

void Serial::receive(bool is_brocking){
    //printf("recvive\n");
    if(is_brocking)
        pthread_mutex_lock(&m_); // lock (brocking)
    else
        pthread_mutex_trylock(&m_); // lock (non brocking)
    
    FD_ZERO(&set_);
    FD_SET(fd_, &set_);
    
    rv_ = select(fd_+1, &set_, NULL, NULL, &timeout_);
    timeout_.tv_sec  = wait_time_sec_;
    timeout_.tv_usec = wait_time_u_;
    
    if(rv_ <= 0){
        usleep(10);
        return;
    }
    
    int ret = read(fd_, tmp_rb_, 512);
    
    if(ret < 0){
#ifdef DEBUG_OUT
        fprintf(stderr, "[ERR] Serial : \x1b[31m No data received. \x1b[39m\n");
#endif
        return;
    }else{
#ifdef DEBUG_OUT_ON_RECV
        fprintf(stdout, "[INF] Serial : \x1b[32m Received data byte size \x1b[0m(\x1b[1m%d\x1b[0m) \x1b[39m\n", ret);
#endif
    }
    
    for(int i=0; i<ret; i++){
        // printf("%02X ", tmp_rb_[i] & 0x000000FF);
        rb_->push(tmp_rb_[i]);
    }
    
    //printf("\n");
    
    fflush(stdout);
    
    pthread_mutex_unlock(&m_); // unlock
    return;
}


void Serial::send(bool is_brocking){
    if(is_brocking)
        pthread_mutex_lock(&m_); // lock (brocking)
    else
        pthread_mutex_trylock(&m_); // lock (non brocking)
    
    tcflush(fd_, TCIOFLUSH);
    
    long long int send_len = sb_->get_length();
    
    for(int i=0; i<send_len; i++){
        tmp_sb_[i] = sb_->pop_left();
    }
    
    write(fd_, tmp_sb_, send_len);
    pthread_mutex_unlock(&m_); // unlock
}

void Serial::end(){
    close(fd_);
#ifdef DEBUG_OUT
    fprintf(stderr, "[INF] Serial : \x1b[32m Closed serial port. (\x1b[1m%s\x1b[0m) \x1b[39m\n", port_name_);
#endif
}
