#ifndef AIVM_PROGRAM_H
#define AIVM_PROGRAM_H

#include <stddef.h>
#include <stdint.h>

typedef enum {
    AIVM_OP_NOP = 0,
    AIVM_OP_HALT = 1,
    AIVM_OP_STUB = 2
} AivmOpcode;

typedef struct {
    AivmOpcode opcode;
} AivmInstruction;

typedef struct {
    const AivmInstruction* instructions;
    size_t instruction_count;
} AivmProgram;

typedef enum {
    AIVM_PROGRAM_OK = 0,
    AIVM_PROGRAM_ERR_NULL = 1,
    AIVM_PROGRAM_ERR_TRUNCATED = 2,
    AIVM_PROGRAM_ERR_BAD_MAGIC = 3,
    AIVM_PROGRAM_ERR_UNSUPPORTED = 4
} AivmProgramStatus;

typedef struct {
    AivmProgramStatus status;
    size_t error_offset;
} AivmProgramLoadResult;

void aivm_program_clear(AivmProgram* program);
void aivm_program_init(AivmProgram* program, const AivmInstruction* instructions, size_t instruction_count);
AivmProgramLoadResult aivm_program_load_aibc1(const uint8_t* bytes, size_t byte_count, AivmProgram* out_program);

#endif
