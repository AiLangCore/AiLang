#ifndef AIVM_VM_H
#define AIVM_VM_H

#include <stddef.h>

#include "aivm_program.h"
#include "aivm_types.h"

typedef enum {
    AIVM_VM_STATUS_READY = 0,
    AIVM_VM_STATUS_RUNNING = 1,
    AIVM_VM_STATUS_HALTED = 2,
    AIVM_VM_STATUS_ERROR = 3
} AivmVmStatus;

typedef enum {
    AIVM_VM_ERR_NONE = 0,
    AIVM_VM_ERR_INVALID_OPCODE = 1,
    AIVM_VM_ERR_STACK_OVERFLOW = 2,
    AIVM_VM_ERR_STACK_UNDERFLOW = 3,
    AIVM_VM_ERR_FRAME_OVERFLOW = 4,
    AIVM_VM_ERR_FRAME_UNDERFLOW = 5,
    AIVM_VM_ERR_LOCAL_OUT_OF_RANGE = 6,
    AIVM_VM_ERR_TYPE_MISMATCH = 7,
    AIVM_VM_ERR_INVALID_PROGRAM = 8,
    AIVM_VM_ERR_STRING_OVERFLOW = 9
} AivmVmError;

typedef struct {
    size_t return_instruction_pointer;
    size_t frame_base;
} AivmCallFrame;

enum {
    AIVM_VM_STACK_CAPACITY = 1024,
    AIVM_VM_CALLFRAME_CAPACITY = 256,
    AIVM_VM_LOCALS_CAPACITY = 1024,
    AIVM_VM_STRING_ARENA_CAPACITY = 8192
};

typedef struct {
    const AivmProgram* program;
    size_t instruction_pointer;
    AivmVmStatus status;
    AivmVmError error;

    AivmValue stack[AIVM_VM_STACK_CAPACITY];
    size_t stack_count;

    AivmCallFrame call_frames[AIVM_VM_CALLFRAME_CAPACITY];
    size_t call_frame_count;

    AivmValue locals[AIVM_VM_LOCALS_CAPACITY];
    size_t locals_count;
    char string_arena[AIVM_VM_STRING_ARENA_CAPACITY];
    size_t string_arena_used;
} AivmVm;

void aivm_init(AivmVm* vm, const AivmProgram* program);
void aivm_reset_state(AivmVm* vm);
void aivm_halt(AivmVm* vm);
int aivm_stack_push(AivmVm* vm, AivmValue value);
int aivm_stack_pop(AivmVm* vm, AivmValue* out_value);
int aivm_frame_push(AivmVm* vm, size_t return_instruction_pointer, size_t frame_base);
int aivm_frame_pop(AivmVm* vm, AivmCallFrame* out_frame);
int aivm_local_set(AivmVm* vm, size_t index, AivmValue value);
int aivm_local_get(const AivmVm* vm, size_t index, AivmValue* out_value);
void aivm_step(AivmVm* vm);
void aivm_run(AivmVm* vm);
const char* aivm_vm_error_code(AivmVmError error);
const char* aivm_vm_error_message(AivmVmError error);

#endif
