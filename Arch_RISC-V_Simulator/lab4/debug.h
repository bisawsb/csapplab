#ifndef LAB4_NEW_DEBUG_H
#define LAB4_NEW_DEBUG_H

#include <immintrin.h>
#include <string.h>
#include <stdio.h>

inline
void print_epi8(__m128i var)
{
	int8_t val[16];
	memcpy(val, &var, sizeof(val));
	printf("epi8:");
	for (int i = 15; i >= 0; --i) {
		if (i % 4 == 3 && i != 15)
			printf(" |");
		printf(" %i[%x]", val[i], val[i]);
	}
	printf("\n");
}

inline
void print_epi16(__m128i var)
{
	int16_t val[8];
	memcpy(val, &var, sizeof(val));
	printf("epi16:");
	for (int i = 7; i >= 0; --i) {
		if (i % 4 == 3 && i != 7)
			printf(" |");
		printf(" %i[%x]", val[i], val[i]);
	}
	printf("\n");
}

inline
void print_epi32(__m128i var)
{
	int32_t val[4];
	memcpy(val, &var, sizeof(val));
	printf("epi32:");
	for (int i = 3; i >= 0; --i) {
		printf(" %i[%x]", val[i], val[i]);
	}
	printf("\n");
}


inline
void print_epu8(__m128i var)
{
	uint8_t val[16];
	memcpy(val, &var, sizeof(val));
	printf("epi8:");
	for (int i = 15; i >= 0; --i) {
		if (i % 4 == 3 && i != 15)
			printf(" |");
		printf(" %u[%x]", val[i], val[i]);
	}
	printf("\n");
}

inline
void print_epu16(__m128i var)
{
	uint16_t val[8];
	memcpy(val, &var, sizeof(val));
	printf("epi16:");
	for (int i = 7; i >= 0; --i) {
		if (i % 4 == 3 && i != 7)
			printf(" |");
		printf(" %u[%x]", val[i], val[i]);
	}
	printf("\n");
}

inline
void print_epu32(__m128i var)
{
	uint32_t val[4];
	memcpy(val, &var, sizeof(val));
	printf("epi32:");
	for (int i = 3; i >= 0; --i) {
		printf(" %u[%x]", val[i], val[i]);
	}
	printf("\n");
}

inline
void print_ps(__m128 var)
{
	float val[4];
	memcpy(val, &var, sizeof(val));
	printf("ps:");
	for (int i = 3; i >= 0; --i) {
		printf(" %f[%x]", val[i], ((int*)val)[i]);
	}
	printf("\n");
}

inline
void print256_epi8(__m256i var)
{
	int8_t val[32];
	memcpy(val, &var, sizeof(val));
	printf("256epi8:");
	for (int i = 31; i >= 0; --i) {
		if (i % 4 == 3 && i != 31)
			printf(" |");
		printf(" %i[%x]", val[i], val[i]);
	}
	printf("\n");
}

inline
void print256_epi16(__m256i var)
{
	int16_t val[16];
	memcpy(val, &var, sizeof(val));
	printf("256epi16:");
	for (int i = 15; i >= 0; --i) {
		if (i % 4 == 3 && i != 15)
			printf(" |");
		printf(" %i[%x]", val[i], val[i]);
	}
	printf("\n");
}

inline
void print256_epi32(__m256i var)
{
	int32_t val[8];
	memcpy(val, &var, sizeof(val));
	printf("256epi32:");
	for (int i = 7; i >= 0; --i) {
		if (i % 4 == 3 && i != 7)
			printf(" |");
		printf(" %i[%x]", val[i], val[i]);
	}
	printf("\n");
}

inline
void print256_epu16(__m256i var)
{
	uint16_t val[16];
	memcpy(val, &var, sizeof(val));
	printf("256epi16:");
	for (int i = 15; i >= 0; --i) {
		if (i % 4 == 3 && i != 15)
			printf(" |");
		printf(" %u[%x]", val[i], val[i]);
	}
	printf("\n");
}

inline
void print256_epu32(__m256i var)
{
	uint32_t val[8];
	memcpy(val, &var, sizeof(val));
	printf("256epi32:");
	for (int i = 7; i >= 0; --i) {
		if (i % 4 == 3 && i != 7)
			printf(" |");
		printf(" %u[%x]", val[i], val[i]);
	}
	printf("\n");
}

inline
void print256_ps(__m256 var)
{
	float val[8];
	memcpy(val, &var, sizeof(val));
	printf("256ps:");
	for (int i = 7; i >= 0; --i) {
		if (i % 4 == 3 && i != 7)
			printf(" |");
		printf(" %f[%x]", val[i], ((int*)val)[i]);
	}
	printf("\n");
}

#endif//LAB4_NEW_DEBUG_H
