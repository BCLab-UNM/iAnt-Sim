/*M///////////////////////////////////////////////////////////////////////////////////////
//
//  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
//
//  By downloading, copying, installing or using the software you agree to this license.
//  If you do not agree to this license, do not download, install,
//  copy or use the software.
//
//
//                           License Agreement
//                For Open Source Computer Vision Library
//
// Copyright (C) 2000-2008, Intel Corporation, all rights reserved.
// Copyright (C) 2009, Willow Garage Inc., all rights reserved.
// Third party copyrights are property of their respective owners.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
//   * Redistribution's of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//   * Redistribution's in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//
//   * The name of the copyright holders may not be used to endorse or promote products
//     derived from this software without specific prior written permission.
//
// This software is provided by the copyright holders and contributors "as is" and
// any express or implied warranties, including, but not limited to, the implied
// warranties of merchantability and fitness for a particular purpose are disclaimed.
// In no event shall the Intel Corporation or contributors be liable for any direct,
// indirect, incidental, special, exemplary, or consequential damages
// (including, but not limited to, procurement of substitute goods or services;
// loss of use, data, or profits; or business interruption) however caused
// and on any theory of liability, whether in contract, strict liability,
// or tort (including negligence or otherwise) arising in any way out of
// the use of this software, even if advised of the possibility of such damage.
//
//M*/

#ifndef __OPENCV_GPUARITHM_HPP__
#define __OPENCV_GPUARITHM_HPP__

#ifndef __cplusplus
#  error gpuarithm.hpp header must be compiled as C++
#endif

#include "opencv2/core/gpumat.hpp"

