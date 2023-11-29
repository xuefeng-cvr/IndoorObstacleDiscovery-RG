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
    if (nrhs != 5) { 
    	mexErrMsgTxt("Five input arguments required."); 
    } else if (nlhs > 5) {
        mexErrMsgTxt("Too many output arguments."); 
    }

    double *e1 = (double *)mxGetPr(prhs[0]);
    double *e2 = (double *)mxGetPr(prhs[1]);
    double *H = (double *)mxGetPr(prhs[2]);
    double *S = (double *)mxGetPr(prhs[3]);
    double *V = (double *)mxGetPr(prhs[4]);

    int M=mxGetM(prhs[0]);
    int N=mxGetN(prhs[0]);
    cv::Mat e1Mat(N,M,CV_64F);
    fillmat<double>(e1,e1Mat);

    M=mxGetM(prhs[1]);
    N=mxGetN(prhs[1]);
    cv::Mat e2Mat(N,M,CV_64F);
    fillmat<double>(e2,e2Mat);

    M=mxGetM(prhs[2]);
    N=mxGetN(prhs[2]);
    cv::Mat HMat(N,M,CV_64F);
    fillmat<double>(H,HMat);

    cv::Mat SMat(N,M,CV_64F);
    fillmat<double>(S,SMat);

    cv::Mat VMat(N,M,CV_64F);
    fillmat<double>(V,VMat);

    cv::Mat mask,merge_HSV;

    auto r =HMat.rows , c =HMat.cols,e1_num=e1Mat.cols-1,e2_num=e2Mat.cols-1;

    cv::Mat mask_inte=cv::Mat::zeros(r + 1, c + 1, CV_64F);
    cv::Mat sqsum=cv::Mat::zeros(r + 1, c + 1, CV_64F);

    mwSize dim[3] = {(mwSize)(r + 1), (mwSize)(c + 1), 49};
    plhs[0] = mxCreateNumericArray(3, dim, mxDOUBLE_CLASS, mxREAL);

    MatlabMultiArray3<double> ret(plhs[0]);
    double *out = (double *)mxGetPr(plhs[0]);

    int count_channel = 0;

    for (int i = 0; i < e1_num; i++){
        mask=((HMat >=e1Mat.ptr<double>(0)[i])&(HMat < e1Mat.ptr<double>(0)[i+1]))/255;
        mask.convertTo(mask,CV_64F);
        integral(mask, mask_inte, sqsum, CV_64F, CV_64F);
        mask_inte = mask_inte.t();
        memcpy(out+count_channel*(r+1)*(c+1), mask_inte.ptr<double>(0), sizeof(double)*(r+1)*(c+1));
        count_channel++;
    }
    for (int i = 0; i < e2_num; i++){
        mask=((SMat >=e2Mat.ptr<double>(0)[i])&(SMat < e2Mat.ptr<double>(0)[i+1]))/255;
        mask.convertTo(mask,CV_64F);
        integral(mask, mask_inte, sqsum, CV_64F, CV_64F);
        mask_inte = mask_inte.t();
        memcpy(out+count_channel*(r+1)*(c+1), mask_inte.ptr<double>(0), sizeof(double)*(r+1)*(c+1));
        count_channel++;
    }
    for (int i = 0; i < e2_num; i++){
        mask=((VMat >=e2Mat.ptr<double>(0)[i])&(VMat < e2Mat.ptr<double>(0)[i+1]))/255;
        mask.convertTo(mask,CV_64F);
        integral(mask, mask_inte, sqsum, CV_64F, CV_64F);
        mask_inte = mask_inte.t();
        memcpy(out+count_channel*(r+1)*(c+1), mask_inte.ptr<double>(0), sizeof(double)*(r+1)*(c+1));
        count_channel++;
    }
}
