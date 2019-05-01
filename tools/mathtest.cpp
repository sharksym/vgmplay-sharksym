#include <iostream>
#include <iomanip>
#include <array>
#include <random>

struct Z80
{
	struct {
		union
		{
			struct
			{
				uint8_t f, a, c, b, e, d, l, h;
			};
			struct
			{
				uint16_t af, bc, de, hl;
			};
		};
		struct
		{
			uint16_t af_, bc_, de_, hl_;
		};
		uint16_t sp;
	};

	std::array<uint8_t, 0x10000> memory;

	void print()
	{
		std::cout << "af: " << std::setfill('0') << std::setw(4) << std::hex << af << "  ";
		std::cout << "bc: " << std::setfill('0') << std::setw(4) << std::hex << bc << "  ";
		std::cout << "de: " << std::setfill('0') << std::setw(4) << std::hex << de << "  ";
		std::cout << "hl: " << std::setfill('0') << std::setw(4) << std::hex << hl << "  ";
		std::cout << (carry() ? " c" : "nc") << " " << (zero() ? " z" : "nz") << "\n";
	}

	bool carry()
	{
		return f & 1;
	}

	bool zero()
	{
		return (f >> 6) & 1;
	}

	bool sign()
	{
		return (f >> 7) & 1;
	}

	void store8f(uint8_t& r, int in)
	{
		r = in;
		f = (f & 0b00111110) | (in >> 8 != 0) | (r == 0) << 6 | (r & 0x80);
	}

	void store16f(uint16_t& rr, int in)
	{
		rr = in;
		f = (f & 0b00111110) | (in >> 16 != 0) | (rr == 0) << 6 | (rr >> 8 & 0x80);
	}

	void store16cy(uint16_t& rr, int in)
	{
		rr = in;
		f = (f & 0b11111110) | (in >> 16 != 0);
	}

	void adc8(uint8_t& r, int r_)
	{
		store8f(r, r + r_ + carry());
	}

	void add8(uint8_t& r, int r_)
	{
		store8f(r, r + r_);
	}

	void sbc8(uint8_t& r, int r_)
	{
		store8f(r, r - r_ - carry());
	}

	void sub8(uint8_t& r, int r_)
	{
		store8f(r, r - r_);
	}

	void cp8(uint8_t r, int r_)
	{
		sub8(r, r_);
	}

	void adc16(uint16_t& rr, int rr_)
	{
		store16f(rr, rr + rr_ + carry());
	}

	void add16(uint16_t& rr, int rr_)
	{
		store16cy(rr, rr + rr_);
	}

	void sbc16(uint16_t& rr, int rr_)
	{
		store16f(rr, rr - rr_ - carry());
	}

	void and8(uint8_t& r, int r_)
	{
		store8f(r, r & r_);
	}

	void or8(uint8_t& r, int r_)
	{
		store8f(r, r | r_);
	}

	void xor8(uint8_t& r, int r_)
	{
		store8f(r, r ^ r_);
	}

	void inc8(uint8_t& r)
	{
		++r;
		f = (f & 0b10111111) | (r == 0) << 6;
	}

	void inc16(uint16_t& rr)
	{
		++rr;
	}

	void dec8(uint8_t& r)
	{
		--r;
		f = (f & 0b10111111) | (r == 0) << 6;
	}

	void dec16(uint16_t& rr)
	{
		--rr;
	}

	void rl8(uint8_t& r)
	{
		store8f(r, int(r) << 1 | carry());
	}

	void rlc8(uint8_t& r)
	{
		store8f(r, int(r) << 1 | r >> 7);
	}

	void cpl()
	{
		a ^= 255;
	}

	void ex(uint16_t& rr, uint16_t& rr_)
	{
		uint16_t temp = rr;
		rr = rr_;
		rr_ = temp;
	}

	void exx()
	{
		ex(bc,bc_);
		ex(de,de_);
		ex(hl,hl_);
	}

	void ex_sp(uint16_t& rr)
	{
		uint16_t temp = rr;
		rr = memory[sp] | memory[sp + 1] << 8;
		memory[sp] = temp;
		memory[sp + 1] = temp >> 8;
	}

	void push(uint16_t rr)
	{
		dec16(sp);
		memory[sp] = rr >> 8;
		dec16(sp);
		memory[sp] = rr;
	}

	void pop(uint16_t& rr)
	{
		rr = memory[sp];
		inc16(sp);
		rr |= memory[sp] << 8;
		inc16(sp);
	}

