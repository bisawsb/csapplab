#include "Yuv420pVideo.h"

void Yuv420pVideo::pushFrame(Yuv420pFrame frame) {
	frames_.push_back(std::move(frame));
}
int Yuv420pVideo::writeToFile(const char *filename) {
	FILE *fp = fopen(filename, "w");
	int totSize = 0;
	for (const auto &frame : frames_) {
		auto size = frame.appendToFile(fp);
		if (size == -1) { fclose(fp); return -1; }
		totSize += size;
	}
	fclose(fp);
	return totSize;
}
bool Yuv420pVideo::operator==(const Yuv420pVideo &rhs) const { return frames_ == rhs.frames_; }
bool Yuv420pVideo::operator!=(const Yuv420pVideo &rhs) const { return !(rhs == *this); }
