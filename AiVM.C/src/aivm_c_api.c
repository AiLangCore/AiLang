#include "aivm_c_api.h"

#include "aivm_runtime.h"

AivmCResult aivm_c_execute_instructions(const AivmInstruction* instructions, size_t instruction_count)
{
    AivmProgram program;
    AivmVm vm;
    AivmCResult result;

    aivm_program_init(&program, instructions, instruction_count);

    result.ok = aivm_execute_program(&program, &vm);
    result.status = vm.status;
    result.error = vm.error;
    return result;
}
