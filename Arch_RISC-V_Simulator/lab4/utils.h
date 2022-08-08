#ifndef LAB4_NEW_UTILS_H
#define LAB4_NEW_UTILS_H

inline unsigned char roundInt(int x) {
	if (x < 0) return 0;
	if (x > 255) return 255;
	return static_cast<unsigned char>(x);
}

#define IS_ALIGNED(addr,size)   ((((size_t)(addr)) % (size)) == 0)

#endif//LAB4_NEW_UTILS_H
