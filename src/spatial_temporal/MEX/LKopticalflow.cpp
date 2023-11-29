#include "stdio.h"
#include "mex.h"
#include <iostream>
#include <vector>

#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/video/tracking.hpp>

using namespace std;
using namespace cv;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	if (nrhs != 3)
		mexErrMsgTxt("Three inputs required.");
	unsigned char *prevData = (unsigned char *)mxGetPr(prhs[0]);   //获得指向输入图像矩阵的指�?
	unsigned char *nextData = (unsigned char *)mxGetPr(prhs[1]);   //获得指向输入图像矩阵的指�?
	double *prevPoints = (double *)mxGetPr(prhs[2]); //�?跟踪的特征点
	int rows = mxGetM(prhs[0]);
	int cols = mxGetN(prhs[0]);
	int pcount = mxGetM(prhs[2]);
	int channel = mxGetNumberOfDimensions(prhs[0]); //灰度图为2，彩色图�?3
	if (channel > 2)
		mexErrMsgTxt("Can not input an rgb image.");
	plhs[0] = mxCreateDoubleMatrix(pcount, 2, mxREAL); // nextPts_out
	plhs[1] = mxCreateDoubleMatrix(pcount, 1, mxREAL); // status
	plhs[2] = mxCreateDoubleMatrix(pcount, 1, mxREAL); // err

	double *nextPts_out = mxGetPr(plhs[0]);
	double *status_out = mxGetPr(plhs[1]);
	double *err_out = mxGetPr(plhs[2]);

	Mat prevImg(rows, cols, CV_8U);
	Mat nextImg(rows, cols, CV_8U);
	vector<Point2f> prevPts;
	vector<Point2f> nextPts;
	int i, j, k;
	for (i = 0; i < cols; i++)
		for (j = 0; j < rows; j++)
		{
			int idx = i*rows + j;
			prevImg.at<unsigned char>(j, i) = prevData[idx];
			nextImg.at<unsigned char>(j, i) = nextData[idx];
		}
	for (i = 0; i < pcount; i++)
		prevPts.push_back(Point2f(prevPoints[i]-1,prevPoints[i + pcount]-1));

	vector<uchar> status;
	vector<float> err;
	/*namedWindow("img1", CV_WINDOW_AUTOSIZE);
	namedWindow("img2", CV_WINDOW_AUTOSIZE);
	imshow("img1", prevImg);
	imshow("img2", nextImg);
	waitKey(0);*/
	calcOpticalFlowPyrLK(prevImg, nextImg, prevPts, nextPts, status, err);
	for (i = 0; i < pcount; i++)
	{
		nextPts_out[i + pcount] = nextPts[i].y+1;
		nextPts_out[i] =  nextPts[i].x+1;
		status_out[i] = status[i];
		err_out[i] = err[i];
	}
	return;
}