#ifndef LAB4_NEW_YUV420PVIDEO_H
#define LAB4_NEW_YUV420PVIDEO_H

#include <vector>
#include "Yuv420pFrame.h"
#include "Rgb888.h"

class Yuv420pVideo {
	std::vector<Yuv420pFrame> frames_;
public:
	void pushFrame(Yuv420pFrame frame);
	int writeToFile(const char *filename);
	template<ExecutePolicy policy>
	static Yuv420pVideo yuv420pFadeIn(const Yuv420pFrame &frame);
	bool operator==(const Yuv420pVideo &rhs) const;
	bool operator!=(const Yuv420pVideo &rhs) const;
};

template<ExecutePolicy policy>
Yuv420pVideo Yuv420pVideo::yuv420pFadeIn(const Yuv420pFrame &frame) {
	Yuv420pVideo ret;
	Rgb888 rgb888 = Rgb888::fromYuv420<policy>(frame);
	for (int A = 1; A < 255; A = A + 3) {
		ret.pushFrame(Yuv420pFrame::fromAlphaMixingRgb888<policy>(rgb888, A));
	}
	return ret;
}

#endif//LAB4_NEW_YUV420PVIDEO_H
