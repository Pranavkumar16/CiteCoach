#include <cassert>
#include <vector>
#include "../../android/app/src/main/cpp/prompt_cache.h"
int main() {
    using V = std::vector<int>;
    assert(reusable_prompt_prefix(V{1,2,3}, V{1,2,3}) == 2);
    assert(reusable_prompt_prefix(V{1,2,3}, V{1,2,4,5}) == 2);
    assert(reusable_prompt_prefix(V{1,2,3}, V{9,2,3}) == 0);
    assert(reusable_prompt_prefix(V{1,2,3}, V{1}) == 0);
    assert(reusable_prompt_prefix(V{}, V{1,2}) == 0);
    assert(reusable_prompt_prefix(V{1,2}, V{}) == 0);
}
