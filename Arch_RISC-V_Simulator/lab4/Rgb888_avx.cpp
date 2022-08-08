#include "Rgb888.h"

#if defined(__clang__)
#pragma clang attribute push(__attribute__((target("avx2"))), apply_to = any(function))
#elif defined(__GNUC__) || defined(__GNUG__)
#pragma GCC push_options
#pragma GCC target("avx2")
#else
#error "Unknown compiler"
#endif

static __inline__ __m256 cvt256epi16_ps(__m256i a, const int imm8) {
	__m256i b;

	b = _mm256_setzero_si256();
	b = _mm256_cmpgt_epi16(b, a);
	if (imm8 & 0x1) b = _mm256_unpackhi_epi16(a, b);
	else
		b = _mm256_unpacklo_epi16(a, b);

	return _mm256_cvtepi32_ps(b);
}

template<int imm8>
static __inline__ float extract256_ps_float(__m256 a) {
	__m256i a1 = _mm256_castps_si256(a);
	int val = _mm256_extract_epi32(a1, imm8);
	return *(float *) &val;
}

template<>
Rgb888 Rgb888::fromYuv420<(ExecutePolicy) AVX>(const Yuv420pFrame &input) {
	Rgb888 ret(input.width(), input.height());

	const auto yaddent = _mm256_set1_epi16(-16);
	const auto uvaddent = _mm256_set1_epi16(-128);
	const auto ycoeff = _mm256_set1_ps(1.164383);
	const auto vrcoeff = _mm256_set1_ps(1.596027);
	const auto ugcoeff = _mm256_set1_ps(-0.391762);
	const auto vgcoeff = _mm256_set1_ps(-0.812968);
	const auto ubcoeff = _mm256_set1_ps(2.017232);
	const auto zeroepi32 = _mm256_set1_epi32(0);
	const auto maximumepi32 = _mm256_set1_epi32(255);

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

#define AVX_DECL_Y(baseposval, num)                                                                                    \
	size_t pos##num = (baseposval);                                                                                    \
	size_t pos##num##next = pos##num + ret.width_;                                                                     \
	uint8_t y##num##_1 = input.ybuffer()[pos##num];                                                                    \
	uint8_t y##num##_2 = input.ybuffer()[pos##num + 1];                                                                \
	uint8_t y##num##_3 = input.ybuffer()[pos##num##next];                                                              \
	uint8_t y##num##_4 = input.ybuffer()[pos##num##next + 1];

#define AVX_DECL_UV(basepos, num, idx)                                                                                 \
	uint8_t u##idx = input.ubuffer()[basepos + num];                                                                   \
	uint8_t v##idx = input.vbuffer()[basepos + num]

#define AVX_EXTRACT_TO_BUFFER(component, num1, num2)                                                                       \
	do {                                                                                                                   \
		auto component##num1##num2##int32 = _mm256_cvtps_epi32(component##num1##num2);                                     \
		component##num1##num2##int32 = _mm256_min_epi32(component##num1##num2##int32, maximumepi32);                       \
		component##num1##num2##int32 = _mm256_max_epi32(component##num1##num2##int32, zeroepi32);                          \
		ret.component##buffer()[pos##num1] = _mm256_extract_epi32(component##num1##num2##int32, 7);                        \
		ret.component##buffer()[pos##num1 + 1] = _mm256_extract_epi32(component##num1##num2##int32, 6);                    \
		ret.component##buffer()[pos##num1##next] = _mm256_extract_epi32(component##num1##num2##int32, 5);                  \
		ret.component##buffer()[pos##num1##next + 1] = _mm256_extract_epi32(component##num1##num2##int32, 4);              \
		ret.component##buffer()[pos##num2] = _mm256_extract_epi32(component##num1##num2##int32, 3);                        \
		ret.component##buffer()[pos##num2 + 1] = _mm256_extract_epi32(component##num1##num2##int32, 2);                    \
		ret.component##buffer()[pos##num2##next] = _mm256_extract_epi32(component##num1##num2##int32, 1);                  \
		ret.component##buffer()[pos##num2##next + 1] = _mm256_extract_epi32(component##num1##num2##int32, 0);              \
	} while (0)

#define AVX_CALCULATE_R_SINGLE(vrvec, num1, num2)                                                                      \
	do {                                                                                                               \
		auto vr##num1 = extract256_ps_float<(8 - num1 % 8) % 8>(vrvec);                                                \
		auto vr##num2 = extract256_ps_float<(8 - num2 % 8) % 8>(vrvec);                                                \
		auto vr##num1##num2##vec =                                                                                     \
				_mm256_set_ps(vr##num1, vr##num1, vr##num1, vr##num1, vr##num2, vr##num2, vr##num2, vr##num2);         \
		auto r##num1##num2 = _mm256_add_ps(y##num1##num2, vr##num1##num2##vec);                                        \
		AVX_EXTRACT_TO_BUFFER(r, num1, num2);                                                                          \
	} while (0)

#define AVX_CALCULATE_R_FOUR_IMPL(num1, num2, num3, num4, num5, num6, num7, num8, num12345678)                         \
	do {                                                                                                               \
		auto vr##num12345678 = _mm256_mul_ps(v##num12345678##vec, vrcoeff);                                            \
		AVX_CALCULATE_R_SINGLE(vr##num12345678, num1, num2);                                                           \
		AVX_CALCULATE_R_SINGLE(vr##num12345678, num3, num4);                                                           \
		AVX_CALCULATE_R_SINGLE(vr##num12345678, num5, num6);                                                           \
		AVX_CALCULATE_R_SINGLE(vr##num12345678, num7, num8);                                                           \
	} while (0)

#define AVX_CALCULATE_R_FOUR(num1, num2, num3, num4, num5, num6, num7, num8)                                           \
	AVX_CALCULATE_R_FOUR_IMPL(num1, num2, num3, num4, num5, num6, num7, num8,                                          \
							  num1##num2##num3##num4##num5##num6##num7##num8)

#define AVX_CALCULATE_G_SINGLE(ugvec, vgvec, num1, num2)                                                               \
	do {                                                                                                               \
		auto ug##num1 = extract256_ps_float<(8 - num1 % 8) % 8>(ugvec);                                                \
		auto ug##num2 = extract256_ps_float<(8 - num2 % 8) % 8>(ugvec);                                                \
		auto ug##num1##num2##vec =                                                                                     \
				_mm256_set_ps(ug##num1, ug##num1, ug##num1, ug##num1, ug##num2, ug##num2, ug##num2, ug##num2);         \
		auto vg##num1 = extract256_ps_float<(8 - num1 % 8) % 8>(vgvec);                                                \
		auto vg##num2 = extract256_ps_float<(8 - num2 % 8) % 8>(vgvec);                                                \
		auto vg##num1##num2##vec =                                                                                     \
				_mm256_set_ps(vg##num1, vg##num1, vg##num1, vg##num1, vg##num2, vg##num2, vg##num2, vg##num2);         \
		auto g##num1##num2 = _mm256_add_ps(_mm256_add_ps(y##num1##num2, ug##num1##num2##vec), vg##num1##num2##vec);    \
		AVX_EXTRACT_TO_BUFFER(g, num1, num2);                                                                          \
	} while (0)

#define AVX_CALCULATE_G_FOUR_IMPL(num1, num2, num3, num4, num5, num6, num7, num8, num12345678)                         \
	do {                                                                                                               \
		auto ug##num12345678 = _mm256_mul_ps(u##num12345678##vec, ugcoeff);                                            \
		auto vg##num12345678 = _mm256_mul_ps(v##num12345678##vec, vgcoeff);                                            \
		AVX_CALCULATE_G_SINGLE(ug##num12345678, vg##num12345678, num1, num2);                                          \
		AVX_CALCULATE_G_SINGLE(ug##num12345678, vg##num12345678, num3, num4);                                          \
		AVX_CALCULATE_G_SINGLE(ug##num12345678, vg##num12345678, num5, num6);                                          \
		AVX_CALCULATE_G_SINGLE(ug##num12345678, vg##num12345678, num7, num8);                                          \
	} while (0)

#define AVX_CALCULATE_G_FOUR(num1, num2, num3, num4, num5, num6, num7, num8)                                           \
	AVX_CALCULATE_G_FOUR_IMPL(num1, num2, num3, num4, num5, num6, num7, num8,                                          \
							  num1##num2##num3##num4##num5##num6##num7##num8)

#define AVX_CALCULATE_B_SINGLE(ubvec, num1, num2)                                                                      \
	do {                                                                                                               \
		auto ub##num1 = extract256_ps_float<(8 - num1 % 8) % 8>(ubvec);                                                \
		auto ub##num2 = extract256_ps_float<(8 - num2 % 8) % 8>(ubvec);                                                \
		auto ub##num1##num2##vec =                                                                                     \
				_mm256_set_ps(ub##num1, ub##num1, ub##num1, ub##num1, ub##num2, ub##num2, ub##num2, ub##num2);         \
		auto b##num1##num2 = _mm256_add_ps(y##num1##num2, ub##num1##num2##vec);                                        \
		AVX_EXTRACT_TO_BUFFER(b, num1, num2);                                                                          \
	} while (0)

#define AVX_CALCULATE_B_FOUR_IMPL(num1, num2, num3, num4, num5, num6, num7, num8, num12345678)                         \
	do {                                                                                                               \
		auto ub##num12345678 = _mm256_mul_ps(u##num12345678##vec, ubcoeff);                                            \
		AVX_CALCULATE_B_SINGLE(ub##num12345678, num1, num2);                                                           \
		AVX_CALCULATE_B_SINGLE(ub##num12345678, num3, num4);                                                           \
		AVX_CALCULATE_B_SINGLE(ub##num12345678, num5, num6);                                                           \
		AVX_CALCULATE_B_SINGLE(ub##num12345678, num7, num8);                                                           \
	} while (0)

#define AVX_CALCULATE_B_FOUR(num1, num2, num3, num4, num5, num6, num7, num8)                                           \
	AVX_CALCULATE_B_FOUR_IMPL(num1, num2, num3, num4, num5, num6, num7, num8,                                          \
							  num1##num2##num3##num4##num5##num6##num7##num8)

#define AVX_CALCULATE_RGB_FOUR(num1, num2, num3, num4, num5, num6, num7, num8)                                         \
	do {                                                                                                               \
		AVX_CALCULATE_R_FOUR(num1, num2, num3, num4, num5, num6, num7, num8);                                          \
		AVX_CALCULATE_G_FOUR(num1, num2, num3, num4, num5, num6, num7, num8);                                          \
		AVX_CALCULATE_B_FOUR(num1, num2, num3, num4, num5, num6, num7, num8);                                          \
	} while (0)


#define AVX_CALCULATE(commondiff, commondiff2)                                                                         \
	do {                                                                                                               \
		AVX_DECL_Y(h *ret.width_ + w, 1);                                                                              \
		AVX_DECL_Y(pos1 + commondiff * 2, 2);                                                                          \
		AVX_DECL_Y(pos2 + commondiff * 2, 3);                                                                          \
		AVX_DECL_Y(pos3 + commondiff * 2, 4);                                                                          \
		AVX_DECL_Y(pos4 + commondiff * 2, 5);                                                                          \
		AVX_DECL_Y(pos5 + commondiff * 2, 6);                                                                          \
		AVX_DECL_Y(pos6 + commondiff * 2, 7);                                                                          \
		AVX_DECL_Y(pos7 + commondiff * 2, 8);                                                                          \
                                                                                                                       \
		size_t halfpos = h / 2 * ret.width_ / 2 + w / 2;                                                               \
		AVX_DECL_UV(halfpos, 0 * commondiff2, 1);                                                                      \
		AVX_DECL_UV(halfpos, 1 * commondiff2, 2);                                                                      \
		AVX_DECL_UV(halfpos, 2 * commondiff2, 3);                                                                      \
		AVX_DECL_UV(halfpos, 3 * commondiff2, 4);                                                                      \
		AVX_DECL_UV(halfpos, 4 * commondiff2, 5);                                                                      \
		AVX_DECL_UV(halfpos, 5 * commondiff2, 6);                                                                      \
		AVX_DECL_UV(halfpos, 6 * commondiff2, 7);                                                                      \
		AVX_DECL_UV(halfpos, 7 * commondiff2, 8);                                                                      \
                                                                                                                       \
		auto y1234vec = _mm256_set_epi16(y1_1, y1_2, y1_3, y1_4, y3_1, y3_2, y3_3, y3_4, y2_1, y2_2, y2_3, y2_4, y4_1, \
										 y4_2, y4_3, y4_4);                                                            \
		auto y5678vec = _mm256_set_epi16(y5_1, y5_2, y5_3, y5_4, y7_1, y7_2, y7_3, y7_4, y6_1, y6_2, y6_3, y6_4, y8_1, \
										 y8_2, y8_3, y8_4);                                                            \
		auto uvvec = _mm256_set_epi16(u1, u2, u3, u4, v1, v2, v3, v4, u5, u6, u7, u8, v5, v6, v7, v8);                 \
                                                                                                                       \
		uvvec = _mm256_add_epi16(uvvec, uvaddent);                                                                     \
                                                                                                                       \
		y1234vec = _mm256_add_epi16(y1234vec, yaddent);                                                                \
		y5678vec = _mm256_add_epi16(y5678vec, yaddent);                                                                \
                                                                                                                       \
		auto y12 = cvt256epi16_ps(y1234vec, 0x1);                                                                      \
		auto y34 = cvt256epi16_ps(y1234vec, 0x0);                                                                      \
		auto y56 = cvt256epi16_ps(y5678vec, 0x1);                                                                      \
		auto y78 = cvt256epi16_ps(y5678vec, 0x0);                                                                      \
                                                                                                                       \
		y12 = _mm256_mul_ps(y12, ycoeff);                                                                              \
		y34 = _mm256_mul_ps(y34, ycoeff);                                                                              \
		y56 = _mm256_mul_ps(y56, ycoeff);                                                                              \
		y78 = _mm256_mul_ps(y78, ycoeff);                                                                              \
                                                                                                                       \
		auto u12345678vec = cvt256epi16_ps(uvvec, 0x1);                                                                \
		auto v12345678vec = cvt256epi16_ps(uvvec, 0x0);                                                                \
                                                                                                                       \
		AVX_CALCULATE_RGB_FOUR(1, 2, 3, 4, 5, 6, 7, 8);                                                                \
	} while (0)

	size_t ws = ret.width_ / 16 * 16;
	size_t hs = ret.height_ / 16 * 16;

	for (size_t h = 0; h < ret.height_; h += 2) {
		for (size_t w = 0; w < ws; w += 16) { AVX_CALCULATE(1, 1); }
	}
	for (size_t w = ws; w < ret.width_; w += 2) {
		for (size_t h = 0; h < hs; h += 16) {
			auto halfwidth = ret.width_ / 2;
			AVX_CALCULATE(ret.width_, halfwidth);
		}
	}
	for (size_t h = hs; h < ret.height_; ++h) {
		for (size_t w = ws; w < ret.width_; ++w) {
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
