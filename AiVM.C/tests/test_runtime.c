#include "aivm_program.h"
#include "aivm_runtime.h"

static int expect(int condition)
{
    return condition ? 0 : 1;
}

int main(void)
{
    AivmVm vm;
    static const AivmInstruction instructions_ok[] = {
        { .opcode = AIVM_OP_NOP, .operand_int = 0 },
        { .opcode = AIVM_OP_HALT, .operand_int = 0 }
    };
    static const AivmProgram program_ok = {
        .instructions = instructions_ok,
        .instruction_count = 2U,
        .format_version = 0U,
        .format_flags = 0U,
        .section_count = 0U
    };
    static const AivmInstruction instructions_err[] = {
        { .opcode = (AivmOpcode)99, .operand_int = 0 }
    };
    static const AivmProgram program_err = {
        .instructions = instructions_err,
        .instruction_count = 1U,
        .format_version = 0U,
        .format_flags = 0U,
        .section_count = 0U
    };

    if (expect(aivm_execute_program(&program_ok, &vm) == 1) != 0) {
        return 1;
    }
    if (expect(vm.status == AIVM_VM_STATUS_HALTED) != 0) {
        return 1;
    }

    if (expect(aivm_execute_program(&program_err, &vm) == 0) != 0) {
        return 1;
    }
    if (expect(vm.status == AIVM_VM_STATUS_ERROR) != 0) {
        return 1;
    }

    if (expect(aivm_execute_program(NULL, &vm) == 0) != 0) {
        return 1;
    }

    return 0;
}
