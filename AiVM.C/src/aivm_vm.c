#include "aivm_vm.h"

void aivm_reset_state(AivmVm* vm)
{
    if (vm == NULL) {
        return;
    }

    vm->instruction_pointer = 0U;
    vm->status = AIVM_VM_STATUS_READY;
    vm->error = AIVM_VM_ERR_NONE;
    vm->stack_count = 0U;
    vm->call_frame_count = 0U;
    vm->locals_count = 0U;
}

void aivm_init(AivmVm* vm, const AivmProgram* program)
{
    if (vm == NULL) {
        return;
    }

    vm->program = program;
    aivm_reset_state(vm);
}

void aivm_halt(AivmVm* vm)
{
    if (vm == NULL || vm->program == NULL) {
        return;
    }

    vm->instruction_pointer = vm->program->instruction_count;
    vm->status = AIVM_VM_STATUS_HALTED;
}

int aivm_stack_push(AivmVm* vm, AivmValue value)
{
    if (vm == NULL) {
        return 0;
    }

    if (vm->stack_count >= AIVM_VM_STACK_CAPACITY) {
        vm->error = AIVM_VM_ERR_STACK_OVERFLOW;
        vm->status = AIVM_VM_STATUS_ERROR;
        return 0;
    }

    vm->stack[vm->stack_count] = value;
    vm->stack_count += 1U;
    return 1;
}

int aivm_stack_pop(AivmVm* vm, AivmValue* out_value)
{
    if (vm == NULL || out_value == NULL) {
        return 0;
    }

    if (vm->stack_count == 0U) {
        vm->error = AIVM_VM_ERR_STACK_UNDERFLOW;
        vm->status = AIVM_VM_STATUS_ERROR;
        return 0;
    }

    vm->stack_count -= 1U;
    *out_value = vm->stack[vm->stack_count];
    return 1;
}

int aivm_frame_push(AivmVm* vm, size_t return_instruction_pointer, size_t frame_base)
{
    if (vm == NULL) {
        return 0;
    }

    if (vm->call_frame_count >= AIVM_VM_CALLFRAME_CAPACITY) {
        vm->error = AIVM_VM_ERR_FRAME_OVERFLOW;
        vm->status = AIVM_VM_STATUS_ERROR;
        return 0;
    }

    vm->call_frames[vm->call_frame_count].return_instruction_pointer = return_instruction_pointer;
    vm->call_frames[vm->call_frame_count].frame_base = frame_base;
    vm->call_frame_count += 1U;
    return 1;
}

int aivm_frame_pop(AivmVm* vm, AivmCallFrame* out_frame)
{
    if (vm == NULL || out_frame == NULL) {
        return 0;
    }

    if (vm->call_frame_count == 0U) {
        vm->error = AIVM_VM_ERR_FRAME_UNDERFLOW;
        vm->status = AIVM_VM_STATUS_ERROR;
        return 0;
    }

    vm->call_frame_count -= 1U;
    *out_frame = vm->call_frames[vm->call_frame_count];
    return 1;
}

int aivm_local_set(AivmVm* vm, size_t index, AivmValue value)
{
    if (vm == NULL) {
        return 0;
    }

    if (index >= AIVM_VM_LOCALS_CAPACITY) {
        vm->error = AIVM_VM_ERR_LOCAL_OUT_OF_RANGE;
        vm->status = AIVM_VM_STATUS_ERROR;
        return 0;
    }

    vm->locals[index] = value;
    if (index >= vm->locals_count) {
        vm->locals_count = index + 1U;
    }
    return 1;
}

int aivm_local_get(const AivmVm* vm, size_t index, AivmValue* out_value)
{
    if (vm == NULL || out_value == NULL) {
        return 0;
    }

    if (index >= vm->locals_count) {
        return 0;
    }

    *out_value = vm->locals[index];
    return 1;
}

void aivm_step(AivmVm* vm)
{
    const AivmInstruction* instruction;

    if (vm == NULL || vm->program == NULL || vm->program->instructions == NULL) {
        return;
    }

    if (vm->status == AIVM_VM_STATUS_HALTED || vm->status == AIVM_VM_STATUS_ERROR) {
        return;
    }

    if (vm->instruction_pointer >= vm->program->instruction_count) {
        vm->status = AIVM_VM_STATUS_HALTED;
        return;
    }

    vm->status = AIVM_VM_STATUS_RUNNING;
    instruction = &vm->program->instructions[vm->instruction_pointer];

    switch (instruction->opcode) {
        case AIVM_OP_NOP:
            vm->instruction_pointer += 1U;
            break;

        case AIVM_OP_HALT:
            aivm_halt(vm);
            break;

        case AIVM_OP_STUB:
            vm->instruction_pointer += 1U;
            break;

        default:
            vm->error = AIVM_VM_ERR_INVALID_OPCODE;
            vm->status = AIVM_VM_STATUS_ERROR;
            vm->instruction_pointer = vm->program->instruction_count;
            break;
    }

    if (vm->status == AIVM_VM_STATUS_RUNNING &&
        vm->instruction_pointer >= vm->program->instruction_count) {
        vm->status = AIVM_VM_STATUS_HALTED;
    }
}

void aivm_run(AivmVm* vm)
{
    if (vm == NULL || vm->program == NULL) {
        return;
    }

    while (vm->instruction_pointer < vm->program->instruction_count &&
           vm->status != AIVM_VM_STATUS_ERROR &&
           vm->status != AIVM_VM_STATUS_HALTED) {
        aivm_step(vm);
    }
}

const char* aivm_vm_error_code(AivmVmError error)
{
    switch (error) {
        case AIVM_VM_ERR_NONE:
            return "AIVM000";
        case AIVM_VM_ERR_INVALID_OPCODE:
            return "AIVM001";
        case AIVM_VM_ERR_STACK_OVERFLOW:
            return "AIVM002";
        case AIVM_VM_ERR_STACK_UNDERFLOW:
            return "AIVM003";
        case AIVM_VM_ERR_FRAME_OVERFLOW:
            return "AIVM004";
        case AIVM_VM_ERR_FRAME_UNDERFLOW:
            return "AIVM005";
        case AIVM_VM_ERR_LOCAL_OUT_OF_RANGE:
            return "AIVM006";
        default:
            return "AIVM999";
    }
}

const char* aivm_vm_error_message(AivmVmError error)
{
    switch (error) {
        case AIVM_VM_ERR_NONE:
            return "No error.";
        case AIVM_VM_ERR_INVALID_OPCODE:
            return "Invalid opcode.";
        case AIVM_VM_ERR_STACK_OVERFLOW:
            return "Stack overflow.";
        case AIVM_VM_ERR_STACK_UNDERFLOW:
            return "Stack underflow.";
        case AIVM_VM_ERR_FRAME_OVERFLOW:
            return "Call frame overflow.";
        case AIVM_VM_ERR_FRAME_UNDERFLOW:
            return "Call frame underflow.";
        case AIVM_VM_ERR_LOCAL_OUT_OF_RANGE:
            return "Local index out of range.";
        default:
            return "Unknown VM error.";
    }
}
