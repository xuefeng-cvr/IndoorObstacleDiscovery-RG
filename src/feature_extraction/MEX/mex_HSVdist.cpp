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

double compute_cosine(cv::Mat leftMat, cv::Mat rightMat)
{
    cv::Mat a, b, ab;
    double sum_a = 0, sum_b = 0, sum_ab = 0, result;
    a = leftMat * leftMat.t();
    b = rightMat * rightMat.t();
    ab = leftMat * rightMat.t();

    sum_a = a.ptr<double>(0)[0];
    sum_b = b.ptr<double>(0)[0];
    sum_ab = ab.ptr<double>(0)[0];
    result = 1 - (sum_ab / (sqrt(sum_a) * sqrt(sum_b)));
    return result;
}

template <typename T>
void fillmat(T *I_data, Mat &I)
{
    memcpy(I.ptr<T>(0), I_data, sizeof(T) * I.rows * I.cols);
    I = I.t();
    return;
}

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    /* Check for proper number of arguments */
    if (nrhs != 3)
    {
        mexErrMsgTxt("Three input arguments required.");
    }
    else if (nlhs > 3)
    {
        mexErrMsgTxt("Too many output arguments.");
    }

    int *f_bbox = (int *)mxGetPr(prhs[0]);
    int *b_bbox = (int *)mxGetPr(prhs[1]);
    double *intehsv = (double *)mxGetPr(prhs[2]);

    int M = mxGetM(prhs[0]);
    int N = mxGetN(prhs[0]);
    cv::Mat f_bboxMat(N, M, CV_32S);
    fillmat<int>(f_bbox, f_bboxMat);

    cv::Mat b_bboxMat(N, M, CV_32S);
    fillmat<int>(b_bbox, b_bboxMat);

    int height, width, channels;
    const long unsigned int *dim;
    dim = mxGetDimensions(prhs[2]);

    height = (int)*dim;
    width = (int)*(dim + 1);
    channels = (int)*(dim + 2);

    f_bboxMat = f_bboxMat - 1;
    b_bboxMat = b_bboxMat - 1;

    auto r_b = f_bboxMat.rows;
    typedef cv::Vec<int, 49> Vec49d;

    /**/
    cv::Mat hsiFeat_back = cv::Mat::zeros(r_b, 49, CV_64F);
    cv::Mat hsiFeat_fore = cv::Mat::zeros(r_b, 49, CV_64F);
    cv::Mat hsv_dist = cv::Mat::zeros(r_b, 3, CV_64F);

    int minY, minX, maxX, maxY;
    for (int i = 0; i < r_b; i++)
    {
        int *row_b = b_bboxMat.ptr<int>(i);
        minX = row_b[0];
        minY = row_b[1];
        maxX = row_b[2] + 1;
        maxY = row_b[3] + 1;
        for (int j = 0; j < 49; j++)
        {
            // hsiFeat_back.ptr<double>(i)[j]=double(intehsvMat.at<Vec49d>(maxY,maxX)[j]+intehsvMat.at<Vec49d>(minY,minX)[j]-intehsvMat.at<Vec49d>(minY,maxX)[j]-intehsvMat.at<Vec49d>(maxY,minX)[j]);
            hsiFeat_back.ptr<double>(i)[j] = double(intehsv[j * height * width + height * maxX + maxY] + intehsv[j * height * width + height * minX + minY] - intehsv[j * height * width + height * maxX + minY] - intehsv[j * height * width + height * minX + maxY]);
        }

        int *row_f = f_bboxMat.ptr<int>(i);
        minX = row_f[0];
        minY = row_f[1];
        maxX = row_f[2] + 1;
        maxY = row_f[3] + 1;
        for (int j = 0; j < 49; j++)
        {
            // hsiFeat_fore.ptr<double>(i)[j]=double(intehsvMat.at<Vec49d>(maxY,maxX)[j]+intehsvMat.at<Vec49d>(minY,minX)[j]-intehsvMat.at<Vec49d>(minY,maxX)[j]-intehsvMat.at<Vec49d>(maxY,minX)[j]);
            hsiFeat_fore.ptr<double>(i)[j] = double(intehsv[j * height * width + height * maxX + maxY] + intehsv[j * height * width + height * minX + minY] - intehsv[j * height * width + height * maxX + minY] - intehsv[j * height * width + height * minX + maxY]);
        }
        hsiFeat_back.ptr<double>(i)[0] = hsiFeat_back.ptr<double>(i)[0] + hsiFeat_back.ptr<double>(i)[16];
        hsiFeat_fore.ptr<double>(i)[0] = hsiFeat_fore.ptr<double>(i)[0] + hsiFeat_fore.ptr<double>(i)[16];
        hsiFeat_back.ptr<double>(i)[16] = 0;
        hsiFeat_fore.ptr<double>(i)[16] = 0;
    }

    hsiFeat_back = hsiFeat_back - hsiFeat_fore;

    for (int i = 0; i < r_b; i++)
    {
        hsv_dist.ptr<double>(i)[0] = compute_cosine(hsiFeat_back(Rect(Point(0, i), Point(16, i + 1))), hsiFeat_fore(Rect(Point(0, i), Point(16, i + 1))));
        hsv_dist.ptr<double>(i)[1] = compute_cosine(hsiFeat_back(Rect(Point(16, i), Point(33, i + 1))), hsiFeat_fore(Rect(Point(16, i), Point(33, i + 1))));
        hsv_dist.ptr<double>(i)[2] = compute_cosine(hsiFeat_back(Rect(Point(33, i), Point(49, i + 1))), hsiFeat_fore(Rect(Point(33, i), Point(49, i + 1))));
    }

    plhs[0] = mxCreateDoubleMatrix(hsv_dist.rows, hsv_dist.cols, mxREAL);

    hsv_dist = hsv_dist.t();
    double *out = (double *)mxGetPr(plhs[0]);
    memcpy(out, hsv_dist.ptr<double>(0), sizeof(double) * hsv_dist.rows * hsv_dist.cols);
}
