#include "aivm_program.h"

void aivm_program_clear(AivmProgram* program)
{
    if (program == NULL) {
        return;
    }

    program->instructions = NULL;
    program->instruction_count = 0U;
}

void aivm_program_init(AivmProgram* program, const AivmInstruction* instructions, size_t instruction_count)
{
    if (program == NULL) {
        return;
    }

    program->instructions = instructions;
    program->instruction_count = instruction_count;
}

AivmProgramLoadResult aivm_program_load_aibc1(const uint8_t* bytes, size_t byte_count, AivmProgram* out_program)
{
    AivmProgramLoadResult result;

    if (out_program != NULL) {
        aivm_program_clear(out_program);
    }

    if (bytes == NULL || out_program == NULL) {
        result.status = AIVM_PROGRAM_ERR_NULL;
        result.error_offset = 0U;
        return result;
    }

    /*
     * Minimum deterministic guard for AiBC1 container prefix.
     * Full bytecode decoding is intentionally deferred to later phases.
     */
    if (byte_count < 4U) {
        result.status = AIVM_PROGRAM_ERR_TRUNCATED;
        result.error_offset = byte_count;
        return result;
    }

    if (bytes[0] != (uint8_t)'A' ||
        bytes[1] != (uint8_t)'I' ||
        bytes[2] != (uint8_t)'B' ||
        bytes[3] != (uint8_t)'C') {
        result.status = AIVM_PROGRAM_ERR_BAD_MAGIC;
        result.error_offset = 0U;
        return result;
    }

    result.status = AIVM_PROGRAM_ERR_UNSUPPORTED;
    result.error_offset = 4U;
    return result;
}
