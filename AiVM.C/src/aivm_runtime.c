#include "aivm_runtime.h"

int aivm_execute_program(const AivmProgram* program, AivmVm* vm_out)
{
    if (program == NULL || vm_out == NULL) {
        return 0;
    }

    aivm_init(vm_out, program);
    aivm_run(vm_out);

    if (vm_out->status == AIVM_VM_STATUS_ERROR) {
        return 0;
    }

    return 1;
}
