#include "Rgb888.h"

#if defined(__clang__)
#pragma clang attribute push (__attribute__((target("x87,no-mmx,no-sse,no-avx"))), apply_to = any(function))
#elif defined(__GNUC__) || defined(__GNUG__)
#pragma GCC push_options
#pragma GCC target("tune=generic,no-mmx,no-sse,no-avx")
#else
#error "Unknown compiler"
#endif


template<>
Rgb888 Rgb888::fromYuv420<BASIC>(const Yuv420pFrame &input) {
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

#if defined(__clang__)
#pragma clang attribute pop
#elif defined(__GNUC__) || defined(__GNUG__)
#pragma GCC pop_options
#else
#error "Unknown compiler"
#endif

