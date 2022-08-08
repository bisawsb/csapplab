#include "ExecutePolicy.h"
#include "Rgb888.h"
#include "Yuv420pFrame.h"
#include "Yuv420pVideo.h"
#include "argparse.h"
#include <chrono>
#include <iostream>

using namespace argparse;

void runBenchmark(const std::string &inputFile, size_t width, size_t height, std::error_code &err) {
	using namespace std::chrono;
	Yuv420pFrame inputFrame = Yuv420pFrame::fromFile(inputFile, width, height, err);
	if (err) return;
	bool ok = false;
	auto t1 = steady_clock::now();
	auto basicResult = Yuv420pVideo::yuv420pFadeIn<BASIC>(inputFrame);
	auto t2 = steady_clock::now();
	auto mmxResult = Yuv420pVideo::yuv420pFadeIn<MMX>(inputFrame);
	auto t3 = steady_clock::now();
	auto sse2Result = Yuv420pVideo::yuv420pFadeIn<SSE>(inputFrame);
	auto t4 = steady_clock::now();
	auto avxResult = Yuv420pVideo::yuv420pFadeIn<AVX>(inputFrame);
	auto t5 = steady_clock::now();
	auto time_span1 = duration_cast<duration<double>>(t2 - t1);
	auto time_span2 = duration_cast<duration<double>>(t3 - t2);
	auto time_span3 = duration_cast<duration<double>>(t4 - t3);
	auto time_span4 = duration_cast<duration<double>>(t5 - t4);
	std::cout << "Basic ISA: " << time_span1.count() << "s.\n";
	std::cout << "MMX: " << time_span2.count() << "s.\n";
	std::cout << "SSE: " << time_span3.count() << "s.\n";
	std::cout << "AVX: " << time_span4.count() << "s.\n";
}

void runValidate(const std::string &inputFile, size_t width, size_t height, ExecutePolicy policy,
				 std::error_code &err) {
	Yuv420pFrame inputFrame = Yuv420pFrame::fromFile(inputFile, width, height, err);
	if (err) return;
	auto basicResult = Yuv420pVideo::yuv420pFadeIn<BASIC>(inputFrame);
	bool validateResult = false;
	switch (policy) {
		case BASIC:
			validateResult = basicResult == Yuv420pVideo::yuv420pFadeIn<BASIC>(inputFrame);
			break;
		case MMX:
			validateResult = basicResult == Yuv420pVideo::yuv420pFadeIn<MMX>(inputFrame);
			break;
		case SSE:
			validateResult = basicResult == Yuv420pVideo::yuv420pFadeIn<SSE>(inputFrame);
			break;
		case AVX:
			validateResult = basicResult == Yuv420pVideo::yuv420pFadeIn<AVX>(inputFrame);
			break;
	}
	if (validateResult) {
		std::cout << "Validate OK\n";
	} else {
		std::cout << "Validate FAILED\n";
		exit(-1);
	}
}

void runTransform(const std::string &inputFile, const std::string &outputFile, size_t width, size_t height,
				  ExecutePolicy policy, std::error_code &err) {
	Yuv420pFrame inputFrame = Yuv420pFrame::fromFile(inputFile, width, height, err);
	if (err) return;
	switch (policy) {
		case BASIC:
			Yuv420pVideo::yuv420pFadeIn<BASIC>(inputFrame).writeToFile(outputFile.c_str());
			break;
		case MMX:
			Yuv420pVideo::yuv420pFadeIn<MMX>(inputFrame).writeToFile(outputFile.c_str());
			break;
		case SSE:
			Yuv420pVideo::yuv420pFadeIn<SSE>(inputFrame).writeToFile(outputFile.c_str());
			break;
		case AVX:
			Yuv420pVideo::yuv420pFadeIn<AVX>(inputFrame).writeToFile(outputFile.c_str());
			break;
	}
}

enum MODE { REGULAR, BENCHMARK, VALIDATE };

int main(int argc, const char *argv[]) {
	ArgumentParser parser("yuv-alpha-mixing", "YUV420p image alpha mixing");
	parser.add_argument("-f", "--file", "input file", true);
	parser.add_argument("-s", "--size", "image size (e.g. 1920x1080)", true);
	parser.add_argument("-o", "--output", "output file", false);
	parser.add_argument("-m", "--mode", "execution mode (regular/benchmark/validate)", false);
	parser.add_argument("-i", "--isa", "isa (mmx/sse/avx/(other implies compiler generated assembly code))", false);
	parser.enable_help();

	std::string inputFile, outputFile;
	size_t width, height;
	MODE mode = REGULAR;
	ExecutePolicy policy = BASIC;

	auto err = parser.parse(argc, argv);
	if (err) {
		std::cout << err << std::endl;
		return -1;
	}

	if (parser.exists("help")) {
		parser.print_help();
		return 0;
	}

	if (parser.exists("f")) { inputFile = parser.get<std::string>("f"); }
	if (parser.exists("m")) {
		auto m = parser.get<std::string>("m");
		if (m == "benchmark") mode = BENCHMARK;
		else if (m == "validate")
			mode = VALIDATE;
	}
	if (mode == REGULAR) {
		if (parser.exists("o")) {
			outputFile = parser.get<std::string>("o");
		} else {
			std::cout << "Should specify the output file by -o option in regular mode\n";
			return -1;
		}
	}

	if (parser.exists("i")) {
		auto p = parser.get<std::string>("i");
		if (p == "mmx") {
			policy = MMX;
		} else if (p == "sse") {
			policy = SSE;
		} else if (p == "avx") {
			policy = AVX;
		}
	}
	if (parser.exists("s")) {
		auto raw = parser.get<std::string>("s");
		size_t pos;
		size_t pos2;
		bool failed = false;
		try {
			width = std::stoull(raw, &pos);
			if (pos == raw.size() || raw[pos] != 'x') {
				failed = true;
			} else {
				height = std::stoull(raw.substr(pos + 1), &pos2);
				if (pos + pos2 + 1 != raw.size()) failed = true;
			}
		} catch (const std::invalid_argument &err) { failed = true; }
		if (failed) {
			std::cout << "Failed to parse the size. Should be given in WWWxHHH form. For example 1920x1080\n";
			return -1;
		}
	}
	std::error_code errcode;

	switch (mode) {
		case REGULAR:
			runTransform(inputFile, outputFile, width, height, policy, errcode);
			if (errcode) { std::cout << "Failed to do transformation: " << errcode.message() << "\n"; }
			break;
		case BENCHMARK:
			for (int i = 0; i < 10; ++i) runBenchmark(inputFile, width, height, errcode);
			if (errcode) { std::cout << "Failed to run benchmark: " << errcode.message() << "\n"; }
			break;
		case VALIDATE:
			runValidate(inputFile, width, height, policy, errcode);
			if (errcode) { std::cout << "Failed to do transformation: " << errcode.message() << "\n"; }
			break;
	}
}
