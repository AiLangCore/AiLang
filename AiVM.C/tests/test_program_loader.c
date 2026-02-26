#include <stdint.h>

#include "aivm_program.h"

static int expect(int condition)
{
    return condition ? 0 : 1;
}

int main(void)
{
    AivmProgram program;
    AivmProgramLoadResult result;
    static const uint8_t bad_magic[12] = { 'X', 'I', 'B', 'C', 1, 0, 0, 0, 0, 0, 0, 0 };
    static const uint8_t truncated[3] = { 'A', 'I', 'B' };
    static const uint8_t unsupported_version[12] = { 'A', 'I', 'B', 'C', 2, 0, 0, 0, 7, 0, 0, 0 };
    static const uint8_t valid_header[12] = { 'A', 'I', 'B', 'C', 1, 0, 0, 0, 9, 0, 0, 0 };

    result = aivm_program_load_aibc1(NULL, 0U, &program);
    if (expect(result.status == AIVM_PROGRAM_ERR_NULL) != 0) {
        return 1;
    }

    result = aivm_program_load_aibc1(valid_header, 12U, NULL);
    if (expect(result.status == AIVM_PROGRAM_ERR_NULL) != 0) {
        return 1;
    }

    result = aivm_program_load_aibc1(truncated, 3U, &program);
    if (expect(result.status == AIVM_PROGRAM_ERR_TRUNCATED) != 0) {
        return 1;
    }
    if (expect(result.error_offset == 3U) != 0) {
        return 1;
    }

    result = aivm_program_load_aibc1(bad_magic, 12U, &program);
    if (expect(result.status == AIVM_PROGRAM_ERR_BAD_MAGIC) != 0) {
        return 1;
    }

    result = aivm_program_load_aibc1(unsupported_version, 12U, &program);
    if (expect(result.status == AIVM_PROGRAM_ERR_UNSUPPORTED) != 0) {
        return 1;
    }
    if (expect(result.error_offset == 4U) != 0) {
        return 1;
    }
    if (expect(program.format_version == 2U) != 0) {
        return 1;
    }
    if (expect(program.format_flags == 7U) != 0) {
        return 1;
    }

    result = aivm_program_load_aibc1(valid_header, 12U, &program);
    if (expect(result.status == AIVM_PROGRAM_ERR_UNSUPPORTED) != 0) {
        return 1;
    }
    if (expect(result.error_offset == 12U) != 0) {
        return 1;
    }
    if (expect(program.format_version == 1U) != 0) {
        return 1;
    }
    if (expect(program.format_flags == 9U) != 0) {
        return 1;
    }

    return 0;
}
