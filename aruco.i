/************************************

Swig Module for ArUco Python wrapper

************************************/

// module name
%module(directors="1") aruco

// needed
%include <std_string.i>
%include "pyabc.i"
%include "std_vector.i"

%{
	#define SWIG_FILE_WITH_INIT
%}

// NumPy <--> OpenCV typemaps
%include "okapi-typemaps.i"

/************************************

ArUco stuff

************************************/


%{
	#define SWIG_FILE_WITH_INIT
	#include "aruco/exports.h"
	#include "aruco/cameraparameters.h"
	#include "aruco/marker.h"
	#include "aruco/board.h"
	#include "aruco/cvdrawingutils.h"
%}

%include "aruco/exports.h"
%include "aruco/cameraparameters.h"
// Marker is std::vector< cv::Point2f >, template definition 
// needed for std::vector -> Python List conversion
%template(Point2fVec) std::vector< cv::Point2f >;
%include "aruco/marker.h"

/***
 Workaround:
 std::vector<Point2f>.at() --> Point2f conversion doesn't work
 so I just implemented the Python __getitem__() method for aruco::Marker
 to get corner points of the Marker object and added VectorIterator to
 support for-loops
***/
%pythoncode %{
class VectorIterator(object):

    def __init__(self, pointerToVector):
        self.pointerToVector = pointerToVector
        self.index = -1

    def next(self):
        self.index += 1
        if self.index < len(self.pointerToVector):
            return self.pointerToVector[self.index]
        else:
            raise StopIteration
%}

%extend aruco::Marker {
	public:
        cv::Point2f __getitem__(int i) {
            return $self->at(i);
        }
}

%extend aruco::Marker {
%pythoncode {
    def iterator(self):
        return VectorIterator(self)
   }
}

// Board is std::vector< aruco::Marker >, template definition 
// needed for std::vector -> Python List conversion
%template(MarkerVec) std::vector< aruco::Marker >;
%include "aruco/board.h"
%include "aruco/cvdrawingutils.h"


// rename detect function because of polymorphism problems
%rename("detect_mat") aruco::BoardDetector::detect(const cv::Mat&);

// some stuff to support nested class MarkerCandidate in boarddetector.h

// Suppress SWIG warning
#pragma SWIG nowarn=SWIGWARN_PARSE_NESTED_CLASS
// nested class in markerdetector

class MarkerCandidate : public aruco::Marker {
      public:
        MarkerCandidate() {}
        MarkerCandidate(const aruco::Marker &M) : Maruco::arker(M) {}
        MarkerCandidate(const MarkerCandidate &M) : aruco::Marker(M) {
            contour = M.contour;
            idx = M.idx;
        }
        MarkerCandidate &operator=(const MarkerCandidate &M) {
            (*(aruco::Marker *)this) = (*(aruco::Marker *)&M);
            contour = M.contour;
            idx = M.idx;
            return *this;
        }

        vector< cv::Point > contour; // all the points of its contour
        int idx; // index position in the global contour list
};

%{
	#include "aruco/markerdetector.h"
%}

%include "aruco/markerdetector.h"
// add detect function that returns the detected markers
%extend aruco::MarkerDetector {

	public:
		std::vector< aruco::Marker > detect(const cv::Mat &input,
										aruco::CameraParameters camParams,
										float markerSizeMeters = -1,
										bool setYPerperdicular = false) throw(cv::Exception)
		{
			std::vector< aruco::Marker > markers;
			$self->detect(input, markers, camParams, markerSizeMeters, setYPerperdicular);
	        return markers;
		};
}



%{
	// SWIG thinks that Inner is a global class, so we need to trick the C++
	// compiler into understanding this so called global type.
	typedef aruco::MarkerDetector::MarkerCandidate MarkerCandidate;
%}

%{
	#include "aruco/boarddetector.h"
%}

%include "aruco/boarddetector.h"
