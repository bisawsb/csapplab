#include "Rgb888.h"
#include "MapMacro.h"
#include "Yuv420pFrame.h"
#include "debug.h"
#include <cstring>
#include <signal.h>

Rgb888::Rgb888(int width, int height)
	: width_(width), height_(height), gbufferOffset_(width * height), bbufferOffset_(width * height * 2),
	  bufferSize_(width * height * 3), buffer_(new(std::align_val_t(64)) unsigned char[bufferSize_]) {}
Rgb888::Rgb888(const Rgb888 &other) : Rgb888(other.width_, other.height_) {
	memcpy(buffer_, other.buffer_, bufferSize_);
}
Rgb888 &Rgb888::operator=(const Rgb888 &other) {
	if (this == &other) return *this;
	if (width_ != other.width_ || height_ != other.height_) {
		width_ = other.width_;
		height_ = other.height_;
		gbufferOffset_ = other.gbufferOffset_;
		bbufferOffset_ = other.bbufferOffset_;
		bufferSize_ = other.bufferSize_;
		delete[] buffer_;
		buffer_ = new(std::align_val_t(64)) unsigned char[bufferSize_];
	}
	memcpy(buffer_, other.buffer_, bufferSize_);
	return *this;
}
Rgb888::Rgb888(Rgb888 &&other) noexcept
	: width_(other.width_), height_(other.height_), gbufferOffset_(other.gbufferOffset_),
	  bbufferOffset_(other.bbufferOffset_), bufferSize_(other.bufferSize_), buffer_(other.buffer_) {
	other.buffer_ = nullptr;
}

Rgb888 &Rgb888::operator=(Rgb888 &&other) noexcept {
	if (this == &other) return *this;
	delete[] buffer_;
	width_ = other.width_;
	height_ = other.height_;
	gbufferOffset_ = other.gbufferOffset_;
	bbufferOffset_ = other.bbufferOffset_;
	bufferSize_ = other.bufferSize_;
	buffer_ = other.buffer_;
	other.buffer_ = nullptr;
	return *this;
}

Rgb888::~Rgb888() { delete[] buffer_; }
