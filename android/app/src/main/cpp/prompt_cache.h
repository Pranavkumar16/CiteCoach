#pragma once
#include <algorithm>
#include <cstddef>
#include <vector>

// Re-evaluate the final prompt token so its logits are always current.
template <typename Token>
std::size_t reusable_prompt_prefix(const std::vector<Token>& previous,
                                  const std::vector<Token>& current) {
    if (current.empty()) return 0;
    std::size_t shared = 0;
    const auto limit = std::min(previous.size(), current.size() - 1);
    while (shared < limit && previous[shared] == current[shared]) ++shared;
    return shared;
}
