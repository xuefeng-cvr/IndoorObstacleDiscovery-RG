#include "mex.h"

#include <iostream>
#include <set>
#include <map>
#include <list>
#include <vector>
#include <string.h>
#include <opencv2/opencv.hpp>
// #include "opencv2/core/core.hpp"
#include "matlab_multiarray.hpp"
using namespace std;
using namespace cv;

template <typename T>
void fillmat(T *I_data, Mat& I)
{
    memcpy(I.ptr<T>(0), I_data, sizeof(T)*I.rows*I.cols);
    I = I.t();
    return;
}

void mexFunction( int nlhs, mxArray *plhs[], 
        		  int nrhs, const mxArray*prhs[] )
{    
    /* Check for proper number of arguments */
    if (nrhs != 8) { 
    	mexErrMsgTxt("Eight input arguments required."); 
    } else if (nlhs > 8) {
        mexErrMsgTxt("Too many output arguments."); 
    }

    double *H = (double *)mxGetPr(prhs[0]);
    double *S = (double *)mxGetPr(prhs[1]);
    double *V = (double *)mxGetPr(prhs[2]);
    double *H2 = (double *)mxGetPr(prhs[3]);
    double *S2 = (double *)mxGetPr(prhs[4]);
    double *V2 = (double *)mxGetPr(prhs[5]);
    int *b = (int *)mxGetPr(prhs[6]);
    double *area = (double *)mxGetPr(prhs[7]);

    int M=mxGetM(prhs[0]);
    int N=mxGetN(prhs[0]);
    cv::Mat HMat(N,M,CV_64F);
    fillmat<double>(H,HMat);

    cv::Mat SMat(N,M,CV_64F);
    fillmat<double>(S,SMat);

    cv::Mat VMat(N,M,CV_64F);
    fillmat<double>(V,VMat);

    cv::Mat H2Mat(N,M,CV_64F);
    fillmat<double>(H2,H2Mat);

    cv::Mat S2Mat(N,M,CV_64F);
    fillmat<double>(S2,S2Mat);

    cv::Mat V2Mat(N,M,CV_64F);
    fillmat<double>(V2,V2Mat);

    M=mxGetM(prhs[6]);
    N=mxGetN(prhs[6]);
    cv::Mat bMat(N,M,CV_32S);
    fillmat<int>(b,bMat);

    M=mxGetM(prhs[7]);
    N=mxGetN(prhs[7]);
    cv::Mat areaMat(N,M,CV_64F);
    fillmat<double>(area,areaMat);

    bMat = bMat - 1;

    auto r =HMat.rows,c =HMat.cols,r_b=bMat.rows;
    double H_sum,S_sum,V_sum,H2_sum,S2_sum,V2_sum,h_var,s_var,v_var;
    int minY,minX,maxX,maxY;
    //cv::Mat H_sum = cv::Mat::ones(r,1, CV_64FC1);
    //cv::Mat S_sum = cv::Mat::ones(r,1, CV_64FC1);
    //cv::Mat V_sum = cv::Mat::ones(r,1, CV_64FC1);
    //cv::Mat H2_sum = cv::Mat::ones(r,1, CV_64FC1);
    //cv::Mat S2_sum = cv::Mat::ones(r,1, CV_64FC1);
    //cv::Mat V2_sum = cv::Mat::ones(r,1, CV_64FC1);

    cv::Mat sqsum = cv::Mat::zeros(r + 1, c + 1, CV_64F);
    cv::Mat H_inte = cv::Mat::zeros(r + 1, c + 1, CV_64F);
    cv::Mat S_inte = cv::Mat::zeros(r + 1, c + 1, CV_64F);
    cv::Mat V_inte = cv::Mat::zeros(r + 1, c + 1, CV_64F);
    cv::Mat H2_inte = cv::Mat::zeros(r + 1, c + 1, CV_64F);
    cv::Mat S2_inte = cv::Mat::zeros(r + 1, c + 1, CV_64F);
    cv::Mat V2_inte = cv::Mat::zeros(r + 1, c + 1, CV_64F);
    cv::Mat hsv_std = cv::Mat::zeros(r_b, 3, CV_64F);

    integral(HMat, H_inte, sqsum, CV_64F, CV_64F);
    integral(SMat, S_inte, sqsum, CV_64F, CV_64F);
    integral(VMat, V_inte, sqsum, CV_64F, CV_64F);
    integral(H2Mat, H2_inte, sqsum, CV_64F, CV_64F);
    integral(S2Mat, S2_inte, sqsum, CV_64F, CV_64F);
    integral(V2Mat, V2_inte, sqsum, CV_64F, CV_64F);

    for (int i = 0; i < r_b; i++){
        int* row= bMat.ptr<int>(i);
        minX=row[0];
        minY=row[1];
        maxX=row[2]+1;
        maxY=row[3]+1;
            
        H_sum=H_inte.ptr<double>(maxY)[maxX]+H_inte.ptr<double>(minY)[minX]-H_inte.ptr<double>(minY)[maxX]-H_inte.ptr<double>(maxY)[minX];
        S_sum=S_inte.ptr<double>(maxY)[maxX]+S_inte.ptr<double>(minY)[minX]-S_inte.ptr<double>(minY)[maxX]-S_inte.ptr<double>(maxY)[minX];
        V_sum=V_inte.ptr<double>(maxY)[maxX]+V_inte.ptr<double>(minY)[minX]-V_inte.ptr<double>(minY)[maxX]-V_inte.ptr<double>(maxY)[minX];
        H2_sum=H2_inte.ptr<double>(maxY)[maxX]+H2_inte.ptr<double>(minY)[minX]-H2_inte.ptr<double>(minY)[maxX]-H2_inte.ptr<double>(maxY)[minX];
        S2_sum=S2_inte.ptr<double>(maxY)[maxX]+S2_inte.ptr<double>(minY)[minX]-S2_inte.ptr<double>(minY)[maxX]-S2_inte.ptr<double>(maxY)[minX];
        V2_sum=V2_inte.ptr<double>(maxY)[maxX]+V2_inte.ptr<double>(minY)[minX]-V2_inte.ptr<double>(minY)[maxX]-V2_inte.ptr<double>(maxY)[minX];
        //printf("2");

        //h_var=(H2_sum-areaMat.ptr<double>(i)[0]*(H_sum/areaMat.ptr<double>(i)[0])*(H_sum/areaMat.ptr<double>(i)[0]));
        //s_var=(S2_sum-areaMat.ptr<double>(i)[0]*(S_sum/areaMat.ptr<double>(i)[0])*(S_sum/areaMat.ptr<double>(i)[0]));
        //v_var=(V2_sum-areaMat.ptr<double>(i)[0]*(V_sum/areaMat.ptr<double>(i)[0])*(V_sum/areaMat.ptr<double>(i)[0]));

        h_var=(H2_sum-H_sum*(H_sum/areaMat.ptr<double>(i)[0]));
        s_var=(S2_sum-S_sum*(S_sum/areaMat.ptr<double>(i)[0]));
        v_var=(V2_sum-V_sum*(V_sum/areaMat.ptr<double>(i)[0]));

        if(h_var<0) h_var = 0;
        if(s_var<0) s_var = 0;
        if(v_var<0) v_var = 0;

        //printf("3");
        double* p= hsv_std.ptr<double>(i);
        p[0]=h_var;
        p[1]=s_var;
        p[2]=v_var;
        //printf("%d %d %d %d\n",row[0],row[1],row[2],row[3]);
        //printf("%d %d %d %d\n",minY,minX,maxY,maxX);
        //printf("i:%d\n",i);
    }

    plhs[0] = mxCreateDoubleMatrix(hsv_std.rows, hsv_std.cols, mxREAL);

    hsv_std = hsv_std.t();
    double *out = (double *)mxGetPr(plhs[0]);
    memcpy(out, hsv_std.ptr<double>(0), sizeof(double)*hsv_std.rows*hsv_std.cols);
}

