//
//  RingDeque.hpp
//  PressSensor
//
//  Created by Tomo Kikuchi on 2022/12/05.
//

#ifndef RingDeque_hpp
#define RingDeque_hpp

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

template<class T>
class RingDeque {
private:
    T *buf_;
    
    long long int size_;
    long long int len_;
    
    int head_;
    int tail_;
public:
    RingDeque(long long int size);
    ~RingDeque();
    
    long long int get_buffer_size();
    long long int get_length();
    
    void push(T data);
    void write(T data, int offset);
    T pop();
    T read(int offset);
    
    void push_left(T data);
    void write_left(T data, int offset);
    T pop_left();
    T read_left(int offset);
    
    void print(const char* format);
    void println(const char* format);
    
    
    void zero_reset();
    void reset();
};

#endif /* RingDeque_hpp */
