//
//  DigitalSignalProcessing.hpp
//  PressSensor
//
//  Created by Tomo Kikuchi on 2023/08/23.
//

#ifndef DigitalSignalProcessing_hpp
#define DigitalSignalProcessing_hpp

#include <stdio.h>
#include <math.h>

#define TYPE_LPF (0x01)
#define TYPE_HPF (0x02)

namespace DSP{

class Bq{
public:
    double x1, x2;
    double y1, y2;
    double c0,c1,c2,c3,c4;
    
    Bq(){
        bq_clearbuf();
        bq_clearcoef();
    }
    
public:
    inline double process(double in){
        double y0 = 0.0;
        y0 += c0 * in;
        y0 += c1 * x1;
        y0 += c2 * x2;
        y0 -= c3 * y1;
        y0 -= c4 * y2;
       
        x2 = x1; x1 = in;
        y2 = y1; y1 = y0;
        
        return y0;
    }
    
    void bq_init(){
        bq_clearbuf();
        bq_clearcoef();
    }
    
    inline void bq_clearbuf(){
        x1 = x2 = 0.0;
        y1 = y2 = 0.0;
    }
    
    inline void bq_clearcoef(){
        c0 = c1 = c2 = c3 = c4 = 0.0;
    }
    
    void coef_lpf(double fc, double q, double fs){
        double w0 = 2.0*M_PI*fc/fs;
        double alpha = 0.5*sin(w0)/q;
        double b0 = (1 - cos(w0))/2;
        double b1 = 1 - cos(w0);
        double b2 = (1 - cos(w0))/2;
        double a0 = 1 + alpha;
        double a1 = -2*cos(w0);
        double a2 = 1 - alpha;
        
        c0 = b0/a0;
        c1 = b1/a0;
        c2 = b2/a0;
        c3 = a1/a0;
        c4 = a2/a0;
    }
    
    void coef_hpf(double fc, double q, double fs){
        double w0 = 2.0*M_PI*fc/fs;
        double alpha = 0.5*sin(w0)/q;
        double b0 = (1 + cos(w0))/2;
        double b1 = -(1 + cos(w0));
        double b2 = (1 + cos(w0))/2;
        double a0 = 1 + alpha;
        double a1 = -2*cos(w0);
        double a2 = 1 - alpha;
        
        c0 = b0/a0;
        c1 = b1/a0;
        c2 = b2/a0;
        c3 = a1/a0;
        c4 = a2/a0;
    }
    
};

class Butrerworth{
private:
    int order_;
    int nbq_;
    int type_;
    double fs_;
    double fc_;
    Bq *fils_;
   
    void bw_coefs_lpf(Bq *fils){
        double fc = fc_;
        double fs = fs_;
        int n = order_;
        int nbq = nbq_;
        
        // Each processing
        for(int k=0; k<nbq; k++){
            // Generate IIR Filter
            double w = 2 * M_PI * fc/fs; // wc
            double c = cos(w);
            double s = sin(w);
            double a; // as alpha_k,n
            if(n%2==0) a = s * cos( M_PI * (n-2*k-1) / (2*n) ); // order = even
            else       a = s * cos( M_PI * (n-2*k+1) / (2*n) ); // order = odd
            
            // order = odd: first process block
            if(n%2==1 && k==0){
                double b0 = s;
                double b1 = s;
                double b2 = 0;
                double a0 = (s+c+1);
                double a1 = (s-c-1);
                double a2 = 0;
                fils[k].c0 = b0/a0;
                fils[k].c1 = b1/a0;
                fils[k].c2 = b2/a0;
                fils[k].c3 = a1/a0;
                fils[k].c4 = a2/a0;
                continue;
            }
            
            // other process block
            double b0 = (1-c)/2;
            double b1 = (1-c);
            double b2 = (1-c)/2;
            double a0 =  1+a;
            double a1 = -2*c;
            double a2 =  1-a;
            fils[k].c0 = b0/a0;
            fils[k].c1 = b1/a0;
            fils[k].c2 = b2/a0;
            fils[k].c3 = a1/a0;
            fils[k].c4 = a2/a0;
        }
    }
    
    
    void bw_coefs_hpf(Bq *fils){
        double fc = fc_;
        double fs = fs_;
        int n = order_;
        int nbq = nbq_;
        
        // Each processing
        for(int k=0; k<nbq; k++){
            // Generate IIR coef
            double w = 2 * M_PI * fc/fs;
            double c = cos(w);
            double s = sin(w);
            double a; //as alpha_k,n
            if(n%2==0) a = s * cos( M_PI * (n-2*k-1) / (2*n) );// order even
            else       a = s * cos( M_PI * (n-2*k+1) / (2*n) );// order odd
            
            // order = odd: first process block
            if(n%2==1 && k==0){
                double b0 = +(1+c);
                double b1 = -(1+c);
                double b2 = 0;
                double a0 = (s+c+1);
                double a1 = (s-c-1);
                double a2 = 0;
                fils[k].c0 = b0/a0;
                fils[k].c1 = b1/a0;
                fils[k].c2 = b2/a0;
                fils[k].c3 = a1/a0;
                fils[k].c4 = a2/a0;
                continue;
            }
            
            // other process block
            double b0 =  (1+c)/2;
            double b1 = -(1+c);
            double b2 =  (1+c)/2;
            double a0 =  1+a;
            double a1 = -2*c;
            double a2 =  1-a;
            fils[k].c0 = b0/a0;
            fils[k].c1 = b1/a0;
            fils[k].c2 = b2/a0;
            fils[k].c3 = a1/a0;
            fils[k].c4 = a2/a0;
        }
    }
    
    double bw_proc(double in){
        int nbq = nbq_;
        double val = in;
        for(int i=0;i<nbq;i++){
            val = fils_[i].process(val);
        }
        return val;
    }
    
    bool isBypassed_ = true;
    
    void setBypass(bool isBypassed){
        isBypassed_ = isBypassed;
    }
    
public:
    Butrerworth(int order = 7, int type = TYPE_LPF, double fs = 115.108, double fc = 20){
        nbq_ = (order + 1) / 2;
        type_ = type;
        order_ = order;
        
        fs_ = fs;
        fc_ = fc;
        
        fils_ = new Bq[nbq_];
        
        for(int i=0; i<nbq_; i++){
            // Set coef
            if( type == TYPE_HPF){
                bw_coefs_hpf(fils_);
            }else if(type == TYPE_LPF){
                bw_coefs_lpf(fils_);
            }
        }
    }
    
    void setCutoff(double fc, int type = TYPE_LPF){
        setBypass(true);
        fc_ = fc;
        for(int i=0; i<nbq_; i++){
            if( type == TYPE_HPF){
                bw_coefs_hpf(fils_);
            }else if(type == TYPE_LPF){
                bw_coefs_lpf(fils_);
            }
        }
        setBypass(false);
    }
    
    ~Butrerworth(){
        delete[] fils_;
    }
      
    inline double process(double din){
        if(isBypassed_){
            return din;
        }else{
            return bw_proc(din);
        }
        
    }
};
};
#endif /* DigitalSignalProcessing_hpp */
