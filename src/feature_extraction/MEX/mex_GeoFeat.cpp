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

cv::Mat get_map(cv::Mat edge_geo, int index, int H, int W)
{
    cv::Mat map = cv::Mat::zeros(H, W, CV_64F);
    int i, x, y;
    for (i = 0; i < edge_geo.rows; i++)
    {
        x = (int)edge_geo.at<double>(i, 0);
        y = (int)edge_geo.at<double>(i, 1);
        map.at<double>(y, x) = edge_geo.at<double>(i, index);
    }
    return map;
}

cv::Mat bwlabel(cv::Mat map)
{
    cv::Mat bwmap = cv::Mat::zeros(map.rows, map.cols, CV_64F);
    for (int i = 0; i < map.rows; i++)
    {
        for (int j = 0; j < map.cols; j++)
        {
            if (map.at<double>(i, j) > 0)
            {
                bwmap.at<double>(i, j) = 1;
            }
        }
    }
    return bwmap;
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

    int *bbox_orgin = (int *)mxGetPr(prhs[0]);
    double *edge_geo_orgin = (double *)mxGetPr(prhs[1]);
    double forward = (double)mxGetScalar(prhs[2]);

    int M = mxGetM(prhs[0]);
    int N = mxGetN(prhs[0]);
    cv::Mat bbox(N, M, CV_32S);
    fillmat<int>(bbox_orgin, bbox);

    M = mxGetM(prhs[1]);
    N = mxGetN(prhs[1]);
    cv::Mat edge_geo(N, M, CV_64F);
    fillmat<double>(edge_geo_orgin, edge_geo);

    int H = 1080;
    int W = 1920;

    cv::Mat dist_map, dist_y_map, Y_map, angle_map, err_map, bw_map;
    dist_map    = get_map(edge_geo, 6, H, W);
    dist_y_map  = get_map(edge_geo, 5, H, W);
    Y_map       = get_map(edge_geo, 1, H, W);
    angle_map   = get_map(edge_geo, 7, H, W);
    err_map     = get_map(edge_geo, 8, H, W);
    bw_map      = bwlabel(dist_map);

    cv::Mat dist_map_inte = cv::Mat::zeros(H + 1, W + 1, CV_64F);
    cv::Mat dist_y_map_inte = cv::Mat::zeros(H + 1, W + 1, CV_64F);
    cv::Mat Y_map_inte = cv::Mat::zeros(H + 1, W + 1, CV_64F);
    cv::Mat angle_map_inte = cv::Mat::zeros(H + 1, W + 1, CV_64F);
    cv::Mat err_map_inte = cv::Mat::zeros(H + 1, W + 1, CV_64F);
    cv::Mat bw_map_inte = cv::Mat::zeros(H + 1, W + 1, CV_64F);
    cv::Mat sqsum = cv::Mat::zeros(H + 1, W + 1, CV_64F);

    integral(dist_map, dist_map_inte, sqsum, CV_64F, CV_64F);
    integral(dist_y_map, dist_y_map_inte, sqsum, CV_64F, CV_64F);
    integral(Y_map, Y_map_inte, sqsum, CV_64F, CV_64F);
    integral(angle_map, angle_map_inte, sqsum, CV_64F, CV_64F);
    integral(err_map, err_map_inte, sqsum, CV_64F, CV_64F);
    integral(bw_map, bw_map_inte, sqsum, CV_64F, CV_64F);

    cv::Mat geo_feat = cv::Mat::zeros(bbox.rows, 5, CV_64F);

    int i, minY, minX, maxX, maxY;
    double dist, dist_y, p_num, Y, angle, err;
    for (i = 0; i < bbox.rows; i++)
    {
        minX = bbox.at<int>(i, 0)-1;
        minY = bbox.at<int>(i, 1)-1;
        maxX = bbox.at<int>(i, 2);
        maxY = bbox.at<int>(i, 3);

        // mexPrintf("recurrent %d << \n", i);

        dist    = (dist_map_inte.at<double>(maxY, maxX) + 
                    dist_map_inte.at<double>(minY, minX) - 
                    dist_map_inte.at<double>(minY, maxX) - 
                    dist_map_inte.at<double>(maxY, minX));
        dist_y  = (dist_y_map_inte.at<double>(maxY, maxX) + 
                    dist_y_map_inte.at<double>(minY, minX) - 
                    dist_y_map_inte.at<double>(minY, maxX) - 
                    dist_y_map_inte.at<double>(maxY, minX));
        p_num   = (bw_map_inte.at<double>(maxY, maxX) + 
                    bw_map_inte.at<double>(minY, minX) - 
                    bw_map_inte.at<double>(minY, maxX) - 
                    bw_map_inte.at<double>(maxY, minX));
        Y       = (Y_map_inte.at<double>(maxY, maxX) + 
                    Y_map_inte.at<double>(minY, minX) - 
                    Y_map_inte.at<double>(minY, maxX) -
                    Y_map_inte.at<double>(maxY, minX));
        angle   = (angle_map_inte.at<double>(maxY, maxX) + 
                    angle_map_inte.at<double>(minY, minX) - 
                    angle_map_inte.at<double>(minY, maxX) - 
                    angle_map_inte.at<double>(maxY, minX));
        err     = (err_map_inte.at<double>(maxY, maxX) + 
                    err_map_inte.at<double>(minY, minX) - 
                    err_map_inte.at<double>(minY, maxX) - 
                    err_map_inte.at<double>(maxY, minX));

        geo_feat.at<double>(i, 0) = (forward * Y / p_num / H * 10 / 140) - dist / p_num;
        geo_feat.at<double>(i, 1) = dist / p_num;
        geo_feat.at<double>(i, 2) = angle / p_num;
        geo_feat.at<double>(i, 3) = dist_y / p_num;
        geo_feat.at<double>(i, 4) = 1 / sqrt(err / p_num);
    }

    plhs[0] = mxCreateDoubleMatrix(geo_feat.rows, geo_feat.cols, mxREAL);

    geo_feat = geo_feat.t();
    double *out = (double *)mxGetPr(plhs[0]);
    memcpy(out, geo_feat.ptr<double>(0), sizeof(double) * geo_feat.rows * geo_feat.cols);
}
