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
    static const uint8_t bad_magic[4] = { 'X', 'I', 'B', 'C' };
    static const uint8_t truncated[3] = { 'A', 'I', 'B' };
    static const uint8_t valid_header[4] = { 'A', 'I', 'B', 'C' };

    result = aivm_program_load_aibc1(NULL, 0U, &program);
    if (expect(result.status == AIVM_PROGRAM_ERR_NULL) != 0) {
        return 1;
    }

    result = aivm_program_load_aibc1(valid_header, 4U, NULL);
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

    result = aivm_program_load_aibc1(bad_magic, 4U, &program);
    if (expect(result.status == AIVM_PROGRAM_ERR_BAD_MAGIC) != 0) {
        return 1;
    }

    result = aivm_program_load_aibc1(valid_header, 4U, &program);
    if (expect(result.status == AIVM_PROGRAM_ERR_UNSUPPORTED) != 0) {
        return 1;
    }
    if (expect(result.error_offset == 4U) != 0) {
        return 1;
    }

    return 0;
}
