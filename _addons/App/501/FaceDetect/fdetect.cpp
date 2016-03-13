#include <opencv/cv.h>
#include <opencv/highgui.h>
#include <stdio.h>

#define SCALE_FACTOR 1.1

const char* cascade_name = "cascade.xml";

int main( int argc, char** argv )
{
	IplImage *img = cvLoadImage(argv[1]);
	if (!img) {
		fprintf( stderr, "ERROR: Could not load image\n" );
		return -1;
	}

	static CvMemStorage* storage = 0;
	static CvHaarClassifierCascade* cascade = 0;
	int scale = 1;

	CvPoint pt1, pt2;

	cascade = (CvHaarClassifierCascade*)cvLoad( cascade_name, 0, 0, 0 ); 
	if( !cascade ) {
		fprintf( stderr, "ERROR: Could not load classifier cascade\n" );
		return -2;
	}

 	storage = cvCreateMemStorage(0);
	cvClearMemStorage( storage );

	CvSeq* faces = cvHaarDetectObjects( img, cascade, storage,
		                            SCALE_FACTOR, 2, CV_HAAR_DO_CANNY_PRUNING,
		                            cvSize(40, 40) );

	for(int i = 0; i < (faces ? faces->total : 0); i++ ) {
		CvRect* r = (CvRect*)cvGetSeqElem( faces, i );
		pt1.x = r->x*scale;
		pt2.x = (r->x+r->width)*scale;
		pt1.y = r->y*scale;
		pt2.y = (r->y+r->height)*scale;
		printf("%d:%d,%d-%d,%d\n",i+1,pt1.x,pt1.y,pt2.x,pt2.y);
	}
	cvReleaseImage(&img);
	return 0;
}

