#include <stdio.h>
#include "api.h"

int main() {
  if (get_first_cap("Hello", 5) != 'H')
    return 1;

  printf("main: OK!\n");
  return 0;
}
