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

bool equal(double num1,double num2)
{
    if (fabs(num1-num2) < 0.000001)
            return true;
        else return false;
}

bool big_than(double num1,double num2)
{
    if(num1-num2>0.000001)
            return true;
        else return false;
}

void mode(std::vector<double> ucmPatch_no0,double &max,int &flag)
{	
    int t=0;
    double now=0;
    for (int i = 0; i <ucmPatch_no0.size(); i++){
        if(equal(ucmPatch_no0[i],now))
        {
            t++;
        }
        else
        {
            now=ucmPatch_no0[i];
            t=1;
        }
        if (t>=flag)
        {
            flag=t;
            max=ucmPatch_no0[i];	
        }
    }
}

template <typename T>
void fillmat(T *I_data, Mat& I)
{
    // int i,j;
    // for(i=0; i<I.rows; i++)
    // {
    //     for(j=0; j<I.cols; j++)
    //     {
    //         I.at<T>(i,j) = I_data[i+j*I.rows];
    //     }
    // }

    memcpy(I.ptr<T>(0), I_data, sizeof(T)*I.rows*I.cols);
    I = I.t();

    return;
}

void mexFunction( int nlhs, mxArray *plhs[], 
        		  int nrhs, const mxArray*prhs[] )
{    
    /* Check for proper number of arguments */
    if (nrhs != 6) { 
    	mexErrMsgTxt("Six input arguments required."); 
    } else if (nlhs > 6) {
        mexErrMsgTxt("Too many output arguments."); 
    }

    clock_t start,finish,start1,finish1;

    float *ucm = (float *)mxGetPr(prhs[0]);
    float *ucm_0 = (float *)mxGetPr(prhs[1]);
    float *b = (float *)mxGetPr(prhs[2]);
    int *r = (int *)mxGetPr(prhs[3]);
    int *r_c = (int *)mxGetPr(prhs[4]);
    double *skip = (double *)mxGetPr(prhs[5]);

    int M=mxGetM(prhs[0]);
    int N=mxGetN(prhs[0]);
    cv::Mat ucmMat(N,M,CV_32F);
    fillmat<float>(ucm,ucmMat);

    cv::Mat ucm_0Mat(N,M,CV_32F);
    fillmat<float>(ucm_0,ucm_0Mat);

    M=mxGetM(prhs[2]);
    N=mxGetN(prhs[2]);
    cv::Mat bMat(N,M,CV_32F);
    fillmat<float>(b,bMat);

    M=mxGetM(prhs[3]);
    N=mxGetN(prhs[3]);
    cv::Mat rMat(N,M,CV_32S);
    fillmat<int>(r,rMat);

    cv::Mat r_cMat(N,M,CV_32S);
    fillmat<int>(r_c,r_cMat);

    M=mxGetM(prhs[5]);
    N=mxGetN(prhs[5]);
    cv::Mat skipMat(N,M,CV_64F);
    fillmat<double>(skip,skipMat);

    rMat = rMat - 1;
    r_cMat = r_cMat - 1;

    ucmMat.convertTo(ucmMat, CV_64F);
    ucm_0Mat.convertTo(ucm_0Mat, CV_64F);
    bMat.convertTo(bMat, CV_64F);
    auto r_ucm=ucmMat.rows,c_ucm=ucmMat.cols,r_b=bMat.rows;

    cv::Mat pb_feat = cv::Mat::zeros(r_b, 7, CV_64F);
    cv::Mat sqsum = cv::Mat::zeros(r_ucm + 1, c_ucm + 1, CV_64F);
    cv::Mat ucm_inte = cv::Mat::zeros(r_ucm +1, c_ucm + 1, CV_64F);
    cv::Mat ucm_inte1 = cv::Mat::zeros(r_ucm +1, c_ucm + 1, CV_64F);
    cv::Mat ucm1 = cv::Mat::zeros(r_ucm, c_ucm, CV_64F);
    cv::Mat edge_map_inte = cv::Mat::zeros(r_ucm +1, c_ucm + 1, CV_64F);
    integral(ucmMat, ucm_inte, sqsum, CV_64F, CV_64F);
    integral(ucm_0Mat, edge_map_inte, sqsum, CV_64F, CV_64F);

    double max,inte,totaltime,totaltime_mode,totaltime_other,flag,flag_sum,totaltime_max;
    int minY,minX,maxX,maxY;
    std::vector<cv::Mat>ucm_inte10;
    finish=clock();
    totaltime=(double)(finish-start)/CLOCKS_PER_SEC;
    
    start=clock();
    for (int i = 0; i<10; i++){
        for (int j=0; j <r_ucm; j++){
            for (int k =0; k<c_ucm; k++){
                if(big_than(ucmMat.ptr<double>(j)[k],skipMat.ptr<double>(0)[i]) &&(big_than(skipMat.ptr<double>(0)[i+1],ucmMat.ptr<double>(j)[k])||equal(skipMat.ptr<double>(0)[i+1],ucmMat.ptr<double>(j)[k])))
                    ucm1.ptr<double>(j)[k]=1;
                else{
                    ucm1.ptr<double>(j)[k]=0;
                }
            }
        }
        integral(ucm1, ucm_inte1, sqsum, CV_64F, CV_64F);
        ucm_inte10.push_back(ucm_inte1.clone());
    }
    finish=clock();
    totaltime=(double)(finish-start)/CLOCKS_PER_SEC;

    double minVal; 
    double maxVal; 
    cv::Point minLoc; 
    cv::Point maxLoc;
    totaltime_max=0;
    totaltime_other=0;
    totaltime_mode=0;
    start=clock();	
    for (int i = 0; i <r_b; i++){
        start1=clock();
        int index=0;
        start1=clock();
        int* row_0= rMat.ptr<int>(i);
        minX=row_0[0];
        minY=row_0[1];
        maxX=row_0[2]+1;
        maxY=row_0[3]+1;
        flag=0;
        flag_sum=0;
        for (int j = 0; j <10; j++){
            inte=ucm_inte10[j].ptr<double>(maxY)[maxX]+ucm_inte10[j].ptr<double>(minY)[minX]-ucm_inte10[j].ptr<double>(minY)[maxX]-ucm_inte10[j].ptr<double>(maxY)[minX];
            if(big_than(inte,flag)){
                flag=inte;
                // maxVal=skipMat.ptr<double>(j+1)[0];
                maxVal=skipMat.ptr<double>(0)[j+1];
            }
            flag_sum+=inte;
        }

        pb_feat.ptr<double>(i)[1]=maxVal;
        finish1=clock();
        totaltime_mode+=(double)(finish1-start1)/CLOCKS_PER_SEC;
        pb_feat.ptr<double>(i)[2]=flag/flag_sum;
        start1=clock();

        double s=bMat.ptr<double>(i)[2]*bMat.ptr<double>(i)[3];

        pb_feat.ptr<double>(i)[5]=(ucm_inte.ptr<double>(maxY)[maxX]+ucm_inte.ptr<double>(minY)[minX]-ucm_inte.ptr<double>(minY)[maxX]-ucm_inte.ptr<double>(maxY)[minX])/s;
        pb_feat.ptr<double>(i)[6]=(edge_map_inte.ptr<double>(maxY)[maxX]+edge_map_inte.ptr<double>(minY)[minX]-edge_map_inte.ptr<double>(minY)[maxX]-edge_map_inte.ptr<double>(maxY)[minX])/s;
        

        int* row= r_cMat.ptr<int>(i);
        minX=row[0];
        minY=row[1];
        maxX=row[2]+1;
        maxY=row[3]+1;
        totaltime_other+=(double)(finish1-start1)/CLOCKS_PER_SEC;
        pb_feat.ptr<double>(i)[3]=(ucm_inte.ptr<double>(maxY)[maxX]+ucm_inte.ptr<double>(minY)[minX]-ucm_inte.ptr<double>(minY)[maxX]-ucm_inte.ptr<double>(maxY)[minX])*4/s;
        pb_feat.ptr<double>(i)[4]=(edge_map_inte.ptr<double>(maxY)[maxX]+edge_map_inte.ptr<double>(minY)[minX]-edge_map_inte.ptr<double>(minY)[maxX]-edge_map_inte.ptr<double>(maxY)[minX])*4/s;

        finish1=clock();               
    }
    finish=clock();

    plhs[0] = mxCreateDoubleMatrix(pb_feat.rows, pb_feat.cols, mxREAL);
    // MatlabMultiArray<double> ret(plhs[0]);
    // for(size_t ii=0; ii<pb_feat.rows; ++ii)
    // {
    //     for (size_t jj=0; jj<pb_feat.cols; ++jj)
    //     {
    //         ret[ii][jj] = pb_feat.ptr<double>(ii)[jj];
    //     }
    // }

    pb_feat = pb_feat.t();
    double *out = (double *)mxGetPr(plhs[0]);
    memcpy(out, pb_feat.ptr<double>(0), sizeof(double)*pb_feat.rows*pb_feat.cols);

}

