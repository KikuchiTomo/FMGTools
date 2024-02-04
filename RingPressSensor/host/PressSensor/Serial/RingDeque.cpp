//
//  RingDeque.cpp
//  PressSensor
//
//  Created by Tomo Kikuchi on 2022/12/05.
//

#include "RingDeque.hpp"

template<class T>
RingDeque<T>::RingDeque(long long int size){
    size_ = size;
    len_ = 0;
    
    head_ = 0;
    tail_ = 0;
    
    buf_ = (T*) malloc (sizeof(T) * size);
}

template<class T>
RingDeque<T>::~RingDeque(){
    free(buf_);
}

template<class T>
long long int RingDeque<T>::get_buffer_size(){
    return size_;
}

template<class T>
long long int RingDeque<T>::get_length(){
    return len_;
}

template<class T>
void RingDeque<T>::zero_reset(){
    for(long long int i=0; i<size_; i++){
        
        buf_[i] = 0;
    }
}

template<class T>
void RingDeque<T>::reset(){
    zero_reset();
    head_ = 0;
    tail_ = 0;
    len_  = 0;
}

template <class T>
void RingDeque<T>::push(T data){
    if(size_>0 && len_<size_){
        head_ = (size_ + head_ - 1) % size_;
        buf_[head_] = data;
        len_++;
    }
}

template <class T>
void RingDeque<T>::write(T data, int offset){
    if(len_>0 && size_>0 && len_>offset){
        int tmp = head_;
        tmp = (tmp + size_ + offset) % size_;
        buf_[tmp] = data;
    }
}

template <class T>
T RingDeque<T>::pop(){
    T tmp_ret = 0;
    if(len_>0 && size_>0){
        tmp_ret = buf_[head_];
        head_ = (size_ + head_ + 1) % size_;
        len_--;
    }
    return tmp_ret;
}

template <class T>
T RingDeque<T>::read(int offset){
    T tmp_ret = 0;
    if(len_>0 && size_>0){
        int tmp = head_;
        tmp = (tmp + size_ + offset) % size_;
        tmp_ret = buf_[tmp];
    }
    return tmp_ret;
}

template <class T>
void RingDeque<T>::push_left(T data){
    if(size_>0 && len_<size_){
        buf_[tail_] = data;
        tail_ = (size_ + tail_ + 1) % size_;
        len_++;
    }
}

template <class T>
void RingDeque<T>::write_left(T data, int offset){
    if(len_>0 && size_>0){
        int tmp = tail_;
        tmp = (tmp + size_ - offset - 1) % size_;
        buf_[tmp] = data;
    }
}

template <class T>
T RingDeque<T>::pop_left(){
    T tmp_ret = 0;
    if(len_>0 && size_>0){
        tail_ = (size_ + tail_ - 1) % size_;
        tmp_ret = buf_[tail_];
        len_--;
    }
    return tmp_ret;
}

template <class T>
T RingDeque<T>::read_left(int offset){
    T tmp_ret = 0;
    if(len_>0 && size_>0){
        int tmp = tail_;
        tmp = (tmp + size_ - offset - 1) % size_;
        tmp_ret = buf_[tmp];
    }
    return tmp_ret;
}

template <class T>
void RingDeque<T>::print(const char* format){
    for(int i=0; i<len_; i++){
        printf(format, read_left(i));
    }
}

template <class T>
void RingDeque<T>::println(const char* format){
    for(int i=0; i<len_; i++){
        printf(format, read_left(i));
    }
    printf("\n");
}

template class RingDeque<char>;
template class RingDeque<float>;
template class RingDeque<double>;

template class RingDeque<uint8_t>;
template class RingDeque<uint16_t>;
template class RingDeque<uint32_t>;
template class RingDeque<uint64_t>;

template class RingDeque<int8_t>;
template class RingDeque<int16_t>;
template class RingDeque<int32_t>;
template class RingDeque<int64_t>;
