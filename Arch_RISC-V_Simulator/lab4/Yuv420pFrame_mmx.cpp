#include "Yuv420pFrame.h"

#if defined(__clang__)
#pragma clang attribute push (__attribute__((target("mmx,ssse3,no-avx"))), apply_to = any(function))
#elif defined(__GNUC__) || defined(__GNUG__)
#pragma GCC push_options
#pragma GCC target("tune=generic")
#else
#error "Unknown compiler"
#endif

template<>
Yuv420pFrame Yuv420pFrame::fromAlphaMixingRgb888<MMX>(const Rgb888 &input, int alpha) {
	Yuv420pFrame ret(input.width(), input.height());
	auto *ubuf = new (std::align_val_t(64)) unsigned char[input.width() * input.height()];
	auto *vbuf = new (std::align_val_t(64)) unsigned char[input.width() * input.height()];
	const auto palpha = _mm_set_pi16(1, alpha, alpha, alpha);
	const auto ycoeff = _mm_set_pi16(32, 8414, 16519, 3208);
	const auto ucoeff = _mm_set_pi16(256, -4856, -9535, 14392);
	const auto vcoeff = _mm_set_pi16(256, 14392, -12051, -2340);
	for (size_t pos = 0; pos < ret.height_ * ret.width_; ++pos) {
		auto rgb = _mm_set_pi16(0, input.rbuffer()[pos], input.gbuffer()[pos], input.bbuffer()[pos]);
		rgb = _m_pmullw(rgb, palpha);
		rgb = _mm_srli_pi16(rgb, 8);
		rgb = _m_from_int64(static_cast<int64_t>(0x4000000000000000ull | static_cast<uint64_t>(_m_to_int64(rgb))));

		auto ypartial = _m_pmaddwd(rgb, ycoeff);
		auto upartial = _m_pmaddwd(rgb, ucoeff);
		auto vpartial = _m_pmaddwd(rgb, vcoeff);

		uint64_t ytmp = _m_to_int64(ypartial);
		uint64_t utmp = _m_to_int64(upartial);
		uint64_t vtmp = _m_to_int64(vpartial);

		uint64_t y = ((int32_t) ytmp + (int32_t)(ytmp >> 32u)) >> 15u;
		uint64_t u = ((int32_t) utmp + (int32_t)(utmp >> 32u)) >> 15u;
		uint64_t v = ((int32_t) vtmp + (int32_t)(vtmp >> 32u)) >> 15u;

		//if (y > 255 || u > 255 || v > 255) {
		// printf("%u, %u, %u, %llx, %llx, %llx, %llx, %llx, %llx, %llx\n", input.rbuffer()[pos], input.gbuffer()[pos], input.bbuffer()[pos], _m_to_int64(rgb), ytmp, y, utmp, u, vtmp, v);
		//}

		ret.ybuffer()[pos] = y;
		ubuf[pos] = u;
		vbuf[pos] = v;
	}
#define MMX_DOWNSAMPLING(component)                                                                                    \
	do {                                                                                                               \
		for (size_t h = 0; h < ret.height_ / 2; ++h) {                                                                 \
			size_t w = 0;                                                                                              \
			for (; w < ret.width_ / 2 - 3; w += 4) {                                                                   \
				size_t base1 = h * ret.width_ * 2 + w * 2;                                                             \
				size_t base2 = base1 + 2;                                                                              \
				size_t base3 = base2 + 2;                                                                              \
				size_t base4 = base3 + 2;                                                                              \
				auto component##1 = _mm_set_pi16(component##buf[base1], component##buf[base2], component##buf[base3],  \
												 component##buf[base4]);                                               \
				auto component##2 = _mm_set_pi16(component##buf[base1 + 1], component##buf[base2 + 1],                 \
												 component##buf[base3 + 1], component##buf[base4 + 1]);                \
				auto component##3 =                                                                                    \
						_mm_set_pi16(component##buf[base1 + ret.width_], component##buf[base2 + ret.width_],           \
									 component##buf[base3 + ret.width_], component##buf[base4 + ret.width_]);          \
				auto component##4 =                                                                                    \
						_mm_set_pi16(component##buf[base1 + ret.width_ + 1], component##buf[base2 + ret.width_ + 1],   \
									 component##buf[base3 + ret.width_ + 1], component##buf[base4 + ret.width_ + 1]);  \
				auto tmp = _mm_add_pi16(component##1, component##2);                                                   \
				tmp = _mm_add_pi16(tmp, component##3);                                                                 \
				tmp = _mm_add_pi16(tmp, component##4);                                                                 \
				tmp = _mm_srli_pi16(tmp, 2);                                                                           \
				uint64_t component = _m_to_int64(tmp);                                                                 \
				ret.component##buffer()[h * ret.width_ / 2 + w] = component >> 48;                                     \
				ret.component##buffer()[h * ret.width_ / 2 + w + 1] = component >> 32;                                 \
				ret.component##buffer()[h * ret.width_ / 2 + w + 2] = component >> 16;                                 \
				ret.component##buffer()[h * ret.width_ / 2 + w + 3] = component;                                       \
			}                                                                                                          \
			for (; w < ret.width_ / 2; ++w) {                                                                          \
				size_t base = h * ret.width_ * 2 + w * 2;                                                              \
				int component##1 = component##buf[base];                                                               \
				int component##2 = component##buf[base + 1];                                                           \
				int component##3 = component##buf[base + ret.width_];                                                  \
				int component##4 = component##buf[base + ret.width_ + 1];                                              \
				ret.component##buffer()[h * ret.width_ / 2 + w] =                                                      \
						(component##1 + component##2 + component##3 + component##4) / 4;                               \
			};                                                                                                         \
		}                                                                                                              \
	} while (0)
	MMX_DOWNSAMPLING(u);
	MMX_DOWNSAMPLING(v);
#undef MMX_DOWNSAMPLING
	return ret;
}
#if defined(__clang__)
#pragma clang attribute pop
#elif defined(__GNUC__) || defined(__GNUG__)
#pragma GCC pop_options
#else
#error "Unknown compiler"
#endif

