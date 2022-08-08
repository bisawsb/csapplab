#include "Rgb888.h"

#if defined(__clang__)
#pragma clang attribute push(__attribute__((target("ssse3,sse4.2,no-avx"))), apply_to = any(function))
#elif defined(__GNUC__) || defined(__GNUG__)
#pragma GCC push_options
#pragma GCC target("ssse3,sse4.2,no-avx")
#else
#error "Unknown compiler"
#endif


static __inline__ __m128 cvtepi16_ps(__m128i a, const int imm8) {
	__m128i b;

	b = _mm_setzero_si128();
	b = _mm_cmpgt_epi16(b, a);
	if (imm8 & 0x1) b = _mm_unpackhi_epi16(a, b);
	else
		b = _mm_unpacklo_epi16(a, b);

	return _mm_cvtepi32_ps(b);
}

template<int imm8>
static __inline__ float extract_ps_float(__m128 a) {
	int val = _mm_extract_ps(a, imm8);
	return *(float *) &val;
}

template<>
Rgb888 Rgb888::fromYuv420<(ExecutePolicy) SSE>(const Yuv420pFrame &input) {
	Rgb888 ret(input.width(), input.height());

	const auto yaddent = _mm_set1_epi16(-16);
	const auto uvaddent = _mm_set1_epi16(-128);
	const auto ycoeff = _mm_set1_ps(1.164383);
	const auto vrcoeff = _mm_set1_ps(1.596027);
	const auto ugcoeff = _mm_set1_ps(-0.391762);
	const auto vgcoeff = _mm_set1_ps(-0.812968);
	const auto ubcoeff = _mm_set1_ps(2.017232);
	const auto zeroepi32 = _mm_set1_epi32(0);
	const auto maximumepi32 = _mm_set1_epi32(255);

#define SSE_DECL_Y(baseposval, num)                                                                                    \
	size_t pos##num = (baseposval);                                                                                    \
	size_t pos##num##next = pos##num + ret.width_;                                                                     \
	uint8_t y##num##1 = input.ybuffer()[pos##num];                                                                     \
	uint8_t y##num##2 = input.ybuffer()[pos##num + 1];                                                                 \
	uint8_t y##num##3 = input.ybuffer()[pos##num##next];                                                               \
	uint8_t y##num##4 = input.ybuffer()[pos##num##next + 1];

#define SSE_DECL_UV(basepos, num, idx)                                                                                 \
	uint8_t u##idx = input.ubuffer()[basepos + num];                                                                   \
	uint8_t v##idx = input.vbuffer()[basepos + num]

#define SSE_EXTRACT_TO_BUFFER(component, num)                                                                          \
	do {                                                                                                               \
		auto component##num##int32 = _mm_cvtps_epi32(component##num);                                                  \
		component##num##int32 = _mm_min_epi32(component##num##int32, maximumepi32);                                    \
		component##num##int32 = _mm_max_epi32(component##num##int32, zeroepi32);                                       \
		ret.component##buffer()[pos##num] = _mm_extract_epi32(component##num##int32, 3);                               \
		ret.component##buffer()[pos##num + 1] = _mm_extract_epi32(component##num##int32, 2);                           \
		ret.component##buffer()[pos##num##next] = _mm_extract_epi32(component##num##int32, 1);                         \
		ret.component##buffer()[pos##num##next + 1] = _mm_extract_epi32(component##num##int32, 0);                     \
	} while (0)

#define SSE_CALCULATE_R_SINGLE(vrvec, num)                                                                             \
	do {                                                                                                               \
		auto vr##num = extract_ps_float<(4 - num % 4) % 4>(vrvec);                                                     \
		auto vr##num##vec = _mm_set1_ps(vr##num);                                                                      \
		auto r##num = _mm_add_ps(y##num, vr##num##vec);                                                                \
		SSE_EXTRACT_TO_BUFFER(r, num);                                                                                 \
	} while (0)

#define SSE_CALCULATE_R_FOUR_IMPL(num1, num2, num3, num4, num1234)                                                     \
	do {                                                                                                               \
		auto vr##num1234 = _mm_mul_ps(v##num1234##vec, vrcoeff);                                                       \
		SSE_CALCULATE_R_SINGLE(vr##num1234, num1);                                                                     \
		SSE_CALCULATE_R_SINGLE(vr##num1234, num2);                                                                     \
		SSE_CALCULATE_R_SINGLE(vr##num1234, num3);                                                                     \
		SSE_CALCULATE_R_SINGLE(vr##num1234, num4);                                                                     \
	} while (0)

#define SSE_CALCULATE_R_FOUR(num1, num2, num3, num4)                                                                   \
	SSE_CALCULATE_R_FOUR_IMPL(num1, num2, num3, num4, num1##num2##num3##num4)

#define SSE_CALCULATE_G_SINGLE(ugvec, vgvec, num)                                                                      \
	do {                                                                                                               \
		auto ug##num = extract_ps_float<(4 - num % 4) % 4>(ugvec);                                                     \
		auto ug##num##vec = _mm_set1_ps(ug##num);                                                                      \
		auto vg##num = extract_ps_float<(4 - num % 4) % 4>(vgvec);                                                     \
		auto vg##num##vec = _mm_set1_ps(vg##num);                                                                      \
		auto g##num = _mm_add_ps(_mm_add_ps(y##num, ug##num##vec), vg##num##vec);                                      \
		SSE_EXTRACT_TO_BUFFER(g, num);                                                                                 \
	} while (0)

#define SSE_CALCULATE_G_FOUR_IMPL(num1, num2, num3, num4, num1234)                                                     \
	do {                                                                                                               \
		auto ug##num1234 = _mm_mul_ps(u##num1234##vec, ugcoeff);                                                       \
		auto vg##num1234 = _mm_mul_ps(v##num1234##vec, vgcoeff);                                                       \
		SSE_CALCULATE_G_SINGLE(ug##num1234, vg##num1234, num1);                                                        \
		SSE_CALCULATE_G_SINGLE(ug##num1234, vg##num1234, num2);                                                        \
		SSE_CALCULATE_G_SINGLE(ug##num1234, vg##num1234, num3);                                                        \
		SSE_CALCULATE_G_SINGLE(ug##num1234, vg##num1234, num4);                                                        \
	} while (0)

#define SSE_CALCULATE_G_FOUR(num1, num2, num3, num4)                                                                   \
	SSE_CALCULATE_G_FOUR_IMPL(num1, num2, num3, num4, num1##num2##num3##num4)


#define SSE_CALCULATE_B_SINGLE(ubvec, num)                                                                             \
	do {                                                                                                               \
		auto ub##num = extract_ps_float<(4 - num % 4) % 4>(ubvec);                                                     \
		auto ub##num##vec = _mm_set1_ps(ub##num);                                                                      \
		auto b##num = _mm_add_ps(y##num, ub##num##vec);                                                                \
		SSE_EXTRACT_TO_BUFFER(b, num);                                                                                 \
	} while (0)

#define SSE_CALCULATE_B_FOUR_IMPL(num1, num2, num3, num4, num1234)                                                     \
	do {                                                                                                               \
		auto ub##num1234 = _mm_mul_ps(u##num1234##vec, ubcoeff);                                                       \
		SSE_CALCULATE_B_SINGLE(ub##num1234, num1);                                                                     \
		SSE_CALCULATE_B_SINGLE(ub##num1234, num2);                                                                     \
		SSE_CALCULATE_B_SINGLE(ub##num1234, num3);                                                                     \
		SSE_CALCULATE_B_SINGLE(ub##num1234, num4);                                                                     \
	} while (0)

#define SSE_CALCULATE_B_FOUR(num1, num2, num3, num4)                                                                   \
	SSE_CALCULATE_B_FOUR_IMPL(num1, num2, num3, num4, num1##num2##num3##num4)

#define SSE_CALCULATE_RGB_FOUR(num1, num2, num3, num4)                                                                 \
	do {                                                                                                               \
		SSE_CALCULATE_R_FOUR(num1, num2, num3, num4);                                                                  \
		SSE_CALCULATE_G_FOUR(num1, num2, num3, num4);                                                                  \
		SSE_CALCULATE_B_FOUR(num1, num2, num3, num4);                                                                  \
	} while (0)


#define SSE_CALCULATE(commondiff, commondiff2)                                                                         \
	do {                                                                                                               \
		SSE_DECL_Y(h *ret.width_ + w, 1);                                                                              \
		SSE_DECL_Y(pos1 + commondiff * 2, 2);                                                                          \
		SSE_DECL_Y(pos2 + commondiff * 2, 3);                                                                          \
		SSE_DECL_Y(pos3 + commondiff * 2, 4);                                                                          \
                                                                                                                       \
		size_t halfpos = h / 2 * ret.width_ / 2 + w / 2;                                                               \
		SSE_DECL_UV(halfpos, 0 * commondiff2, 1);                                                                      \
		SSE_DECL_UV(halfpos, 1 * commondiff2, 2);                                                                      \
		SSE_DECL_UV(halfpos, 2 * commondiff2, 3);                                                                      \
		SSE_DECL_UV(halfpos, 3 * commondiff2, 4);                                                                      \
                                                                                                                       \
		auto y12vec = _mm_set_epi16(y11, y12, y13, y14, y21, y22, y23, y24);                                           \
		auto y34vec = _mm_set_epi16(y31, y32, y33, y34, y41, y42, y43, y44);                                           \
		auto uvvec = _mm_set_epi16(u1, u2, u3, u4, v1, v2, v3, v4);                                                    \
                                                                                                                       \
		uvvec = _mm_add_epi16(uvvec, uvaddent);                                                                        \
                                                                                                                       \
		y12vec = _mm_add_epi16(y12vec, yaddent);                                                                       \
		y34vec = _mm_add_epi16(y34vec, yaddent);                                                                       \
                                                                                                                       \
		auto y1 = cvtepi16_ps(y12vec, 0x1);                                                                            \
		auto y2 = cvtepi16_ps(y12vec, 0x0);                                                                            \
		auto y3 = cvtepi16_ps(y34vec, 0x1);                                                                            \
		auto y4 = cvtepi16_ps(y34vec, 0x0);                                                                            \
                                                                                                                       \
		y1 = _mm_mul_ps(y1, ycoeff);                                                                                   \
		y2 = _mm_mul_ps(y2, ycoeff);                                                                                   \
		y3 = _mm_mul_ps(y3, ycoeff);                                                                                   \
		y4 = _mm_mul_ps(y4, ycoeff);                                                                                   \
                                                                                                                       \
		auto u1234vec = cvtepi16_ps(uvvec, 0x1);                                                                       \
		auto v1234vec = cvtepi16_ps(uvvec, 0x0);                                                                       \
                                                                                                                       \
		SSE_CALCULATE_RGB_FOUR(1, 2, 3, 4);                                                                            \
	} while (0)

	size_t ws = ret.width_ / 8 * 8;
	size_t hs = ret.height_ / 8 * 8;

	for (size_t h = 0; h < ret.height_; h += 2) {
		for (size_t w = 0; w < ws; w += 8) { SSE_CALCULATE(1, 1); }
	}
	for (size_t w = ws; w < ret.width_; w += 2) {
		for (size_t h = 0; h < hs; h += 8) {
			auto halfwidth = ret.width_ / 2;
			SSE_CALCULATE(ret.width_, halfwidth);
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
