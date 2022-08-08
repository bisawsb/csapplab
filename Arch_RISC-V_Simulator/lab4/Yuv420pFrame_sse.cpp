#include "Yuv420pFrame.h"
#include "signal.h"

#define DOWNSAMPLE(comp)                                                                                               \
	do {                                                                                                               \
		size_t ws = ret.width_ / 16 * 16;                                                                              \
		for (size_t h = 0; h < ret.height_; h += 2) {                                                                  \
			auto basepos0 = h * ret.width_;                                                                            \
			auto basepos1 = basepos0 + ret.width_;                                                                     \
			auto halfpos = h / 2 * ret.width_ / 2;                                                                     \
			size_t w = 0;                                                                                              \
			for (; w < ws; w += 16) {                                                                                  \
				auto comp##0 = _mm_load_si128(reinterpret_cast<const __m128i *>(comp##buf + basepos0));                \
				auto comp##1 = _mm_load_si128(reinterpret_cast<const __m128i *>(comp##buf + basepos1));                \
				__m128i comp##00, comp##01, comp##10, comp##11;                                                        \
                                                                                                                       \
				comp##00 = comp##01 = comp##10 = comp##11 = _mm_setzero_si128();                                       \
				comp##00 = _mm_unpackhi_epi8(comp##0, comp##00);                                                       \
				comp##01 = _mm_unpacklo_epi8(comp##0, comp##01);                                                       \
				comp##10 = _mm_unpackhi_epi8(comp##1, comp##10);                                                       \
				comp##11 = _mm_unpacklo_epi8(comp##1, comp##11);                                                       \
				comp##0 = _mm_hadd_epi16(comp##01, comp##00);                                                          \
				comp##1 = _mm_hadd_epi16(comp##11, comp##10);                                                          \
				auto comp = _mm_add_epi16(comp##0, comp##1);                                                           \
				comp = _mm_srai_epi16(comp, 2);                                                                        \
				const auto vperm = _mm_setr_epi8(0, 2, 4, 6, 8, 10, 12, 14, -1, -1, -1, -1, -1, -1, -1, -1);           \
				auto shuffled = _mm_shuffle_epi8(comp, vperm);                                                         \
				auto extracted = _mm_extract_epi64(shuffled, 0);                                                       \
				*(int64_t *) &(ret.comp##buffer()[halfpos]) = extracted;                                               \
				basepos0 += 16;                                                                                        \
				basepos1 += 16;                                                                                        \
				halfpos += 8;                                                                                          \
			}                                                                                                          \
			for (; w < ret.width_; ++w) {                                                                              \
				size_t base = h * ret.width_ + w;                                                                      \
				size_t halfpos = h / 2 * ret.width_ / 2 + w / 2;                                                       \
				int comp##1 = comp##buf[base];                                                                         \
				int comp##2 = comp##buf[base + 1];                                                                     \
				int comp##3 = comp##buf[base + ret.width_];                                                            \
				int comp##4 = comp##buf[base + ret.width_ + 1];                                                        \
				ret.comp##buffer()[halfpos] = (comp##1 + comp##2 + comp##3 + comp##4) / 4;                             \
			}                                                                                                          \
		}                                                                                                              \
	} while (0);

#if defined(__clang__)
#pragma clang attribute push(__attribute__((target("ssse3,sse4.2,no-avx"))), apply_to = any(function))
#elif defined(__GNUC__) || defined(__GNUG__)
#pragma GCC push_options
#pragma GCC target("ssse3,sse4.2,no-avx")
#else
#error "Unknown compiler"
#endif

template<>
Yuv420pFrame Yuv420pFrame::fromAlphaMixingRgb888<(ExecutePolicy)(SSE)>(const Rgb888 &input, int alpha) {
	Yuv420pFrame ret(input.width(), input.height());
	auto *ubuf = new (std::align_val_t(64)) unsigned char[input.width() * input.height()];
	auto *vbuf = new (std::align_val_t(64)) unsigned char[input.width() * input.height()];
	float alphaf = alpha / 256.0f;
	const auto palpha = _mm_set_ps(1, alphaf, alphaf, alphaf);
	const auto ycoeff = _mm_set_ps(16.0f, 0.256788f, 0.504129f, 0.097906f);
	const auto ucoeff = _mm_set_ps(128.0f, -0.148223f, -0.290993f, 0.439216f);
	const auto vcoeff = _mm_set_ps(128.0f, 0.439216f, -0.367788f, -0.071427f);

	for (size_t pos = 0; pos < ret.height_ * ret.width_; ++pos) {
		auto rgb = _mm_set_ps(1.0f, input.rbuffer()[pos], input.gbuffer()[pos], input.bbuffer()[pos]);
		rgb = _mm_mul_ps(rgb, palpha);

		auto y = _mm_cvtss_si32(_mm_dp_ps(rgb, ycoeff, 0xff));
		auto u = _mm_cvtss_si32(_mm_dp_ps(rgb, ucoeff, 0xff));
		auto v = _mm_cvtss_si32(_mm_dp_ps(rgb, vcoeff, 0xff));

		ret.ybuffer()[pos] = y;
		ubuf[pos] = u;
		vbuf[pos] = v;
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

#undef DOWNSAMPLE
