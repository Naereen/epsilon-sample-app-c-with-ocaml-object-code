#include <eadk.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// // Libraries necessary to include OCaml code
// #include "caml/alloc.h"
// #include "caml/mlvalues.h"
// #include "caml/memory.h"
// #include "caml/callback.h"

// Trying to find a way to include the object file produced using microb
// #include "fact.h"


const char eadk_app_name[] __attribute__((section(".rodata.eadk_app_name"))) = "OCaml + C app";
const uint32_t eadk_api_level  __attribute__((section(".rodata.eadk_api_level"))) = 0;

int main(int argc, char * argv[]) {
  eadk_timing_msleep(3000);
  eadk_display_draw_string("Hello, world!", (eadk_point_t){0, 0}, true, eadk_color_black, eadk_color_white);
  printf("Should run the OCaml interpreter on external data:\n'%s'\n", eadk_external_data);

  // Reference https://ocaml.org/docs/compiler-backend#embedding-ocaml-bytecode-in-c
  printf("Before calling OCaml\n");
  // fflush(stdout);
  // caml_startup(argv);

  // printf("fact(10) = %i\n", fact(20));
  printf("TODO");

  printf("After calling OCaml\n");
  return 0;
}
