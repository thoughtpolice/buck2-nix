#include <stddef.h>
#include "api.h"

char get_first_cap(const char *in, int size) {
  const char *first_cap = NULL;

  if (size == 0)
    return ' ';
  for (int i = 0 ; i++ < size && *in != 0; in++) {
    if (*in >= 'A' && *in <= 'Z') {
      first_cap = in;
      break;
    }
  }

  if (first_cap) return *first_cap;
  return ' ';
}
