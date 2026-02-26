#ifndef AIVM_C_API_H
#define AIVM_C_API_H

#include <stddef.h>

#include "aivm_program.h"
#include "aivm_vm.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    int ok;
    AivmVmStatus status;
    AivmVmError error;
} AivmCResult;

AivmCResult aivm_c_execute_instructions(const AivmInstruction* instructions, size_t instruction_count);

#ifdef __cplusplus
}
#endif

#endif
