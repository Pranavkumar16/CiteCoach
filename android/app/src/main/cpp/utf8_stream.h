#pragma once
#include <cstdint>
#include <string>
#include <string_view>

// llama token pieces may end halfway through a Unicode character. JNI
// NewStringUTF accepts modified UTF-8, so never pass these raw pieces to it.
class Utf8Stream {
    std::string pending;
public:
    std::u16string append(std::string_view bytes, bool final = false) {
        if (!bytes.empty()) pending.append(bytes.data(), bytes.size());
        std::u16string out;
        size_t i = 0;
        while (i < pending.size()) {
            const auto c = static_cast<unsigned char>(pending[i]);
            int count = c < 0x80 ? 1 : (c >= 0xC2 && c <= 0xDF ? 2 :
                (c >= 0xE0 && c <= 0xEF ? 3 : (c >= 0xF0 && c <= 0xF4 ? 4 : 0)));
            if (count == 0) { out.push_back(0xFFFD); ++i; continue; }
            if (i + count > pending.size()) {
                if (!final) break;
                out.push_back(0xFFFD); i = pending.size(); break;
            }
            uint32_t cp = c & (count == 1 ? 0x7F : (0x7F >> count));
            bool valid = true;
            for (int j = 1; j < count; ++j) {
                const auto next = static_cast<unsigned char>(pending[i+j]);
                if ((next & 0xC0) != 0x80) { valid = false; break; }
                cp = (cp << 6) | (next & 0x3F);
            }
            const uint32_t minimum[] = {0, 0, 0x80, 0x800, 0x10000};
            valid = valid && cp >= minimum[count] && cp <= 0x10FFFF && !(cp >= 0xD800 && cp <= 0xDFFF);
            if (!valid) { out.push_back(0xFFFD); ++i; continue; }
            if (cp <= 0xFFFF) out.push_back(static_cast<char16_t>(cp));
            else { cp -= 0x10000; out.push_back(0xD800 + (cp >> 10)); out.push_back(0xDC00 + (cp & 0x3FF)); }
            i += count;
        }
        pending.erase(0, i);
        return out;
    }
};