namespace cv { namespace gpu {

//! adds one matrix to another (c = a + b)
CV_EXPORTS void add(const GpuMat& a, const GpuMat& b, GpuMat& c, const GpuMat& mask = GpuMat(), int dtype = -1, Stream& stream = Stream::Null());
//! adds scalar to a matrix (c = a + s)
CV_EXPORTS void add(const GpuMat& a, const Scalar& sc, GpuMat& c, const GpuMat& mask = GpuMat(), int dtype = -1, Stream& stream = Stream::Null());

//! subtracts one matrix from another (c = a - b)
CV_EXPORTS void subtract(const GpuMat& a, const GpuMat& b, GpuMat& c, const GpuMat& mask = GpuMat(), int dtype = -1, Stream& stream = Stream::Null());
//! subtracts scalar from a matrix (c = a - s)
CV_EXPORTS void subtract(const GpuMat& a, const Scalar& sc, GpuMat& c, const GpuMat& mask = GpuMat(), int dtype = -1, Stream& stream = Stream::Null());

//! computes element-wise weighted product of the two arrays (c = scale * a * b)
CV_EXPORTS void multiply(const GpuMat& a, const GpuMat& b, GpuMat& c, double scale = 1, int dtype = -1, Stream& stream = Stream::Null());
//! weighted multiplies matrix to a scalar (c = scale * a * s)
CV_EXPORTS void multiply(const GpuMat& a, const Scalar& sc, GpuMat& c, double scale = 1, int dtype = -1, Stream& stream = Stream::Null());

//! computes element-wise weighted quotient of the two arrays (c = a / b)
CV_EXPORTS void divide(const GpuMat& a, const GpuMat& b, GpuMat& c, double scale = 1, int dtype = -1, Stream& stream = Stream::Null());
//! computes element-wise weighted quotient of matrix and scalar (c = a / s)
CV_EXPORTS void divide(const GpuMat& a, const Scalar& sc, GpuMat& c, double scale = 1, int dtype = -1, Stream& stream = Stream::Null());
//! computes element-wise weighted reciprocal of an array (dst = scale/src2)
CV_EXPORTS void divide(double scale, const GpuMat& b, GpuMat& c, int dtype = -1, Stream& stream = Stream::Null());

//! computes the weighted sum of two arrays (dst = alpha*src1 + beta*src2 + gamma)
CV_EXPORTS void addWeighted(const GpuMat& src1, double alpha, const GpuMat& src2, double beta, double gamma, GpuMat& dst,
                            int dtype = -1, Stream& stream = Stream::Null());

//! adds scaled array to another one (dst = alpha*src1 + src2)
static inline void scaleAdd(const GpuMat& src1, double alpha, const GpuMat& src2, GpuMat& dst, Stream& stream = Stream::Null())
{
    addWeighted(src1, alpha, src2, 1.0, 0.0, dst, -1, stream);
}

//! computes element-wise absolute difference of two arrays (c = abs(a - b))
CV_EXPORTS void absdiff(const GpuMat& a, const GpuMat& b, GpuMat& c, Stream& stream = Stream::Null());
//! computes element-wise absolute difference of array and scalar (c = abs(a - s))
CV_EXPORTS void absdiff(const GpuMat& a, const Scalar& s, GpuMat& c, Stream& stream = Stream::Null());

//! computes absolute value of each matrix element
//! supports CV_16S and CV_32F depth
CV_EXPORTS void abs(const GpuMat& src, GpuMat& dst, Stream& stream = Stream::Null());

//! computes square of each pixel in an image
//! supports CV_8U, CV_16U, CV_16S and CV_32F depth
CV_EXPORTS void sqr(const GpuMat& src, GpuMat& dst, Stream& stream = Stream::Null());

//! computes square root of each pixel in an image
//! supports CV_8U, CV_16U, CV_16S and CV_32F depth
CV_EXPORTS void sqrt(const GpuMat& src, GpuMat& dst, Stream& stream = Stream::Null());

//! computes exponent of each matrix element (b = e**a)
//! supports CV_8U, CV_16U, CV_16S and CV_32F depth
CV_EXPORTS void exp(const GpuMat& a, GpuMat& b, Stream& stream = Stream::Null());

//! computes natural logarithm of absolute value of each matrix element: b = log(abs(a))
//! supports CV_8U, CV_16U, CV_16S and CV_32F depth
CV_EXPORTS void log(const GpuMat& a, GpuMat& b, Stream& stream = Stream::Null());

//! computes power of each matrix element:
//    (dst(i,j) = pow(     src(i,j) , power), if src.type() is integer
//    (dst(i,j) = pow(fabs(src(i,j)), power), otherwise
//! supports all, except depth == CV_64F
CV_EXPORTS void pow(const GpuMat& src, double power, GpuMat& dst, Stream& stream = Stream::Null());

//! compares elements of two arrays (c = a <cmpop> b)
CV_EXPORTS void compare(const GpuMat& a, const GpuMat& b, GpuMat& c, int cmpop, Stream& stream = Stream::Null());
CV_EXPORTS void compare(const GpuMat& a, Scalar sc, GpuMat& c, int cmpop, Stream& stream = Stream::Null());

//! performs per-elements bit-wise inversion
CV_EXPORTS void bitwise_not(const GpuMat& src, GpuMat& dst, const GpuMat& mask=GpuMat(), Stream& stream = Stream::Null());

//! calculates per-element bit-wise disjunction of two arrays
CV_EXPORTS void bitwise_or(const GpuMat& src1, const GpuMat& src2, GpuMat& dst, const GpuMat& mask=GpuMat(), Stream& stream = Stream::Null());
//! calculates per-element bit-wise disjunction of array and scalar
//! supports 1, 3 and 4 channels images with CV_8U, CV_16U or CV_32S depth
CV_EXPORTS void bitwise_or(const GpuMat& src1, const Scalar& sc, GpuMat& dst, Stream& stream = Stream::Null());

//! calculates per-element bit-wise conjunction of two arrays
CV_EXPORTS void bitwise_and(const GpuMat& src1, const GpuMat& src2, GpuMat& dst, const GpuMat& mask=GpuMat(), Stream& stream = Stream::Null());
//! calculates per-element bit-wise conjunction of array and scalar
//! supports 1, 3 and 4 channels images with CV_8U, CV_16U or CV_32S depth
CV_EXPORTS void bitwise_and(const GpuMat& src1, const Scalar& sc, GpuMat& dst, Stream& stream = Stream::Null());

//! calculates per-element bit-wise "exclusive or" operation
CV_EXPORTS void bitwise_xor(const GpuMat& src1, const GpuMat& src2, GpuMat& dst, const GpuMat& mask=GpuMat(), Stream& stream = Stream::Null());
//! calculates per-element bit-wise "exclusive or" of array and scalar
//! supports 1, 3 and 4 channels images with CV_8U, CV_16U or CV_32S depth
CV_EXPORTS void bitwise_xor(const GpuMat& src1, const Scalar& sc, GpuMat& dst, Stream& stream = Stream::Null());

//! pixel by pixel right shift of an image by a constant value
//! supports 1, 3 and 4 channels images with integers elements
CV_EXPORTS void rshift(const GpuMat& src, Scalar_<int> sc, GpuMat& dst, Stream& stream = Stream::Null());

//! pixel by pixel left shift of an image by a constant value
//! supports 1, 3 and 4 channels images with CV_8U, CV_16U or CV_32S depth
CV_EXPORTS void lshift(const GpuMat& src, Scalar_<int> sc, GpuMat& dst, Stream& stream = Stream::Null());

//! computes per-element minimum of two arrays (dst = min(src1, src2))
CV_EXPORTS void min(const GpuMat& src1, const GpuMat& src2, GpuMat& dst, Stream& stream = Stream::Null());

//! computes per-element minimum of array and scalar (dst = min(src1, src2))
CV_EXPORTS void min(const GpuMat& src1, double src2, GpuMat& dst, Stream& stream = Stream::Null());

//! computes per-element maximum of two arrays (dst = max(src1, src2))
CV_EXPORTS void max(const GpuMat& src1, const GpuMat& src2, GpuMat& dst, Stream& stream = Stream::Null());

//! computes per-element maximum of array and scalar (dst = max(src1, src2))
CV_EXPORTS void max(const GpuMat& src1, double src2, GpuMat& dst, Stream& stream = Stream::Null());

//! implements generalized matrix product algorithm GEMM from BLAS
CV_EXPORTS void gemm(const GpuMat& src1, const GpuMat& src2, double alpha,
    const GpuMat& src3, double beta, GpuMat& dst, int flags = 0, Stream& stream = Stream::Null());

//! transposes the matrix
//! supports matrix with element size = 1, 4 and 8 bytes (CV_8UC1, CV_8UC4, CV_16UC2, CV_32FC1, etc)
CV_EXPORTS void transpose(const GpuMat& src1, GpuMat& dst, Stream& stream = Stream::Null());

//! reverses the order of the rows, columns or both in a matrix
//! supports 1, 3 and 4 channels images with CV_8U, CV_16U, CV_32S or CV_32F depth
CV_EXPORTS void flip(const GpuMat& a, GpuMat& b, int flipCode, Stream& stream = Stream::Null());

//! transforms 8-bit unsigned integers using lookup table: dst(i)=lut(src(i))
//! destination array will have the depth type as lut and the same channels number as source
//! supports CV_8UC1, CV_8UC3 types
CV_EXPORTS void LUT(const GpuMat& src, const Mat& lut, GpuMat& dst, Stream& stream = Stream::Null());

//! makes multi-channel array out of several single-channel arrays
CV_EXPORTS void merge(const GpuMat* src, size_t n, GpuMat& dst, Stream& stream = Stream::Null());

//! makes multi-channel array out of several single-channel arrays
CV_EXPORTS void merge(const std::vector<GpuMat>& src, GpuMat& dst, Stream& stream = Stream::Null());

//! copies each plane of a multi-channel array to a dedicated array
CV_EXPORTS void split(const GpuMat& src, GpuMat* dst, Stream& stream = Stream::Null());

//! copies each plane of a multi-channel array to a dedicated array
CV_EXPORTS void split(const GpuMat& src, std::vector<GpuMat>& dst, Stream& stream = Stream::Null());

//! computes magnitude of complex (x(i).re, x(i).im) vector
//! supports only CV_32FC2 type
CV_EXPORTS void magnitude(const GpuMat& xy, GpuMat& magnitude, Stream& stream = Stream::Null());

//! computes squared magnitude of complex (x(i).re, x(i).im) vector
//! supports only CV_32FC2 type
CV_EXPORTS void magnitudeSqr(const GpuMat& xy, GpuMat& magnitude, Stream& stream = Stream::Null());

//! computes magnitude of each (x(i), y(i)) vector
//! supports only floating-point source
CV_EXPORTS void magnitude(const GpuMat& x, const GpuMat& y, GpuMat& magnitude, Stream& stream = Stream::Null());

//! computes squared magnitude of each (x(i), y(i)) vector
//! supports only floating-point source
CV_EXPORTS void magnitudeSqr(const GpuMat& x, const GpuMat& y, GpuMat& magnitude, Stream& stream = Stream::Null());

//! computes angle (angle(i)) of each (x(i), y(i)) vector
//! supports only floating-point source
CV_EXPORTS void phase(const GpuMat& x, const GpuMat& y, GpuMat& angle, bool angleInDegrees = false, Stream& stream = Stream::Null());

//! converts Cartesian coordinates to polar
//! supports only floating-point source
CV_EXPORTS void cartToPolar(const GpuMat& x, const GpuMat& y, GpuMat& magnitude, GpuMat& angle, bool angleInDegrees = false, Stream& stream = Stream::Null());

//! converts polar coordinates to Cartesian
//! supports only floating-point source
CV_EXPORTS void polarToCart(const GpuMat& magnitude, const GpuMat& angle, GpuMat& x, GpuMat& y, bool angleInDegrees = false, Stream& stream = Stream::Null());

//! scales and shifts array elements so that either the specified norm (alpha) or the minimum (alpha) and maximum (beta) array values get the specified values
CV_EXPORTS void normalize(const GpuMat& src, GpuMat& dst, double alpha = 1, double beta = 0,
                          int norm_type = NORM_L2, int dtype = -1, const GpuMat& mask = GpuMat());
CV_EXPORTS void normalize(const GpuMat& src, GpuMat& dst, double a, double b,
                          int norm_type, int dtype, const GpuMat& mask, GpuMat& norm_buf, GpuMat& cvt_buf);

//! computes norm of array
//! supports NORM_INF, NORM_L1, NORM_L2
//! supports all matrices except 64F
CV_EXPORTS double norm(const GpuMat& src1, int normType=NORM_L2);
CV_EXPORTS double norm(const GpuMat& src1, int normType, GpuMat& buf);
CV_EXPORTS double norm(const GpuMat& src1, int normType, const GpuMat& mask, GpuMat& buf);

//! computes norm of the difference between two arrays
//! supports NORM_INF, NORM_L1, NORM_L2
//! supports only CV_8UC1 type
CV_EXPORTS double norm(const GpuMat& src1, const GpuMat& src2, int normType=NORM_L2);

//! computes sum of array elements
//! supports only single channel images
CV_EXPORTS Scalar sum(const GpuMat& src);
CV_EXPORTS Scalar sum(const GpuMat& src, GpuMat& buf);
CV_EXPORTS Scalar sum(const GpuMat& src, const GpuMat& mask, GpuMat& buf);

//! computes sum of array elements absolute values
//! supports only single channel images
CV_EXPORTS Scalar absSum(const GpuMat& src);
CV_EXPORTS Scalar absSum(const GpuMat& src, GpuMat& buf);
CV_EXPORTS Scalar absSum(const GpuMat& src, const GpuMat& mask, GpuMat& buf);

//! computes squared sum of array elements
//! supports only single channel images
CV_EXPORTS Scalar sqrSum(const GpuMat& src);
CV_EXPORTS Scalar sqrSum(const GpuMat& src, GpuMat& buf);
CV_EXPORTS Scalar sqrSum(const GpuMat& src, const GpuMat& mask, GpuMat& buf);

//! finds global minimum and maximum array elements and returns their values
CV_EXPORTS void minMax(const GpuMat& src, double* minVal, double* maxVal=0, const GpuMat& mask=GpuMat());
CV_EXPORTS void minMax(const GpuMat& src, double* minVal, double* maxVal, const GpuMat& mask, GpuMat& buf);

//! finds global minimum and maximum array elements and returns their values with locations
CV_EXPORTS void minMaxLoc(const GpuMat& src, double* minVal, double* maxVal=0, Point* minLoc=0, Point* maxLoc=0,
                          const GpuMat& mask=GpuMat());
CV_EXPORTS void minMaxLoc(const GpuMat& src, double* minVal, double* maxVal, Point* minLoc, Point* maxLoc,
                          const GpuMat& mask, GpuMat& valbuf, GpuMat& locbuf);

//! counts non-zero array elements
CV_EXPORTS int countNonZero(const GpuMat& src);
CV_EXPORTS int countNonZero(const GpuMat& src, GpuMat& buf);

//! reduces a matrix to a vector
CV_EXPORTS void reduce(const GpuMat& mtx, GpuMat& vec, int dim, int reduceOp, int dtype = -1, Stream& stream = Stream::Null());

//! computes mean value and standard deviation of all or selected array elements
//! supports only CV_8UC1 type
CV_EXPORTS void meanStdDev(const GpuMat& mtx, Scalar& mean, Scalar& stddev);
//! buffered version
CV_EXPORTS void meanStdDev(const GpuMat& mtx, Scalar& mean, Scalar& stddev, GpuMat& buf);

//! computes the standard deviation of integral images
//! supports only CV_32SC1 source type and CV_32FC1 sqr type
//! output will have CV_32FC1 type
CV_EXPORTS void rectStdDev(const GpuMat& src, const GpuMat& sqr, GpuMat& dst, const Rect& rect, Stream& stream = Stream::Null());

//! copies 2D array to a larger destination array and pads borders with user-specifiable constant
CV_EXPORTS void copyMakeBorder(const GpuMat& src, GpuMat& dst, int top, int bottom, int left, int right, int borderType,
                               const Scalar& value = Scalar(), Stream& stream = Stream::Null());

//! applies fixed threshold to the image
CV_EXPORTS double threshold(const GpuMat& src, GpuMat& dst, double thresh, double maxval, int type, Stream& stream = Stream::Null());

//! computes the integral image
//! sum will have CV_32S type, but will contain unsigned int values
//! supports only CV_8UC1 source type
CV_EXPORTS void integral(const GpuMat& src, GpuMat& sum, Stream& stream = Stream::Null());
//! buffered version
CV_EXPORTS void integralBuffered(const GpuMat& src, GpuMat& sum, GpuMat& buffer, Stream& stream = Stream::Null());

//! computes squared integral image
//! result matrix will have 64F type, but will contain 64U values
//! supports source images of 8UC1 type only
CV_EXPORTS void sqrIntegral(const GpuMat& src, GpuMat& sqsum, Stream& stream = Stream::Null());

//! performs per-element multiplication of two full (not packed) Fourier spectrums
//! supports 32FC2 matrixes only (interleaved format)
CV_EXPORTS void mulSpectrums(const GpuMat& a, const GpuMat& b, GpuMat& c, int flags, bool conjB=false, Stream& stream = Stream::Null());

//! performs per-element multiplication of two full (not packed) Fourier spectrums
//! supports 32FC2 matrixes only (interleaved format)
CV_EXPORTS void mulAndScaleSpectrums(const GpuMat& a, const GpuMat& b, GpuMat& c, int flags, float scale, bool conjB=false, Stream& stream = Stream::Null());

//! Performs a forward or inverse discrete Fourier transform (1D or 2D) of floating point matrix.
//! Param dft_size is the size of DFT transform.
//!
//! If the source matrix is not continous, then additional copy will be done,
//! so to avoid copying ensure the source matrix is continous one. If you want to use
//! preallocated output ensure it is continuous too, otherwise it will be reallocated.
//!
//! Being implemented via CUFFT real-to-complex transform result contains only non-redundant values
//! in CUFFT's format. Result as full complex matrix for such kind of transform cannot be retrieved.
//!
//! For complex-to-real transform it is assumed that the source matrix is packed in CUFFT's format.
CV_EXPORTS void dft(const GpuMat& src, GpuMat& dst, Size dft_size, int flags=0, Stream& stream = Stream::Null());

struct CV_EXPORTS ConvolveBuf
{
    Size result_size;
    Size block_size;
    Size user_block_size;
    Size dft_size;
    int spect_len;

    GpuMat image_spect, templ_spect, result_spect;
    GpuMat image_block, templ_block, result_data;

    void create(Size image_size, Size templ_size);
    static Size estimateBlockSize(Size result_size, Size templ_size);
};

//! computes convolution (or cross-correlation) of two images using discrete Fourier transform
//! supports source images of 32FC1 type only
//! result matrix will have 32FC1 type
CV_EXPORTS void convolve(const GpuMat& image, const GpuMat& templ, GpuMat& result, bool ccorr = false);
CV_EXPORTS void convolve(const GpuMat& image, const GpuMat& templ, GpuMat& result, bool ccorr, ConvolveBuf& buf, Stream& stream = Stream::Null());

}} // namespace cv { namespace gpu {

#endif /* __OPENCV_GPUARITHM_HPP__ */