	// c = divisor
	// hl = dividend
	// a <- remainder
	// c <- divisor
	// hl <- quotient
	void Divide16x8()
	{
		xor8(a,a);
		Divide16x8_Continue();
	}
	void Divide16x8_Continue()
	{
		b = 16;
	Loop:
		add16(hl,hl);
		rl8(a);
		if (carry()) goto Carry;
		cp8(a,c);
		if (carry()) goto ZeroDigit;
	Carry:
		inc8(l);
		sub8(a,c);
	ZeroDigit:
		if (--b) goto Loop;
		return;
	}

	// c = divisor
	// dehl = dividend
	// a <- remainder
	// c <- divisor
	// dehl <- quotient
	void Divide32x8()
	{
		push(hl);
		ex(de,hl);
		Divide16x8();
		ex_sp(hl);
		Divide16x8_Continue();
		pop(de);
		return;
	}

	void Divide8x16()
	{
		hl = 0;
		Divide8x16_Continue();
	}
	void Divide8x16_Continue()
	{
		b = 8;
	Loop:
		add8(a,a);
		adc16(hl,hl);
		if (carry()) goto Overflow;
		sbc16(hl,de);
		if (!carry()) goto OneDigit;
		add16(hl,de);
		if (--b) goto Loop;
		return;
	Overflow:
		and8(a,a);
		sbc16(hl,de);
	OneDigit:
		inc8(a);
		if (--b) goto Loop;
		return;
	}

	void Divide16x16()
	{
		push(bc);
		a = h;
		exx();
		pop(de);
		Divide8x16();
		exx();
		h = a;
		a = l;
		exx();
		Divide8x16_Continue();
		push(hl);
		exx();
		l = a;
		pop(bc);
		return;
	}

	void Divide32x16()
	{
		push(bc);
		a = d;
		exx();
		pop(de);
		Divide8x16();
		exx();
		d = a;
		a = e;
		exx();
		Divide8x16_Continue();
		exx();
		e = a;
		a = h;
		exx();
		Divide8x16_Continue();
		exx();
		h = a;
		a = l;
		exx();
		Divide8x16_Continue();
		push(hl);
		exx();
		l = a;
		pop(bc);
		return;
	}
};

uint32_t XorShiftRNG()
{
	static uint32_t y = 2463534242UL;
	y ^= y << 13;
	y ^= y >> 17;
	y ^= y << 15;
	return y;
}

int TestDivide16x8()
{
	std::cout << "Testing Divide16x8...\n";
	Z80 z = {};
	for (int j = 0; j < 65536; ++j)
	{
		if ((j & 4095) == 0) std::cout << j << "\r" << std::flush;
		for (int i = 1; i < 256; ++i)
		{
			z.hl = j;
			z.c = i;
			z.Divide16x8();
			if (z.c != i || (z.hl * z.c + z.a) != j)
			{
				std::cerr << "Fail: " << j << " / " << i << "\n";
				return 1;
			}
		}
	}
	return 0;
}

int TestDivide32x8()
{
	std::cout << "Testing Divide32x8...\n";
	Z80 z = {};
	for (int j = 0; j < 65536; ++j)
	{
		if ((j & 1023) == 0) std::cout << j << "\r" << std::flush;
		for (int i = 1; i < 256; ++i)
		{
			uint32_t div = XorShiftRNG();
			z.hl = div;
			z.de = div >> 16;
			z.c = i;
			z.Divide32x8();
			if (z.c != i || ((uint64_t(z.de) << 16 | z.hl) * z.c + z.a) != div)
			{
				std::cerr << "Fail: " << div << " / " << i << "\n";
				return 1;
			}
		}
	}
	return 0;
}

int TestDivide16x16()
{
	std::cout << "Testing Divide16x16...\n";
	Z80 z = {};
	for (int j = 0; j < 65536; ++j)
	{
		if ((j & 15) == 0) std::cout << j << "\r" << std::flush;
		for (int i = 1; i < 65536; ++i)
		{
			z.hl = j;
			z.bc = i;
			z.Divide16x16();
			if ((z.hl * i + z.bc) != j)
			{
				std::cerr << "Fail: " << j << " / " << i << "\n";
				return 1;
			}
		}
	}
	return 0;
}

int TestDivide32x16()
{
	std::cout << "Testing Divide32x16...\n";
	Z80 z = {};
	for (int j = 0; j < 65536; ++j)
	{
		if ((j & 3) == 0) std::cout << j << "\r" << std::flush;
		for (int i = 1; i < 65536; ++i)
		{
			uint32_t div = XorShiftRNG();
			z.hl = div;
			z.de = div >> 16;
			z.bc = i;
			z.Divide32x16();
			if (((uint64_t(z.de) << 16 | z.hl) * i + z.bc) != div)
			{
				std::cerr << "Fail: " << div << " / " << i << "\n";
				return 1;
			}
		}
	}
	return 0;
}

int main()
{
	return TestDivide16x8() || TestDivide32x8() || TestDivide16x16() || TestDivide32x16();
}
