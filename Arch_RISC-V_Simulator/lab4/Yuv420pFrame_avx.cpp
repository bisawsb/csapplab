#include "Yuv420pFrame.h"
#include "debug.h"
#include "signal.h"

#if defined(__clang__)
#pragma clang attribute push(__attribute__((target("avx2"))), apply_to = any(function))
#elif defined(__GNUC__) || defined(__GNUG__)
#pragma GCC push_options
#pragma GCC target("avx2")
#else
#error "Unknown compiler"
#endif

#define DOWNSAMPLE(comp)                                                                                                   \
	do {                                                                                                                   \
		size_t ws = ret.width_ / 32 * 32;                                                                                  \
		for (size_t h = 0; h < ret.height_; h += 2) {                                                                      \
			auto basepos0 = h * ret.width_;                                                                                \
			auto basepos1 = basepos0 + ret.width_;                                                                         \
			auto halfpos = h / 2 * ret.width_ / 2;                                                                         \
			size_t w = 0;                                                                                                  \
			for (; w < ws; w += 32) {                                                                                      \
				auto comp##0 = _mm256_load_si256(reinterpret_cast<const __m256i *>(comp##buf + basepos0)); /* 15-0 */      \
				auto comp##1 = _mm256_load_si256(reinterpret_cast<const __m256i *>(comp##buf + basepos1)); /* 15-0 */      \
				__m256i comp##00, comp##01, comp##10, comp##11;                                                            \
				comp##00 = comp##01 = comp##10 = comp##11 = _mm256_setzero_si256();                                        \
				comp##00 = _mm256_unpackhi_epi8(comp##0, comp##00); /* 15-12, 7-4 */                                       \
				comp##01 = _mm256_unpacklo_epi8(comp##0, comp##01); /* 11-8, 3-0 */                                        \
				comp##10 = _mm256_unpackhi_epi8(comp##1, comp##10); /* 15-12, 7-4 */                                       \
				comp##11 = _mm256_unpacklo_epi8(comp##1, comp##11); /* 11-8, 3-0 */                                        \
				comp##0 = _mm256_hadd_epi16(comp##01, comp##00);                                                           \
				comp##1 = _mm256_hadd_epi16(comp##11, comp##10);                                                           \
				auto comp = _mm256_add_epi16(comp##0, comp##1);                                                            \
				comp = _mm256_srai_epi16(comp, 2);                                                                         \
				const auto vperm = _mm256_setr_epi8(16, 18, 20, 22, 24, 26, 28, 30, -1, -1, -1, -1, -1, -1, -1, -1, 0,     \
													2, 4, 6, 8, 10, 12, 14, -1, -1, -1, -1, -1, -1, -1, -1);               \
				auto shuffled = _mm256_shuffle_epi8(comp, vperm);                                                          \
				int64_t extracted[2]{_mm256_extract_epi64(shuffled, 0), _mm256_extract_epi64(shuffled, 2)};                \
				*(__m128i *) &(ret.comp##buffer()[halfpos]) = *(__m128i *) extracted;                                      \
				basepos0 += 32;                                                                                            \
				basepos1 += 32;                                                                                            \
				halfpos += 16;                                                                                             \
			}                                                                                                              \
			for (; w < ret.width_; ++w) {                                                                                  \
				size_t base = h * ret.width_ + w;                                                                          \
				size_t halfpos = h / 2 * ret.width_ / 2 + w / 2;                                                           \
				int comp##1 = comp##buf[base];                                                                             \
				int comp##2 = comp##buf[base + 1];                                                                         \
				int comp##3 = comp##buf[base + ret.width_];                                                                \
				int comp##4 = comp##buf[base + ret.width_ + 1];                                                            \
				ret.comp##buffer()[halfpos] = (comp##1 + comp##2 + comp##3 + comp##4) / 4;                                 \
			}                                                                                                              \
		}                                                                                                                  \
	} while (0);

template<>
Yuv420pFrame Yuv420pFrame::fromAlphaMixingRgb888<AVX>(const Rgb888 &input, int alpha) {
	Yuv420pFrame ret(input.width(), input.height());
	auto *ubuf = new (std::align_val_t(64)) unsigned char[input.width() * input.height()];
	auto *vbuf = new (std::align_val_t(64)) unsigned char[input.width() * input.height()];
	float alphaf = alpha / 256.0f;
	const auto palpha = _mm256_set_ps(1, alphaf, alphaf, alphaf, 1, alphaf, alphaf, alphaf);
	const auto ycoeff = _mm256_set_ps(16.0f, 0.256788f, 0.504129f, 0.097906f, 16.0f, 0.256788f, 0.504129f, 0.097906f);
	const auto ucoeff =
			_mm256_set_ps(128.0f, -0.148223f, -0.290993f, 0.439216f, 128.0f, -0.148223f, -0.290993f, 0.439216f);
	const auto vcoeff =
			_mm256_set_ps(128.0f, 0.439216f, -0.367788f, -0.071427f, 128.0f, 0.439216f, -0.367788f, -0.071427f);

	for (size_t pos = 0; pos < ret.height_ * ret.width_; pos += 2) {
		auto rgb = _mm256_set_ps(1.0f, input.rbuffer()[pos], input.gbuffer()[pos], input.bbuffer()[pos], 1.0f,
								 input.rbuffer()[pos + 1], input.gbuffer()[pos + 1], input.bbuffer()[pos + 1]);
		rgb = _mm256_mul_ps(rgb, palpha);

		auto ydot = _mm256_dp_ps(rgb, ycoeff, 0xff);
		auto udot = _mm256_dp_ps(rgb, ucoeff, 0xff);
		auto vdot = _mm256_dp_ps(rgb, vcoeff, 0xff);

		auto ytmp = _mm256_cvtps_epi32(ydot);
		auto utmp = _mm256_cvtps_epi32(udot);
		auto vtmp = _mm256_cvtps_epi32(vdot);
		auto y1 = _mm256_extract_epi32(ytmp, 4);
		auto y2 = _mm256_extract_epi32(ytmp, 0);
		auto u1 = _mm256_extract_epi32(utmp, 4);
		auto u2 = _mm256_extract_epi32(utmp, 0);
		auto v1 = _mm256_extract_epi32(vtmp, 4);
		auto v2 = _mm256_extract_epi32(vtmp, 0);

		ret.ybuffer()[pos] = y1;
		ret.ybuffer()[pos + 1] = y2;
		ubuf[pos] = u1;
		ubuf[pos + 1] = u2;
		vbuf[pos] = v1;
		vbuf[pos + 1] = v2;
	}
	DOWNSAMPLE(u);
	DOWNSAMPLE(v);
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
