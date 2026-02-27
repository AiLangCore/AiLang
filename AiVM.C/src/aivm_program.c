#include "aivm_program.h"

static uint32_t read_u32_le(const uint8_t* bytes, size_t offset)
{
    return (uint32_t)bytes[offset] |
           ((uint32_t)bytes[offset + 1U] << 8U) |
           ((uint32_t)bytes[offset + 2U] << 16U) |
           ((uint32_t)bytes[offset + 3U] << 24U);
}

static int64_t read_i64_le(const uint8_t* bytes, size_t offset)
{
    uint64_t low = (uint64_t)read_u32_le(bytes, offset);
    uint64_t high = (uint64_t)read_u32_le(bytes, offset + 4U);
    uint64_t combined = low | (high << 32U);
    return (int64_t)combined;
}

void aivm_program_clear(AivmProgram* program)
{
    size_t index;
    if (program == NULL) {
        return;
    }

    program->instructions = NULL;
    program->instruction_count = 0U;
    program->format_version = 0U;
    program->format_flags = 0U;
    program->section_count = 0U;
    for (index = 0U; index < AIVM_PROGRAM_MAX_INSTRUCTIONS; index += 1U) {
        program->instruction_storage[index].opcode = AIVM_OP_NOP;
        program->instruction_storage[index].operand_int = 0;
    }
    for (index = 0U; index < AIVM_PROGRAM_MAX_SECTIONS; index += 1U) {
        program->sections[index].section_type = 0U;
        program->sections[index].section_size = 0U;
        program->sections[index].section_offset = 0U;
    }
}

void aivm_program_init(AivmProgram* program, const AivmInstruction* instructions, size_t instruction_count)
{
    if (program == NULL) {
        return;
    }

    aivm_program_clear(program);
    program->instructions = instructions;
    program->instruction_count = instruction_count;
}

AivmProgramLoadResult aivm_program_load_aibc1(const uint8_t* bytes, size_t byte_count, AivmProgram* out_program)
{
    AivmProgramLoadResult result;
    size_t cursor;
    uint32_t section_index;
    int has_instruction_section = 0;

    if (out_program != NULL) {
        aivm_program_clear(out_program);
    }

    if (bytes == NULL || out_program == NULL) {
        result.status = AIVM_PROGRAM_ERR_NULL;
        result.error_offset = 0U;
        return result;
    }

    if (byte_count < 16U) {
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

    out_program->format_version = read_u32_le(bytes, 4U);
    out_program->format_flags = read_u32_le(bytes, 8U);
    out_program->section_count = read_u32_le(bytes, 12U);

    if (out_program->format_version != 1U) {
        result.status = AIVM_PROGRAM_ERR_UNSUPPORTED;
        result.error_offset = 4U;
        return result;
    }

    if (out_program->section_count > AIVM_PROGRAM_MAX_SECTIONS) {
        result.status = AIVM_PROGRAM_ERR_SECTION_LIMIT;
        result.error_offset = 12U;
        return result;
    }

    cursor = 16U;
    for (section_index = 0U; section_index < out_program->section_count; section_index += 1U) {
        uint32_t section_type;
        uint32_t section_size;
        size_t section_payload_start;

        if (cursor + 8U > byte_count) {
            result.status = AIVM_PROGRAM_ERR_TRUNCATED;
            result.error_offset = cursor;
            return result;
        }

        section_type = read_u32_le(bytes, cursor);
        section_size = read_u32_le(bytes, cursor + 4U);
        cursor += 8U;
        section_payload_start = cursor;

        if (cursor + (size_t)section_size > byte_count) {
            result.status = AIVM_PROGRAM_ERR_SECTION_OOB;
            result.error_offset = cursor;
            return result;
        }

        out_program->sections[section_index].section_type = section_type;
        out_program->sections[section_index].section_size = section_size;
        out_program->sections[section_index].section_offset = (uint32_t)cursor;

        if (section_type == AIVM_PROGRAM_SECTION_INSTRUCTIONS) {
            uint32_t instruction_count;
            uint32_t instruction_index;
            size_t instruction_cursor;

            if (has_instruction_section != 0) {
                result.status = AIVM_PROGRAM_ERR_INVALID_SECTION;
                result.error_offset = section_payload_start;
                return result;
            }
            has_instruction_section = 1;

            if (section_size < 4U) {
                result.status = AIVM_PROGRAM_ERR_INVALID_SECTION;
                result.error_offset = section_payload_start;
                return result;
            }

            instruction_count = read_u32_le(bytes, section_payload_start);
            if (instruction_count > AIVM_PROGRAM_MAX_INSTRUCTIONS) {
                result.status = AIVM_PROGRAM_ERR_INSTRUCTION_LIMIT;
                result.error_offset = section_payload_start;
                return result;
            }

            if ((size_t)section_size != (size_t)(4U + (instruction_count * 12U))) {
                result.status = AIVM_PROGRAM_ERR_INVALID_SECTION;
                result.error_offset = section_payload_start;
                return result;
            }

            instruction_cursor = section_payload_start + 4U;
            for (instruction_index = 0U; instruction_index < instruction_count; instruction_index += 1U) {
                uint32_t raw_opcode = read_u32_le(bytes, instruction_cursor);
                int64_t operand_int = read_i64_le(bytes, instruction_cursor + 4U);
                if (raw_opcode > (uint32_t)AIVM_OP_EQ) {
                    result.status = AIVM_PROGRAM_ERR_INVALID_OPCODE;
                    result.error_offset = instruction_cursor;
                    return result;
                }

                out_program->instruction_storage[instruction_index].opcode = (AivmOpcode)raw_opcode;
                out_program->instruction_storage[instruction_index].operand_int = operand_int;
                instruction_cursor += 12U;
            }

            out_program->instructions = out_program->instruction_storage;
            out_program->instruction_count = (size_t)instruction_count;
        }

        cursor += (size_t)section_size;
    }

    result.status = AIVM_PROGRAM_OK;
    result.error_offset = 0U;
    return result;
}
