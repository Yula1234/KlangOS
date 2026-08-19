bits 32

section .multiboot
    align 4
    dd 0x1BADB002
    dd 0x00000003
    dd -(0x1BADB002 + 0x00000003)

section .text
    global _start
    extern kmain

_start:
    cli

    mov [multiboot_magic], eax
    mov [multiboot_info_ptr], ebx

    mov edi, pml4_table
    mov ecx, 8192
    xor eax, eax
    cld
    rep stosd

    mov dword [boot_ident_pd + 0], 0x000000 | 0x83
    mov dword [boot_ident_pd + 8], 0x200000 | 0x83

    mov dword [boot_ident_pdpt + 0], boot_ident_pd + 0b11
    mov dword [pml4_table + 0 * 8],   boot_ident_pdpt + 0b11

    mov edi, boot_hhdm_pds
    mov eax, 0x83
    mov ecx, 2048

.fill_hhdm_pd:
    mov [edi], eax
    mov dword [edi + 4], 0
    add eax, 0x200000
    add edi, 8
    loop .fill_hhdm_pd

    mov dword [boot_hhdm_pdpt + 0],  boot_hhdm_pds + 0x0000 + 0b11
    mov dword [boot_hhdm_pdpt + 8],  boot_hhdm_pds + 0x1000 + 0b11
    mov dword [boot_hhdm_pdpt + 16], boot_hhdm_pds + 0x2000 + 0b11
    mov dword [boot_hhdm_pdpt + 24], boot_hhdm_pds + 0x3000 + 0b11

    mov dword [pml4_table + 256 * 8], boot_hhdm_pdpt + 0b11

    mov eax, pml4_table
    mov cr3, eax

    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    lgdt [gdt64_ptr]
    jmp 0x08:.long_mode_entry

bits 64
default rel

.long_mode_entry:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov rsp, stack_top

    mov edi, [multiboot_magic]
    mov esi, [multiboot_info_ptr]

    call kmain

.hang:
    cli
    hlt
    jmp .hang

section .rodata

gdt64:
    dq 0                  
    dq 0x00209A0000000000 
    dq 0x0000920000000000 

gdt64_ptr:
    dw $ - gdt64 - 1
    dq gdt64

section .bss nobits

alignb 8
multiboot_magic:
    resd 1
multiboot_info_ptr:
    resd 1

alignb 4096
pml4_table:
    resb 4096
boot_ident_pdpt:
    resb 4096
boot_ident_pd:
    resb 4096
boot_hhdm_pdpt:
    resb 4096
boot_hhdm_pds:
    resb 16384

alignb 16
global stack_top
stack_bottom:
    resb 16384
stack_top: