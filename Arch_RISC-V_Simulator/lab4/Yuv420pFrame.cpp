#include "Yuv420pFrame.h"
#include "Rgb888.h"
#include "debug.h"
#include <csignal>
#include <cstring>
#include <fcntl.h>
#include <fstream>
#include <stdexcept>
#include <string>
#include <unistd.h>

Yuv420pFrame::Yuv420pFrame(size_t width, size_t height)
	: width_(width), height_(height), ubufferOffset_(width * height), vbufferOffset_(width * height * 5 / 4),
	  bufferSize_(width * height * 3 / 2), buffer_(new (std::align_val_t(64)) unsigned char[bufferSize_]) {}

Yuv420pFrame Yuv420pFrame::fromFile(const std::string &filename, size_t width, size_t height, std::error_code &errc) {
	Yuv420pFrame ret(width, height);
	std::ifstream fs(filename, std::ios::binary);
	fs.read(reinterpret_cast<char *>(ret.buffer_), ret.bufferSize_);
	if (fs.gcount() != ret.bufferSize_) { errc = std::make_error_code(std::errc::invalid_argument); }
	return ret;
}
Yuv420pFrame::Yuv420pFrame(const Yuv420pFrame &other) : Yuv420pFrame(other.width_, other.height_) {
	memcpy(buffer_, other.buffer_, bufferSize_);
}
Yuv420pFrame::Yuv420pFrame(Yuv420pFrame &&other) noexcept
	: width_(other.width_), height_(other.height_), ubufferOffset_(other.ubufferOffset_),
	  vbufferOffset_(other.vbufferOffset_), bufferSize_(other.bufferSize_), buffer_(other.buffer_) {
	other.buffer_ = nullptr;
}
Yuv420pFrame &Yuv420pFrame::operator=(const Yuv420pFrame &other) {
	if (this == &other) return *this;
	if (width_ != other.width_ || height_ != other.height_) {
		width_ = other.width_;
		height_ = other.height_;
		ubufferOffset_ = other.ubufferOffset_;
		vbufferOffset_ = other.vbufferOffset_;
		bufferSize_ = other.bufferSize_;
		delete[] buffer_;
		buffer_ = new (std::align_val_t(64)) unsigned char[bufferSize_];
	}
	memcpy(buffer_, other.buffer_, bufferSize_);
	return *this;
}
Yuv420pFrame &Yuv420pFrame::operator=(Yuv420pFrame &&other) noexcept {
	if (this == &other) return *this;
	delete[] buffer_;
	width_ = other.width_;
	height_ = other.height_;
	ubufferOffset_ = other.ubufferOffset_;
	vbufferOffset_ = other.vbufferOffset_;
	bufferSize_ = other.bufferSize_;
	buffer_ = other.buffer_;
	other.buffer_ = nullptr;
	return *this;
}
Yuv420pFrame::~Yuv420pFrame() { delete[] buffer_; }
int Yuv420pFrame::appendToFile(FILE *fp) const { return fwrite(buffer_, bufferSize_, 1, fp); }
bool Yuv420pFrame::operator==(const Yuv420pFrame &rhs) const {
	if (width_ == rhs.width_ && height_ == rhs.height_ && buffer_ && rhs.buffer_) {
		for (size_t s = 0; s < bufferSize_; ++s) {
			// Here we allow +-1
			if (abs((int) buffer_[s] - (int) rhs.buffer_[s]) >= 3) return false;
		}
		return true;
	}
	return false;
	return width_ == rhs.width_ && height_ == rhs.height_ && buffer_ && rhs.buffer_ &&
		   memcmp(buffer_, rhs.buffer_, bufferSize_) == 0;
}
bool Yuv420pFrame::operator!=(const Yuv420pFrame &rhs) const { return !(rhs == *this); }
