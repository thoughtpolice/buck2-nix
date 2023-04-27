#include "api.h"

int LLVMFuzzerTestOneInput(const char *Data, long long Size) __attribute__((unused)) {
  get_first_cap(Data, Size);
  return 0;
}
