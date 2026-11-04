#include "../../android/app/src/main/cpp/utf8_stream.h"
#include <cassert>
#include <iostream>
int main() {
    const std::string bytes = u8"Main topic: learning — café 中文 తెలుగు 😀";
    const std::u16string expected = u"Main topic: learning — café 中文 తెలుగు 😀";
    for (size_t split = 0; split <= bytes.size(); ++split) {
        Utf8Stream decoder;
        auto text = decoder.append(std::string_view(bytes).substr(0, split));
        text += decoder.append(std::string_view(bytes).substr(split), true);
        assert(text == expected);
    }
    Utf8Stream one_byte;
    std::u16string text;
    for (const char c : bytes) text += one_byte.append(std::string_view(&c, 1));
    text += one_byte.append({}, true);
    assert(text == expected);
    Utf8Stream malformed;
    assert(malformed.append("\xFF", true) == u"\uFFFD");
    Utf8Stream incomplete;
    assert(incomplete.append("\xF0\x9F").empty());
    assert(incomplete.append({}, true) == u"\uFFFD");
    Utf8Stream nul;
    assert(nul.append(std::string("A\0B", 3), true) == std::u16string(u"A\0B", 3));
    std::cout << "UTF-8 split, supplementary, invalid and NUL cases passed\n";
}
