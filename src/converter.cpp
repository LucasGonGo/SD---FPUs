#include <iostream>
#include <cmath>
#include <cstdint>
#include <bitset>

uint32_t floatToCustom(float value) {
    // Tratar zero como caso especial
    if (value == 0.0f)
        return 0;

    uint32_t result = 0;

    // Pegar sinal
    uint32_t sign = std::signbit(value) ? 1 : 0;

    // Valor absoluto
    float absVal = std::fabs(value);

    // Extrair expoente e mantissa normalizada
    int exp;
    float norm = std::frexp(absVal, &exp); // norm ∈ [0.5, 1.0)

    // Converter expoente para bias-511 (10 bits)
    int biasedExp = exp + 510; // Bias 511
    if (biasedExp < 0 || biasedExp > 1023) {
        std::cerr << "Erro: expoente fora do intervalo de 10 bits!" << std::endl;
        return 0;
    }

    // Calcular mantissa de 21 bits (sem o bit implícito)
    float mantissa = (norm * 2.0f) - 1.0f; // agora ∈ [0.0, 1.0)
    uint32_t mantBits = static_cast<uint32_t>(mantissa * (1 << 21));

    // Montar o número final
    result = (sign << 31) | (biasedExp << 21) | (mantBits & 0x1FFFFF);
    return result;
}

void printCustom(float value) {
    uint32_t encoded = floatToCustom(value);
    std::bitset<32> bits(encoded);

    uint32_t sign = (encoded >> 31) & 0x1;
    uint32_t exp  = (encoded >> 21) & 0x3FF;      // 10 bits
    uint32_t mant = (encoded & 0x1FFFFF);         // 21 bits

    std::cout << "Valor:          " << value << std::endl;
    std::cout << "Binário total:  " << bits << std::endl;
    std::cout << "Sinal:          " << sign << std::endl;
    std::cout << "Expoente (bias):" << exp << std::endl;
    std::cout << "Mantissa (hex): 0x" << std::hex << mant << std::dec << std::endl;
    std::cout << "Mantissa (bin): " << std::bitset<21>(mant) << std::endl;
}

int main() {
    float aux;
    std::cout << "Digite um valor em float: ";
    std::cin >> aux;
    printCustom(aux);
}
