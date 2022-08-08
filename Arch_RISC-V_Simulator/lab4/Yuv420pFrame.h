#ifndef LAB4_NEW_YUV420PFRAME_H
#define LAB4_NEW_YUV420PFRAME_H

#include "ExecutePolicy.h"
#include <cstdio>
#include <immintrin.h>
#include <system_error>

class Rgb888;

class Yuv420pFrame {
	size_t width_;
	size_t height_;
	size_t ubufferOffset_;
	size_t vbufferOffset_;
	size_t bufferSize_;
	unsigned char *buffer_;
	Yuv420pFrame(size_t width, size_t height);

public:
	size_t width() const { return width_; }
	size_t height() const { return height_; }
	const unsigned char *ybuffer() const { return buffer_; }
	const unsigned char *ubuffer() const { return buffer_ + ubufferOffset_; }
	const unsigned char *vbuffer() const { return buffer_ + vbufferOffset_; }
	unsigned char *ybuffer() { return buffer_; }
	unsigned char *ubuffer() { return buffer_ + ubufferOffset_; }
	unsigned char *vbuffer() { return buffer_ + vbufferOffset_; }

	Yuv420pFrame(const Yuv420pFrame &other);
	Yuv420pFrame(Yuv420pFrame &&other) noexcept;
	Yuv420pFrame &operator=(const Yuv420pFrame &other);
	Yuv420pFrame &operator=(Yuv420pFrame &&other) noexcept;
	~Yuv420pFrame();

public:
	template<ExecutePolicy policy>
	static Yuv420pFrame fromAlphaMixingRgb888(const Rgb888 &input, int alpha);
	static Yuv420pFrame fromFile(const std::string &filename, size_t width, size_t height, std::error_code &errc);
	int appendToFile(FILE *fp) const;
	bool operator==(const Yuv420pFrame &rhs) const;
	bool operator!=(const Yuv420pFrame &rhs) const;
};

#include "Rgb888.h"

template<ExecutePolicy policy>
Yuv420pFrame Yuv420pFrame::fromAlphaMixingRgb888(const Rgb888 &input, int alpha) {
	printf("Unrecognized execute policy\n");
	exit(-1);
}

template<>
Yuv420pFrame Yuv420pFrame::fromAlphaMixingRgb888<BASIC>(const Rgb888 &input, int alpha);
template<>
Yuv420pFrame Yuv420pFrame::fromAlphaMixingRgb888<MMX>(const Rgb888 &input, int alpha);
template<>
Yuv420pFrame Yuv420pFrame::fromAlphaMixingRgb888<SSE>(const Rgb888 &input, int alpha);
template<>
Yuv420pFrame Yuv420pFrame::fromAlphaMixingRgb888<AVX>(const Rgb888 &input, int alpha);

#endif//LAB4_NEW_YUV420PFRAME_H
