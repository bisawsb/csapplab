#include "Yuv420pFrame.h"

#if defined(__clang__)
#pragma clang attribute push (__attribute__((target("x87,no-mmx,no-sse,no-avx"))), apply_to = any(function))
#elif defined(__GNUC__) || defined(__GNUG__)
#pragma GCC push_options
#pragma GCC target("tune=generic,no-mmx,no-sse,no-avx")
#else
#error "Unknown compiler"
#endif
template<>
Yuv420pFrame Yuv420pFrame::fromAlphaMixingRgb888<BASIC>(const Rgb888 &input, int alpha) {
	Yuv420pFrame ret(input.width(), input.height());
	auto *ubuf = new(std::align_val_t(64)) unsigned char[input.width() * input.height()];
	auto *vbuf = new(std::align_val_t(64)) unsigned char[input.width() * input.height()];
	for (size_t pos = 0; pos < ret.width_ * ret.height_; ++pos) {
		float r = alpha * input.rbuffer()[pos] / 256.0f;
		float g = alpha * input.gbuffer()[pos] / 256.0f;
		float b = alpha * input.bbuffer()[pos] / 256.0f;

		int y = 0.256788f * r + 0.504129f * g + 0.097906f * b + 16;
		int u = -0.148223f * r - 0.290993f * g + 0.439216f * b + 128 + 0.5;
		int v = 0.439216f * r - 0.367788f * g - 0.071427f * b + 128 + 0.5;
		ret.ybuffer()[pos] = y;
		ubuf[pos] = u;
		vbuf[pos] = v;
	}
	for (size_t h = 0; h < ret.height_ / 2; ++h) {
		for (size_t w = 0; w < ret.width_ / 2; ++w) {
			size_t base = h * ret.width_ * 2 + w * 2;
			int u1 = ubuf[base];
			int u2 = ubuf[base + 1];
			int u3 = ubuf[base + ret.width_];
			int u4 = ubuf[base + ret.width_ + 1];
			ret.ubuffer()[h * ret.width_ / 2 + w] = (u1 + u2 + u3 + u4) / 4;
		}
	}
	for (size_t h = 0; h < ret.height_ / 2; ++h) {
		for (size_t w = 0; w < ret.width_ / 2; ++w) {
			size_t base = h * ret.width_ * 2 + w * 2;
			int v1 = vbuf[base];
			int v2 = vbuf[base + 1];
			int v3 = vbuf[base + ret.width_];
			int v4 = vbuf[base + ret.width_ + 1];
			ret.vbuffer()[h * ret.width_ / 2 + w] = (v1 + v2 + v3 + v4) / 4;
		}
	}
	delete[] ubuf;
	delete[] vbuf;
	return ret;
}
#if defined(__clang__)
#pragma clang attribute pop
#elif defined(__GNUC__) || defined(__GNUG__)
#pragma GCC pop_options
#else
#error "Unknown compiler"
#endif

