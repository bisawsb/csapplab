#ifndef LAB4_NEW_RGB888_H
#define LAB4_NEW_RGB888_H

#include "ExecutePolicy.h"
#include "utils.h"
#include <cstdlib>

class Yuv420pFrame;

class Rgb888 {
	size_t width_;
	size_t height_;
	size_t gbufferOffset_;
	size_t bbufferOffset_;
	size_t bufferSize_;
	unsigned char *buffer_;
	Rgb888(int width, int height);

public:
	int width() const { return width_; }
	int height() const { return height_; }
	const unsigned char *rbuffer() const { return buffer_; }
	const unsigned char *bbuffer() const { return buffer_ + bbufferOffset_; }
	const unsigned char *gbuffer() const { return buffer_ + gbufferOffset_; }
	unsigned char *rbuffer() { return buffer_; }
	unsigned char *bbuffer() { return buffer_ + bbufferOffset_; }
	unsigned char *gbuffer() { return buffer_ + gbufferOffset_; }
	Rgb888(const Rgb888 &other);
	Rgb888 &operator=(const Rgb888 &other);
	Rgb888(Rgb888 &&other) noexcept;
	Rgb888 &operator=(Rgb888 &&other) noexcept;
	~Rgb888();

public:
	template<ExecutePolicy policy>
	static Rgb888 fromYuv420(const Yuv420pFrame &input);
};

#include "Yuv420pFrame.h"

template<ExecutePolicy policy>
Rgb888 Rgb888::fromYuv420(const Yuv420pFrame &input) {
	Rgb888 ret(input.width(), input.height());
	for (size_t h = 0; h < ret.height_; ++h) {
		for (size_t w = 0; w < ret.width_; ++w) {
			size_t pos = h * ret.width_ + w;
			size_t halfpos = h / 2 * ret.width_ / 2 + w / 2;
			int y = input.ybuffer()[pos];
			int u = input.ubuffer()[halfpos];
			int v = input.vbuffer()[halfpos];

			int r = static_cast<int>(1.164383 * (y - 16) + 1.596027 * (v - 128) + 0.5);
			int g = static_cast<int>(1.164383 * (y - 16) - 0.391762 * (u - 128) - 0.812968 * (v - 128) + 0.5);
			int b = static_cast<int>(1.164383 * (y - 16) + 2.017232 * (u - 128) + 0.5);
			ret.rbuffer()[pos] = roundInt(r);
			ret.gbuffer()[pos] = roundInt(g);
			ret.bbuffer()[pos] = roundInt(b);
		}
	}
	return ret;
}

#endif//LAB4_NEW_RGB888_H
